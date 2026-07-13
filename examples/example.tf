terraform {
  required_version = ">= 1.9.0"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 2.4.2"
    }
  }
}

# IMPORTANT: This module deploys Prism Central and therefore must connect to the
# Prism Element (PE) cluster VIP, NOT a Prism Central endpoint. Prism Central
# does not exist yet when this module runs.
provider "nutanix" {
  endpoint = var.prism_element_vip # PE cluster VIP.
  username = var.pe_username
  password = var.pe_password
  insecure = true
}

variable "prism_element_vip" {
  description = "Prism Element cluster VIP the deployment runs against."
  type        = string
}

variable "pe_username" {
  description = "Prism Element username."
  type        = string
}

variable "pe_password" {
  description = "Prism Element password."
  type        = string
  sensitive   = true
}

module "pc_deploy" {
  source = "git::https://github.com/bingamon-lab-tf-modules/tf-ntnx-pc-deploy.git//module?ref=v1.0.0"

  # Prism Central instance to deploy.
  prism_central = {
    name    = "pc-lab"
    size    = "SMALL"
    version = "pc.2024.3"

    # Admin credentials for the new Prism Central.
    credentials = {
      username = "admin"
      password = "nutanix/4u"
    }
  }

  # Network configuration for the Prism Central VM.
  network = {
    # Static VIP for Prism Central (omit to allocate from the range instead).
    external_address = "10.0.0.40"

    name_servers = ["10.0.0.10", "10.0.0.11"]
    ntp_servers  = ["0.pool.ntp.org", "1.pool.ntp.org"]

    external_network = {
      # Look the subnet up by name (or set network_ext_id directly).
      network_name    = "external"
      default_gateway = "10.0.0.1"
      subnet_mask     = "255.255.255.0"
      ip_range = {
        begin = "10.0.0.50"
        end   = "10.0.0.60"
      }
    }
  }

  # Prism Element cluster(s) to register to the newly deployed Prism Central.
  prism_element = {
    cluster_1 = {
      # Register the hosting PE cluster by its VIP + credentials.
      remote_address = var.prism_element_vip
      username       = var.pe_username
      password       = var.pe_password
    }
  }

  # Unregister the PE cluster(s) from Prism Central on destroy.
  enable_unregistration = true

  # Prism Central deployment is long running.
  deploy_timeout = "120m"
}

output "pc_deploy_summary" {
  description = "Summary of the Prism Central deployment."
  value       = module.pc_deploy.pc_deploy_summary
}

output "outputs" {
  description = "Aggregate outputs from the Prism Central deploy module."
  value       = module.pc_deploy.outputs
}
