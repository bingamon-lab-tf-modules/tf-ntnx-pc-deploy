###################################
# Unit Tests: Prism Central deploy
##################################################

#########################
# Provider
#########################

provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

#########################
# Mock Data (Nutanix Provider)
#########################

mock_provider "nutanix" {

  # External subnet lookup (used by the network_name path). The mock provider
  # requires every attribute of the subnet object; nested collections are empty.
  mock_data "nutanix_subnets_v2" {
    defaults = {
      subnets = [
        {
          ext_id                           = "00000000-0000-0000-0000-000000000000"
          name                             = "mock-external-subnet"
          bridge_name                      = ""
          cluster_name                     = ""
          cluster_reference                = ""
          description                      = ""
          dhcp_options                     = []
          dynamic_ip_addresses             = []
          hypervisor_type                  = ""
          ip_config                        = []
          ip_prefix                        = ""
          ip_usage                         = []
          is_advanced_networking           = false
          is_external                      = false
          is_nat_enabled                   = false
          links                            = []
          metadata                         = []
          migration_state                  = ""
          network_function_chain_reference = ""
          network_id                       = 0
          reserved_ip_addresses            = []
          subnet_type                      = ""
          virtual_switch                   = []
          virtual_switch_reference         = ""
          vpc                              = []
          vpc_reference                    = ""
        }
      ]
    }
  }
}

#########################
# Shared defaults
#########################

variables {
  prism_central = {
    name    = "pc-lab"
    size    = "SMALL"
    version = "pc.2024.3"
  }

  network = {
    name_servers = ["8.8.8.8"]
    ntp_servers  = ["0.pool.ntp.org"]
    external_network = {
      network_ext_id  = "11111111-1111-1111-1111-111111111111"
      default_gateway = "10.0.0.1"
      subnet_mask     = "255.255.255.0"
      ip_range = {
        begin = "10.0.0.50"
        end   = "10.0.0.60"
      }
    }
  }

  prism_element = {}
}

#########################
# Tests
#########################

# Test 1: Minimal valid deployment plans cleanly.
run "valid_minimal_deploy" {
  command = plan

  assert {
    condition     = output.pc_deploy_summary.name == "pc-lab"
    error_message = "Expected Prism Central name 'pc-lab'"
  }

  assert {
    condition     = output.pc_deploy_summary.size == "SMALL"
    error_message = "Expected Prism Central size 'SMALL'"
  }

  assert {
    condition     = output.pc_deploy_summary.version == "pc.2024.3"
    error_message = "Expected Prism Central version 'pc.2024.3'"
  }

  assert {
    condition     = output.pc_deploy_summary.create_timeout == "120m"
    error_message = "Expected default create timeout of 120m"
  }

  assert {
    condition     = output.pc_deploy_summary.registered_pe_count == 0
    error_message = "Expected 0 registered Prism Element clusters"
  }
}

# Test 2: Invalid Prism Central size is rejected.
run "invalid_pc_size" {
  command = plan

  variables {
    prism_central = {
      name = "pc-lab"
      size = "HUGE"
    }
  }

  expect_failures = [var.prism_central]
}

# Test 3: Empty name_servers list is rejected (provider requires >= 1).
run "empty_name_servers" {
  command = plan

  variables {
    network = {
      name_servers = []
      ntp_servers  = ["0.pool.ntp.org"]
      external_network = {
        network_ext_id  = "11111111-1111-1111-1111-111111111111"
        default_gateway = "10.0.0.1"
        subnet_mask     = "255.255.255.0"
        ip_range        = { begin = "10.0.0.50", end = "10.0.0.60" }
      }
    }
  }

  expect_failures = [var.network]
}

# Test 4: Setting both network_ext_id and network_name is rejected.
run "network_id_and_name_conflict" {
  command = plan

  variables {
    network = {
      name_servers = ["8.8.8.8"]
      ntp_servers  = ["0.pool.ntp.org"]
      external_network = {
        network_ext_id  = "11111111-1111-1111-1111-111111111111"
        network_name    = "external"
        default_gateway = "10.0.0.1"
        subnet_mask     = "255.255.255.0"
        ip_range        = { begin = "10.0.0.50", end = "10.0.0.60" }
      }
    }
  }

  expect_failures = [var.network]
}

# Test 5: Subnet resolved by name plans cleanly (exercises the data lookup).
run "subnet_lookup_by_name" {
  command = plan

  variables {
    network = {
      name_servers = ["8.8.8.8", "ns.lab.local"]
      ntp_servers  = ["0.pool.ntp.org", "10.0.0.2"]
      external_network = {
        network_name    = "mock-external-subnet"
        default_gateway = "10.0.0.1"
        subnet_mask     = "255.255.255.0"
        ip_range        = { begin = "10.0.0.50", end = "10.0.0.60" }
      }
    }
  }

  assert {
    condition     = output.pc_deploy_summary.name_server_count == 2
    error_message = "Expected 2 name servers"
  }
}

# Test 6: Register a Prism Element cluster by ext_id.
run "register_by_reference" {
  command = plan

  variables {
    prism_element = {
      pe1 = {
        cluster_ext_id = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  assert {
    condition     = output.pc_deploy_summary.registered_pe_count == 1
    error_message = "Expected 1 registered Prism Element cluster"
  }
}

# Test 7: Register a Prism Element cluster by remote address + credentials.
run "register_by_address" {
  command = plan

  variables {
    prism_element = {
      pe1 = {
        remote_address = "10.0.0.9"
        username       = "admin"
        password       = "nutanix/4u"
      }
    }
  }

  assert {
    condition     = output.pc_deploy_summary.registered_pe_count == 1
    error_message = "Expected 1 registered Prism Element cluster"
  }
}

# Test 8: A registration setting both methods is rejected.
run "register_both_methods_conflict" {
  command = plan

  variables {
    prism_element = {
      pe1 = {
        cluster_ext_id = "22222222-2222-2222-2222-222222222222"
        remote_address = "10.0.0.9"
      }
    }
  }

  expect_failures = [var.prism_element]
}

# Test 9: Address based registration without credentials is rejected.
run "register_address_without_credentials" {
  command = plan

  variables {
    prism_element = {
      pe1 = {
        remote_address = "10.0.0.9"
      }
    }
  }

  expect_failures = [var.prism_element]
}

# Test 10: Enabling unregistration plans cleanly.
run "unregistration_enabled" {
  command = plan

  variables {
    enable_unregistration = true
    prism_element = {
      pe1 = {
        cluster_ext_id = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  assert {
    condition     = output.pc_deploy_summary.unregistration_enabled == true
    error_message = "Expected unregistration to be enabled"
  }
}

# Test 11: High availability deployment plans cleanly.
run "high_availability_deploy" {
  command = plan

  variables {
    prism_central = {
      name                            = "pc-lab-ha"
      size                            = "LARGE"
      version                         = "pc.2024.3"
      should_enable_high_availability = true
    }
  }

  assert {
    condition     = output.pc_deploy_summary.high_availability == true
    error_message = "Expected high availability to be enabled"
  }
}
