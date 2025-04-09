/**
 * Copyright 2024 Google LLC
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

variable "alert_config" {
  description = "Configuration for monitoring alerts."
  type = object({
    vpn_tunnel_established = optional(object({
      auto_close            = optional(string, null)
      duration              = optional(string, "120s")
      enabled               = optional(bool, true)
      notification_channels = optional(list(string), [])
      user_labels           = optional(map(string), {})
    }))
    vpn_tunnel_bandwidth = optional(object({
      auto_close            = optional(string, null)
      duration              = optional(string, "120s")
      enabled               = optional(bool, true)
      notification_channels = optional(list(string), [])
      threshold_mbys        = optional(string, "187.5")
      user_labels           = optional(map(string), {})
    }))
  })
  default = {
    vpn_tunnel_established = {}
    vpn_tunnel_bandwidth   = {}
  }
}

variable "dns" {
  description = "DNS configuration."
  type = object({
    gcp_domain    = optional(string, "gcp.example.com")
    onprem_domain = optional(string, "onprem.example.com")
    resolvers     = optional(list(string), [])
  })
  default  = {}
  nullable = false
}

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Configuration for network resource factories."
  type = object({
    dashboards       = optional(string, "data/dashboards")
    dns_policy_rules = optional(string, "data/dns-policy-rules.yaml")
    firewall = optional(object({
      cidr_file     = optional(string, "data/cidrs.yaml")
      classic_rules = optional(string, "data/firewall-rules")
      hierarchical = optional(object({
        egress_rules  = optional(string, "data/hierarchical-egress-rules.yaml")
        ingress_rules = optional(string, "data/hierarchical-ingress-rules.yaml")
        policy_name   = optional(string, "net-default")
      }), {})
      policy_rules = optional(string, "data/firewall-policies")
    }), {})
    subnets = optional(string, "data/subnets")
  })
  default  = {}
  nullable = false
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "psa_ranges" {
  description = "IP ranges used for Private Service Access (CloudSQL, etc.)."
  type = object({
    dev = optional(list(object({
      ranges         = map(string)
      export_routes  = optional(bool, false)
      import_routes  = optional(bool, false)
      peered_domains = optional(list(string), [])
    })), [])
    prod = optional(list(object({
      ranges         = map(string)
      export_routes  = optional(bool, false)
      import_routes  = optional(bool, false)
      peered_domains = optional(list(string), [])
    })), [])
  })
  nullable = false
  default  = {}
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

variable "spoke_configs" {
  description = "Spoke connectivity configurations."
  type = object({
    ncc_configs = optional(object({
      export_psc = optional(bool, true)
      dev = optional(object({
        exclude_export_ranges = list(string)
        }), {
        exclude_export_ranges = []
      })
      prod = optional(object({
        exclude_export_ranges = list(string)
        }), {
        exclude_export_ranges = []
      })
    }))
    peering_configs = optional(object({
      dev = optional(object({
        export        = optional(bool, true)
        import        = optional(bool, true)
        public_export = optional(bool)
        public_import = optional(bool)
      }), {})
      prod = optional(object({
        export        = optional(bool, true)
        import        = optional(bool, true)
        public_export = optional(bool)
        public_import = optional(bool)
      }), {})
    }))
    vpn_configs = optional(object({
      dev = optional(object({
        asn = optional(number, 65501)
        custom_advertise = optional(object({
          all_subnets = bool
          ip_ranges   = map(string)
        }))
      }), {})
      landing = optional(object({
        asn = optional(number, 65500)
        custom_advertise = optional(object({
          all_subnets = bool
          ip_ranges   = map(string)
        }))
      }), {})
      prod = optional(object({
        asn = optional(number, 65502)
        custom_advertise = optional(object({
          all_subnets = bool
          ip_ranges   = map(string)
        }))
      }), {})
    }))
  })
  default = {
    peering_configs = {}
  }
  validation {
    condition = length(
      compact([
        var.spoke_configs.peering_configs != null ? "peering" : null,
        var.spoke_configs.vpn_configs != null ? "vpn" : null,
        var.spoke_configs.ncc_configs != null ? "ncc" : null,
      ])
    ) == 1
    error_message = "Only one of `var.spoke_configs.ncc_configs`, `var.spoke_configs.peering_configs` or `var.spoke_configs.vpn_configs` must be configured."
  }
}

variable "vpc_configs" {
  description = "Optional VPC network configurations."
  type = object({
    dev = optional(object({
      mtu = optional(number, 1500)
      cloudnat = optional(object({
        enable = optional(bool, false)
      }), {})
      dns = optional(object({
        create_inbound_policy = optional(bool, true)
        enable_logging        = optional(bool, true)
      }), {})
      firewall = optional(object({
        create_policy       = optional(bool, false)
        policy_has_priority = optional(bool, false)
        use_classic         = optional(bool, true)
      }), {})
    }), {})
    landing = optional(object({
      mtu = optional(number, 1500)
      cloudnat = optional(object({
        enable = optional(bool, false)
      }), {})
      dns = optional(object({
        create_inbound_policy = optional(bool, true)
        enable_logging        = optional(bool, true)
      }), {})
      firewall = optional(object({
        create_policy       = optional(bool, false)
        policy_has_priority = optional(bool, false)
        use_classic         = optional(bool, true)
      }), {})
    }), {})
    prod = optional(object({
      mtu = optional(number, 1500)
      cloudnat = optional(object({
        enable = optional(bool, false)
      }), {})
      dns = optional(object({
        create_inbound_policy = optional(bool, true)
        enable_logging        = optional(bool, true)
      }), {})
      firewall = optional(object({
        create_policy       = optional(bool, false)
        policy_has_priority = optional(bool, false)
        use_classic         = optional(bool, true)
      }), {})
    }), {})
  })
  nullable = false
  default  = {}
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
