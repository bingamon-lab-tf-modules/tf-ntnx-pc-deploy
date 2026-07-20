# tf-ntnx-pc-deploy

## Table of Contents

## Overview

A description of the module goes here.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_nutanix"></a> [nutanix](#requirement\_nutanix) | >= 2.4.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nutanix"></a> [nutanix](#provider\_nutanix) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nutanix_pc_deploy_v2.this](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/pc_deploy_v2) | resource |
| [nutanix_pc_registration_v2.this](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/pc_registration_v2) | resource |
| [nutanix_pc_unregistration_v2.this](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/pc_unregistration_v2) | resource |
| [nutanix_subnets_v2.external_subnet](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/subnets_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_timeout"></a> [deploy\_timeout](#input\_deploy\_timeout) | Create timeout for nutanix\_pc\_deploy\_v2. Prism Central deployment is long running. | `string` | `"120m"` | no |
| <a name="input_enable_unregistration"></a> [enable\_unregistration](#input\_enable\_unregistration) | When true, also create nutanix\_pc\_unregistration\_v2 resources so PE clusters are unregistered on destroy. | `bool` | `false` | no |
| <a name="input_network"></a> [network](#input\_network) | Network configuration for the Prism Central VM (maps to the network block of nutanix\_pc\_deploy\_v2). | <pre>object({<br/>    # Static external (VIP) address for Prism Central. Optional; when null the<br/>    # address is allocated from the external network IP range instead.<br/>    external_address = optional(string, null)<br/><br/>    # DNS and NTP servers. Values may be IPv4 addresses or FQDNs; the module<br/>    # picks the correct provider block type automatically. At least one of each<br/>    # is required by the provider.<br/>    name_servers = optional(list(string), ["8.8.8.8"])<br/>    ntp_servers  = optional(list(string), ["0.pool.ntp.org"])<br/><br/>    # The external (management) network the Prism Central VM attaches to.<br/>    external_network = object({<br/>      # Supply EITHER an explicit subnet ext_id OR a subnet name to look up.<br/>      network_ext_id = optional(string, null)<br/>      network_name   = optional(string, null)<br/><br/>      default_gateway = string # IPv4 gateway address, e.g. "10.0.0.1".<br/>      subnet_mask     = string # IPv4 subnet mask, e.g. "255.255.255.0".<br/><br/>      # Range the Prism Central VM address(es) are drawn from.<br/>      ip_range = object({<br/>        begin = string # First usable IPv4 address in the range.<br/>        end   = string # Last usable IPv4 address in the range.<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_prism_central"></a> [prism\_central](#input\_prism\_central) | Prism Central instance to deploy. Wraps the config block of nutanix\_pc\_deploy\_v2. | <pre>object({<br/>    # Identity & sizing<br/>    name    = string                        # Name for the Prism Central instance.<br/>    size    = optional(string, "SMALL")     # STARTER, SMALL, LARGE or EXTRALARGE.<br/>    version = optional(string, "pc.2024.3") # PC build version (e.g. "pc.2024.3").<br/><br/>    # Deployment behaviour<br/>    should_enable_high_availability = optional(bool, false) # Scale-out (3-VM) Prism Central.<br/>    should_enable_lockdown_mode     = optional(bool, false) # Disable password based CVM/PCVM ssh.<br/><br/>    # Admin credentials for the deployed Prism Central (optional).<br/>    credentials = optional(object({<br/>      username = string<br/>      password = string<br/>    }), null)<br/><br/>    # Optional resource sizing overrides for the Prism Central VM(s).<br/>    resource_config = optional(object({<br/>      num_vcpus            = optional(number, null)<br/>      memory_size_bytes    = optional(number, null)<br/>      data_disk_size_bytes = optional(number, null)<br/>      container_ext_ids    = optional(list(string), null)<br/>    }), null)<br/>  })</pre> | n/a | yes |
| <a name="input_prism_element"></a> [prism\_element](#input\_prism\_element) | Map of Prism Element clusters to register to the deployed Prism Central, keyed by a logical name. | <pre>map(object({<br/>    # Register an already-known PE cluster by its ext_id (cluster_reference), OR<br/>    # register a remote AOS cluster by VIP address + credentials (aos_remote_cluster_spec).<br/>    cluster_ext_id = optional(string, null)<br/>    remote_address = optional(string, null)<br/>    username       = optional(string, null)<br/>    password       = optional(string, null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deploy_task_status"></a> [deploy\_task\_status](#output\_deploy\_task\_status) | Status reference for the Prism Central deployment task. |
| <a name="output_outputs"></a> [outputs](#output\_outputs) | Aggregate of all module outputs. |
| <a name="output_pc_deploy_summary"></a> [pc\_deploy\_summary](#output\_pc\_deploy\_summary) | Human-readable summary of the requested Prism Central deployment (known at plan time). |
| <a name="output_pc_ext_id"></a> [pc\_ext\_id](#output\_pc\_ext\_id) | External identifier (ext\_id) of the deployed Prism Central. |
| <a name="output_pc_fqdn"></a> [pc\_fqdn](#output\_pc\_fqdn) | The fully qualified domain name assigned to the deployed Prism Central (computed by the provider). |
| <a name="output_pc_vip"></a> [pc\_vip](#output\_pc\_vip) | The Prism Central external (VIP) address. Null when allocated from the external network IP range. |
| <a name="output_registration_status"></a> [registration\_status](#output\_registration\_status) | Registration status for each Prism Element cluster registered to Prism Central. |
<!-- END_TF_DOCS -->
