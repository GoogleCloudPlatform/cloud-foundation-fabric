/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
  })
  validation {
    condition     = var.billing_account.is_org_level != null
    error_message = "Invalid `null` value for `billing_account.is_org_level`."
  }
}

variable "custom_roles" {
  # tfdoc:variable:source 0-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    service_project_network_admin = string
  })
  default = null
}

variable "dns" {
  description = "Onprem DNS resolvers."
  type        = map(list(string))
  default = {
    onprem = ["10.0.200.3"]
  }
}

variable "factories_config" {
  description = "Configuration for network resource factories."
  type = object({
    data_dir             = optional(string, "data")
    firewall_policy_name = optional(string, "factory")
  })
  default = {
    data_dir = "data"
  }
  nullable = false
  validation {
    condition     = var.factories_config.data_dir != null
    error_message = "Data folder needs to be non-null."
  }
  validation {
    condition     = var.factories_config.firewall_policy_name != null
    error_message = "Firewall policy name needs to be non-null."
  }
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created."
  type = object({
    networking      = string
    networking-dev  = string
    networking-prod = string
  })
}

variable "gcp_ranges" {
  description = "GCP address ranges in name => range format."
  type        = map(string)
  default = {
    gcp_dev_primary                 = "10.128.128.0/19"
    gcp_dev_secondary               = "10.128.160.0/19"
    gcp_landing_trusted_primary     = "10.128.64.0/19"
    gcp_landing_trusted_secondary   = "10.128.96.0/19"
    gcp_landing_untrusted_primary   = "10.128.0.0/19"
    gcp_landing_untrusted_secondary = "10.128.32.0/19"
    gcp_prod_primary                = "10.128.192.0/19"
    gcp_prod_secondary              = "10.128.224.0/19"
  }
}

variable "onprem_cidr" {
  description = "Onprem addresses in name => range format."
  type        = map(string)
  default = {
    main = "10.0.0.0/24"
  }
}

variable "organization" {
  # tfdoc:variable:source 0-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "psa_ranges" {
  description = "IP ranges used for Private Service Access (e.g. CloudSQL). Ranges is in name => range format."
  type = object({
    dev = object({
      ranges = map(string)
      routes = object({
        export = bool
        import = bool
      })
    })
    prod = object({
      ranges = map(string)
      routes = object({
        export = bool
        import = bool
      })
    })
  })
  default = null
}

variable "regions" {
  description = "Region definitions."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "europe-west1"
    secondary = "europe-west4"
  }
}

variable "service_accounts" {
  # tfdoc:variable:source 1-resman
  description = "Automation service accounts in name => email format."
  type = object({
    data-platform-dev    = string
    data-platform-prod   = string
    gke-dev              = string
    gke-prod             = string
    project-factory-dev  = string
    project-factory-prod = string
  })
  default = null
}

variable "vpn_onprem_primary_config" {
  description = "VPN gateway configuration for onprem interconnection in the primary region."
  type = object({
    peer_external_gateways = map(object({
      redundancy_type = string
      interfaces      = list(string)
    }))
    router_config = object({
      create    = optional(bool, true)
      asn       = number
      name      = optional(string)
      keepalive = optional(number)
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string)
      }))
    })
    tunnels = map(object({
      bgp_peer = object({
        address        = string
        asn            = number
        route_priority = optional(number, 1000)
        custom_advertise = optional(object({
          all_subnets          = bool
          all_vpc_subnets      = bool
          all_peer_vpc_subnets = bool
          ip_ranges            = map(string)
        }))
      })
      # each BGP session on the same Cloud Router must use a unique /30 CIDR
      # from the 169.254.0.0/16 block.
      bgp_session_range               = string
      ike_version                     = optional(number, 2)
      peer_external_gateway_interface = optional(number)
      peer_gateway                    = optional(string, "default")
      router                          = optional(string)
      shared_secret                   = optional(string)
      vpn_gateway_interface           = number
    }))
  })
  default = null
}

variable "vpn_onprem_secondary_config" {
  description = "VPN gateway configuration for onprem interconnection in the secondary region."
  type = object({
    peer_external_gateways = map(object({
      redundancy_type = string
      interfaces      = list(string)
    }))
    router_config = object({
      create    = optional(bool, true)
      asn       = number
      name      = optional(string)
      keepalive = optional(number)
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string)
      }))
    })
    tunnels = map(object({
      bgp_peer = object({
        address        = string
        asn            = number
        route_priority = optional(number, 1000)
        custom_advertise = optional(object({
          all_subnets          = bool
          all_vpc_subnets      = bool
          all_peer_vpc_subnets = bool
          ip_ranges            = map(string)
        }))
      })
      # each BGP session on the same Cloud Router must use a unique /30 CIDR
      # from the 169.254.0.0/16 block.
      bgp_session_range               = string
      ike_version                     = optional(number, 2)
      peer_external_gateway_interface = optional(number)
      peer_gateway                    = optional(string, "default")
      router                          = optional(string)
      shared_secret                   = optional(string)
      vpn_gateway_interface           = number
    }))
  })
  default = null
}
