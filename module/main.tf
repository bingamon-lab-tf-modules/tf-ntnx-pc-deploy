##################################################
# Prism Central deployment
##################################################

# Deploy a Prism Central VM onto the Prism Element cluster. The provider for
# this module MUST target the Prism Element (PE) cluster VIP, because Prism
# Central does not yet exist when this runs.
resource "nutanix_pc_deploy_v2" "this" {

  should_enable_high_availability = var.prism_central.should_enable_high_availability

  config {
    name                        = var.prism_central.name
    size                        = var.prism_central.size
    should_enable_lockdown_mode = var.prism_central.should_enable_lockdown_mode

    build_info {
      version = var.prism_central.version
    }

    # Admin credentials for the new Prism Central (optional).
    dynamic "credentials" {
      for_each = var.prism_central.credentials != null ? [var.prism_central.credentials] : []
      content {
        username = credentials.value.username
        password = credentials.value.password
      }
    }

    # Resource sizing overrides (optional).
    dynamic "resource_config" {
      for_each = var.prism_central.resource_config != null ? [var.prism_central.resource_config] : []
      content {
        num_vcpus            = resource_config.value.num_vcpus
        memory_size_bytes    = resource_config.value.memory_size_bytes
        data_disk_size_bytes = resource_config.value.data_disk_size_bytes
        container_ext_ids    = resource_config.value.container_ext_ids
      }
    }
  }

  network {

    # Static external (VIP) address for Prism Central (optional).
    dynamic "external_address" {
      for_each = var.network.external_address != null ? [var.network.external_address] : []
      content {
        ipv4 {
          value = external_address.value
        }
      }
    }

    # The external management network Prism Central attaches to.
    external_networks {
      network_ext_id = local.external_network_ext_id

      default_gateway {
        ipv4 {
          value = var.network.external_network.default_gateway
        }
      }

      subnet_mask {
        ipv4 {
          value = var.network.external_network.subnet_mask
        }
      }

      ip_ranges {
        begin {
          ipv4 {
            value = var.network.external_network.ip_range.begin
          }
        }
        end {
          ipv4 {
            value = var.network.external_network.ip_range.end
          }
        }
      }
    }

    # DNS servers. Each value is emitted as an IPv4 or FQDN block automatically.
    dynamic "name_servers" {
      for_each = var.network.name_servers
      content {
        dynamic "ipv4" {
          for_each = can(cidrnetmask("${name_servers.value}/32")) ? [name_servers.value] : []
          content {
            value = ipv4.value
          }
        }
        dynamic "fqdn" {
          for_each = can(cidrnetmask("${name_servers.value}/32")) ? [] : [name_servers.value]
          content {
            value = fqdn.value
          }
        }
      }
    }

    # NTP servers. Each value is emitted as an IPv4 or FQDN block automatically.
    dynamic "ntp_servers" {
      for_each = var.network.ntp_servers
      content {
        dynamic "ipv4" {
          for_each = can(cidrnetmask("${ntp_servers.value}/32")) ? [ntp_servers.value] : []
          content {
            value = ipv4.value
          }
        }
        dynamic "fqdn" {
          for_each = can(cidrnetmask("${ntp_servers.value}/32")) ? [] : [ntp_servers.value]
          content {
            value = fqdn.value
          }
        }
      }
    }
  }

  timeouts {
    create = var.deploy_timeout
  }
}

##################################################
# Prism Element -> Prism Central registration
##################################################

# Register each configured Prism Element cluster to the newly deployed PC.
resource "nutanix_pc_registration_v2" "this" {
  for_each = var.prism_element

  pc_ext_id = nutanix_pc_deploy_v2.this.id

  remote_cluster {

    # Register a known PE cluster by ext_id.
    dynamic "cluster_reference" {
      for_each = each.value.cluster_ext_id != null ? [each.value.cluster_ext_id] : []
      content {
        ext_id = cluster_reference.value
      }
    }

    # Register a remote AOS cluster by VIP address + credentials.
    dynamic "aos_remote_cluster_spec" {
      for_each = each.value.remote_address != null ? [each.value] : []
      content {
        remote_cluster {
          address {
            ipv4 {
              value = aos_remote_cluster_spec.value.remote_address
            }
          }
          credentials {
            authentication {
              username = aos_remote_cluster_spec.value.username
              password = aos_remote_cluster_spec.value.password
            }
          }
        }
      }
    }
  }
}

##################################################
# Prism Element unregistration (optional, destroy-time cleanup)
##################################################

# Optionally manage unregistration so PE clusters are detached from PC on destroy.
resource "nutanix_pc_unregistration_v2" "this" {
  for_each = var.enable_unregistration ? var.prism_element : {}

  pc_ext_id = nutanix_pc_deploy_v2.this.id
  ext_id    = nutanix_pc_registration_v2.this[each.key].ext_id
}
