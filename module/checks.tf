##################################################
# Validation checks
##################################################

# The external network must resolve to an ext_id, either supplied directly or
# looked up by name. A null result usually means the subnet name was not found
# on the Prism Element cluster.
check "external_network_resolved" {
  assert {
    condition     = local.external_network_ext_id != null && local.external_network_ext_id != ""
    error_message = "Could not resolve the external network ext_id. Check 'network.external_network.network_ext_id' or that 'network_name' exists on the Prism Element cluster."
  }
}

# High availability Prism Central needs enough addresses in the external range,
# so at least three usable addresses should be available for a scale-out deploy.
check "ha_requires_address_range" {
  assert {
    condition = (
      !var.prism_central.should_enable_high_availability ||
      var.network.external_network.ip_range.begin != var.network.external_network.ip_range.end
    )
    error_message = "High availability Prism Central requires an external IP range with more than one address."
  }
}
