##################################################
# Prism Central deployment outputs
##################################################

output "pc_ext_id" {
  description = "External identifier (ext_id) of the deployed Prism Central."
  value       = nutanix_pc_deploy_v2.this.id
}

output "pc_vip" {
  description = "The Prism Central external (VIP) address. Null when allocated from the external network IP range."
  value       = var.network.external_address
}

output "pc_fqdn" {
  description = "The fully qualified domain name assigned to the deployed Prism Central (computed by the provider)."
  value       = try(nutanix_pc_deploy_v2.this.network[0].fqdn, null)
}

output "deploy_task_status" {
  description = "Status reference for the Prism Central deployment task."
  value = {
    pc_ext_id         = nutanix_pc_deploy_v2.this.id
    pc_fqdn           = try(nutanix_pc_deploy_v2.this.network[0].fqdn, null)
    high_availability = nutanix_pc_deploy_v2.this.should_enable_high_availability
    create_timeout    = var.deploy_timeout
  }
}

##################################################
# Registration outputs
##################################################

output "registration_status" {
  description = "Registration status for each Prism Element cluster registered to Prism Central."
  value = {
    for k, r in nutanix_pc_registration_v2.this : k => {
      pc_ext_id                          = r.pc_ext_id
      ext_id                             = r.ext_id
      is_registered_with_hosting_cluster = r.is_registered_with_hosting_cluster
    }
  }
}

##################################################
# Summary + aggregate
##################################################

output "pc_deploy_summary" {
  description = "Human-readable summary of the requested Prism Central deployment (known at plan time)."
  value       = local.pc_deploy_summary
}

# Single aggregate output exposing everything the module produces.
output "outputs" {
  description = "Aggregate of all module outputs."
  value = {
    pc_ext_id         = nutanix_pc_deploy_v2.this.id
    pc_vip            = var.network.external_address
    pc_fqdn           = try(nutanix_pc_deploy_v2.this.network[0].fqdn, null)
    pc_deploy_summary = local.pc_deploy_summary
    deploy_task_status = {
      pc_ext_id         = nutanix_pc_deploy_v2.this.id
      pc_fqdn           = try(nutanix_pc_deploy_v2.this.network[0].fqdn, null)
      high_availability = nutanix_pc_deploy_v2.this.should_enable_high_availability
      create_timeout    = var.deploy_timeout
    }
    registration_status = {
      for k, r in nutanix_pc_registration_v2.this : k => {
        pc_ext_id                          = r.pc_ext_id
        ext_id                             = r.ext_id
        is_registered_with_hosting_cluster = r.is_registered_with_hosting_cluster
      }
    }
    unregistration_enabled = var.enable_unregistration
  }
}
