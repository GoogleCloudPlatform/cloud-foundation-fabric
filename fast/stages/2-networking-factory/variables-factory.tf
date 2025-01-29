
variable "factories_config" {
  description = "Configuration for network resource factories."
  type = object({
    vpcs                  = optional(string, "data/networks")
    dns_policy_rules_file = optional(string, "data/dns-policy-rules.yaml")
    firewall_policy_name  = optional(string, "net-default")
  })
  nullable = false
}

variable "vpc_configs" {
  description = "Consolidated configuration for the VPC and its associated resources."
  type = map(object({
    auto_create_subnetworks = optional(bool, false)
    create_googleapis_routes = optional(object({
      private      = optional(bool, true)
      private-6    = optional(bool, false)
      restricted   = optional(bool, true)
      restricted-6 = optional(bool, false)
    }), {})
    delete_default_routes_on_create = optional(bool, false)
    description                     = optional(string, "Terraform-managed.")
    dns_policy = optional(object({
      inbound = optional(bool)
      logging = optional(bool)
      outbound = optional(object({
        private_ns = list(string)
        public_ns  = list(string)
      }))
    }))
    firewall_policy_enforcement_order = optional(string, "AFTER_CLASSIC_FIREWALL")
    ipv6_config = optional(object({
      enable_ula_internal = optional(bool)
      internal_range      = optional(string)
    }), {})
    mtu  = optional(number)
    name = string
    network_attachments = optional(map(object({
      subnet                = string
      automatic_connection  = optional(bool, false)
      description           = optional(string, "Terraform-managed.")
      producer_accept_lists = optional(list(string))
      producer_reject_lists = optional(list(string))
    })), {})
    policy_based_routes = optional(map(object({
      description         = optional(string, "Terraform-managed.")
      labels              = optional(map(string))
      priority            = optional(number)
      next_hop_ilb_ip     = optional(string)
      use_default_routing = optional(bool, false)
      filter = optional(object({
        ip_protocol = optional(string)
        dest_range  = optional(string)
        src_range   = optional(string)
      }), {})
      target = optional(object({
        interconnect_attachment = optional(string)
        tags                    = optional(list(string))
      }), {})
    })), {})
    project_id = string
    psa_configs = optional(list(object({
      deletion_policy  = optional(string, null)
      ranges           = map(string)
      export_routes    = optional(bool, false)
      import_routes    = optional(bool, false)
      peered_domains   = optional(list(string), [])
      range_prefix     = optional(string)
      service_producer = optional(string, "servicenetworking.googleapis.com")
    })), [])
    routes = optional(map(object({
      description   = optional(string, "Terraform-managed.")
      dest_range    = string
      next_hop_type = string
      next_hop      = string
      priority      = optional(number)
      tags          = optional(list(string))
    })), {})
    routing_mode = optional(string, "GLOBAL")
    subnets_factory_config = optional(object({
      context = optional(object({
        regions = optional(map(string), {})
      }), {})
      subnets_folder = optional(string)
    }), {})
    firewall_factory_config = optional(object({
      cidr_tpl_file = optional(string)
      rules_folder  = optional(string)
    }), {})
    vpn_configs = optional(map(object({
      name   = string
      region = string
      peer_gateways = map(object({
        external = optional(object({
          redundancy_type = string
          interfaces      = list(string)
          description     = optional(string, "Terraform managed external VPN gateway")
          name            = optional(string)
        }))
        gcp = optional(string)
      }))
      router_config = object({
        asn    = optional(number)
        create = optional(bool, true)
        custom_advertise = optional(object({
          all_subnets = bool
          ip_ranges   = map(string)
        }))
        keepalive     = optional(number)
        name          = optional(string)
        override_name = optional(string)
      })
      tunnels = map(object({
        bgp_peer = object({
          address        = string
          asn            = number
          route_priority = optional(number, 1000)
          custom_advertise = optional(object({
            all_subnets = bool
            ip_ranges   = map(string)
          }))
          md5_authentication_key = optional(object({
            name = string
            key  = optional(string)
          }))
          ipv6 = optional(object({
            nexthop_address      = optional(string)
            peer_nexthop_address = optional(string)
          }))
          name = optional(string)
        })
        # each BGP session on the same Cloud Router must use a unique /30 CIDR
        # from the 169.254.0.0/16 block.
        bgp_session_range               = string
        ike_version                     = optional(number, 2)
        name                            = optional(string)
        peer_external_gateway_interface = optional(number)
        peer_router_interface_name      = optional(string)
        peer_gateway                    = optional(string, "default")
        router                          = optional(string)
        shared_secret                   = optional(string)
        vpn_gateway_interface           = number
      }))
    })), {})
    peering_configs = optional(map(object({
      peer_network = string
      routes_config = optional(object({
        export        = optional(bool, true)
        import        = optional(bool, true)
        public_export = optional(bool)
        public_import = optional(bool)
      }), {})
    })), {})
  }))
  default = null
}
