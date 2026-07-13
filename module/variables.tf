##################################################
# Prism Central (deploy target)
##################################################

# The Prism Central instance to deploy onto the Prism Element cluster.
variable "prism_central" {
  description = "Prism Central instance to deploy. Wraps the config block of nutanix_pc_deploy_v2."
  type = object({
    # Identity & sizing
    name    = string                        # Name for the Prism Central instance.
    size    = optional(string, "SMALL")     # STARTER, SMALL, LARGE or EXTRALARGE.
    version = optional(string, "pc.2024.3") # PC build version (e.g. "pc.2024.3").

    # Deployment behaviour
    should_enable_high_availability = optional(bool, false) # Scale-out (3-VM) Prism Central.
    should_enable_lockdown_mode     = optional(bool, false) # Disable password based CVM/PCVM ssh.

    # Admin credentials for the deployed Prism Central (optional).
    credentials = optional(object({
      username = string
      password = string
    }), null)

    # Optional resource sizing overrides for the Prism Central VM(s).
    resource_config = optional(object({
      num_vcpus            = optional(number, null)
      memory_size_bytes    = optional(number, null)
      data_disk_size_bytes = optional(number, null)
      container_ext_ids    = optional(list(string), null)
    }), null)
  })

  # Prism Central size must be one of the supported form factors.
  validation {
    condition     = contains(["STARTER", "SMALL", "LARGE", "EXTRALARGE"], var.prism_central.size)
    error_message = "Prism Central 'size' must be one of STARTER, SMALL, LARGE or EXTRALARGE."
  }

  # A name is required and must be non-empty.
  validation {
    condition     = var.prism_central.name != null && trimspace(var.prism_central.name) != ""
    error_message = "Prism Central 'name' must be a non-empty string."
  }

  # When credentials are supplied, both username and password are required.
  validation {
    condition = var.prism_central.credentials != null ? (
      var.prism_central.credentials.username != null &&
      var.prism_central.credentials.password != null
    ) : true
    error_message = "When 'credentials' is provided, both 'username' and 'password' are required."
  }
}

##################################################
# Network
##################################################

# Network configuration for the deployed Prism Central VM.
variable "network" {
  description = "Network configuration for the Prism Central VM (maps to the network block of nutanix_pc_deploy_v2)."
  type = object({
    # Static external (VIP) address for Prism Central. Optional; when null the
    # address is allocated from the external network IP range instead.
    external_address = optional(string, null)

    # DNS and NTP servers. Values may be IPv4 addresses or FQDNs; the module
    # picks the correct provider block type automatically. At least one of each
    # is required by the provider.
    name_servers = optional(list(string), ["8.8.8.8"])
    ntp_servers  = optional(list(string), ["0.pool.ntp.org"])

    # The external (management) network the Prism Central VM attaches to.
    external_network = object({
      # Supply EITHER an explicit subnet ext_id OR a subnet name to look up.
      network_ext_id = optional(string, null)
      network_name   = optional(string, null)

      default_gateway = string # IPv4 gateway address, e.g. "10.0.0.1".
      subnet_mask     = string # IPv4 subnet mask, e.g. "255.255.255.0".

      # Range the Prism Central VM address(es) are drawn from.
      ip_range = object({
        begin = string # First usable IPv4 address in the range.
        end   = string # Last usable IPv4 address in the range.
      })
    })
  })

  # At least one name server is required by the provider (min_items = 1).
  validation {
    condition     = length(var.network.name_servers) > 0
    error_message = "At least one entry in 'network.name_servers' is required."
  }

  # At least one NTP server is required by the provider (min_items = 1).
  validation {
    condition     = length(var.network.ntp_servers) > 0
    error_message = "At least one entry in 'network.ntp_servers' is required."
  }

  # Exactly one of network_ext_id or network_name must identify the subnet.
  validation {
    condition = (
      (var.network.external_network.network_ext_id != null) !=
      (var.network.external_network.network_name != null)
    )
    error_message = "Set exactly one of 'network.external_network.network_ext_id' or 'network.external_network.network_name'."
  }
}

##################################################
# Prism Element registration (PE -> PC)
##################################################

# A map of Prism Element clusters to register against the newly deployed PC.
variable "prism_element" {
  description = "Map of Prism Element clusters to register to the deployed Prism Central, keyed by a logical name."
  type = map(object({
    # Register an already-known PE cluster by its ext_id (cluster_reference), OR
    # register a remote AOS cluster by VIP address + credentials (aos_remote_cluster_spec).
    cluster_ext_id = optional(string, null)
    remote_address = optional(string, null)
    username       = optional(string, null)
    password       = optional(string, null)
  }))
  default = {}

  # Each registration must use exactly one method.
  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      (v.cluster_ext_id != null) != (v.remote_address != null)
    ])
    error_message = "Each 'prism_element' entry must set EITHER 'cluster_ext_id' OR 'remote_address' (not both, not neither)."
  }

  # Address based registration requires credentials.
  validation {
    condition = alltrue([
      for k, v in var.prism_element :
      v.remote_address != null ? (v.username != null && v.password != null) : true
    ])
    error_message = "When registering a PE by 'remote_address', both 'username' and 'password' are required."
  }
}

##################################################
# Behaviour flags
##################################################

# Optionally manage nutanix_pc_unregistration_v2 for each registered PE.
variable "enable_unregistration" {
  description = "When true, also create nutanix_pc_unregistration_v2 resources so PE clusters are unregistered on destroy."
  type        = bool
  default     = false
}

# Create timeout for the (slow) Prism Central deployment.
variable "deploy_timeout" {
  description = "Create timeout for nutanix_pc_deploy_v2. Prism Central deployment is long running."
  type        = string
  default     = "120m"
}
