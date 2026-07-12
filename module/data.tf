##################################################
# Data Lookups
##################################################

# Resolve the external management subnet by name when an explicit ext_id was
# not supplied. The Prism Element VIP provider endpoint is queried here.
data "nutanix_subnets_v2" "external_subnet" {
  count = var.network.external_network.network_name != null ? 1 : 0

  limit  = 1
  filter = "name eq '${var.network.external_network.network_name}'"
}
