locals {

  ##################################################
  # Network
  ##################################################

  # The external network ext_id, either supplied directly or resolved by name.
  external_network_ext_id = (
    var.network.external_network.network_ext_id != null
    ? var.network.external_network.network_ext_id
    : try(data.nutanix_subnets_v2.external_subnet[0].subnets[0].ext_id, null)
  )

  ##################################################
  # Summary (known at plan time; safe to assert on)
  ##################################################

  pc_deploy_summary = {
    name                   = var.prism_central.name
    size                   = var.prism_central.size
    version                = var.prism_central.version
    high_availability      = var.prism_central.should_enable_high_availability
    lockdown_mode          = var.prism_central.should_enable_lockdown_mode
    external_address       = var.network.external_address
    name_server_count      = length(var.network.name_servers)
    ntp_server_count       = length(var.network.ntp_servers)
    registered_pe_count    = length(var.prism_element)
    unregistration_enabled = var.enable_unregistration
    create_timeout         = var.deploy_timeout
  }
}
