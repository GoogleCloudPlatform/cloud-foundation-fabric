/**
 * Copyright 2025 Google LLC
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

variable "billing_account" {
  description = "Billing account id."
  type        = string
}

variable "factories_config" {
  description = "Configuration for network resource factories."
  type = object({
    vpcs                 = optional(string, "recipes/hub-and-spoke-ncc")
    firewall_policy_name = optional(string, "net-default")
  })
  default = {
    vpcs = "recipes/hub-and-spoke-ncc"
  }
}

variable "network_project_config" {
  description = "Consolidated configuration for project, VPCs and their associated resources."
  type = map(object({
    project_config = object({
      name                    = string
      prefix                  = optional(string)
      parent                  = optional(string)
      billing_account         = optional(string)
      deletion_policy         = optional(string, "DELETE")
      default_service_account = optional(string, "keep")
      auto_create_network     = optional(bool, false)
      project_create          = optional(bool, true)
      shared_vpc_host_config = optional(object({
        enabled          = bool
        service_projects = optional(list(string), [])
      }))
      services = optional(list(string), )
      org_policies = optional(map(object({
        inherit_from_parent = optional(bool)
        reset               = optional(bool)
        rules = optional(list(object({
          allow = optional(object({
            all    = optional(bool)
            values = optional(list(string))
          }))
          deny = optional(object({
            all    = optional(bool)
            values = optional(list(string))
          }))
          enforce = optional(bool)
          condition = optional(object({
            description = optional(string)
            expression  = optional(string)
            location    = optional(string)
            title       = optional(string)
          }), {})
        })), )
      })), {})
      metric_scopes = optional(list(string), [])
      iam           = optional(map(list(string)), {})
      iam_bindings = optional(map(object({
        members = list(string)
        role    = string
        condition = optional(object({
          expression  = string
          title       = string
          description = optional(string)
        }))
      })), {})
      iam_bindings_additive = optional(map(object({
        member = string
        role   = string
        condition = optional(object({
          expression  = string
          title       = string
          description = optional(string)
        }))
      })), {})
      iam_by_principals_additive = optional(map(list(string)), {})
      iam_by_principals          = optional(map(list(string)), {})
    })
    ncc_hub_config = optional(object({
      name            = string
      description     = optional(string, "Terraform-managed.")
      preset_topology = optional(string, "MESH")
      export_psc      = optional(bool, true)
      groups = optional(map(object({
        labels      = optional(map(string))
        description = optional(string, "Terraform-managed.")
        auto_accept = optional(list(string), [])
      })))
    }))
    vpc_config = optional(map(object({
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
      dns_zones = optional(map(object({
        force_destroy = optional(bool)
        description   = optional(string, "Terraform managed.")
        iam           = optional(map(list(string)), {})
        zone_config = object({
          domain = string
          forwarding = optional(object({
            forwarders      = optional(map(string), {})
            client_networks = optional(list(string), )
          }))
          peering = optional(object({
            client_networks = optional(list(string), )
            peer_network    = string
          }))
          public = optional(object({
            dnssec_config = optional(object({
              non_existence = optional(string, "nsec3")
              state         = string
              key_signing_key = optional(object(
                { algorithm = string, key_length = number }),
                { algorithm = "rsasha256", key_length = 2048 }
              )
              zone_signing_key = optional(object(
                { algorithm = string, key_length = number }),
                { algorithm = "rsasha256", key_length = 1024 }
              )
            }))
            enable_logging = optional(bool, false)
          }))
          private = optional(object({
            client_networks             = optional(list(string), )
            service_directory_namespace = optional(string)
          }))
        })
        recordsets = optional(map(object({
          ttl     = optional(number, 300)
          records = optional(list(string))
          geo_routing = optional(list(object({
            location = string
            records  = optional(list(string))
            health_checked_targets = optional(list(object({
              load_balancer_type = string
              ip_address         = string
              port               = string
              ip_protocol        = string
              network_url        = string
              project            = string
              region             = optional(string)
            })))
          })))
          wrr_routing = optional(list(object({
            weight  = number
            records = list(string)
          })))
        })), {})
      })))
      firewall_policy_enforcement_order = optional(string, "AFTER_CLASSIC_FIREWALL")
      ipv6_config = optional(object({
        enable_ula_internal = optional(bool)
        internal_range      = optional(string)
      }), {})
      mtu  = optional(number)
      name = string
      nat_config = optional(map(object({
        region         = string
        router_create  = optional(bool, true)
        router_name    = optional(string)
        router_network = optional(string)
        router_asn     = optional(number)
        type           = optional(string, "PUBLIC")
        addresses      = optional(list(string), [])
        endpoint_types = optional(list(string))
        logging_filter = optional(string)
        config_port_allocation = optional(object({
          enable_endpoint_independent_mapping = optional(bool, true)
          enable_dynamic_port_allocation      = optional(bool, false)
          min_ports_per_vm                    = optional(number)
          max_ports_per_vm                    = optional(number, 65536)
        }), {})
        config_source_subnetworks = optional(object({
          all                 = optional(bool, true)
          primary_ranges_only = optional(bool)
          subnetworks = optional(list(object({
            self_link        = string
            all_ranges       = optional(bool, true)
            primary_range    = optional(bool, false)
            secondary_ranges = optional(list(string))
          })), [])
        }), {})
        config_timeouts = optional(object({
          icmp            = optional(number)
          tcp_established = optional(number)
          tcp_time_wait   = optional(number)
          tcp_transitory  = optional(number)
          udp             = optional(number)
        }), {})
        rules = optional(list(object({
          description   = optional(string)
          match         = string
          source_ips    = optional(list(string))
          source_ranges = optional(list(string))
        })), [])

      })))
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
      psa_config = optional(list(object({
        deletion_policy  = optional(string, null)
        ranges           = map(string)
        export_routes    = optional(bool, false)
        import_routes    = optional(bool, false)
        peered_domains   = optional(list(string), [])
        range_prefix     = optional(string)
        service_producer = optional(string, "servicenetworking.googleapis.com")
      })), [])
      routers = optional(map(object({
        region = string
        asn    = optional(number)
        custom_advertise = optional(object({
          all_subnets = bool
          ip_ranges   = map(string)
        }))
        keepalive = optional(number)
        name      = optional(string)
      })))
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
      vpn_config = optional(map(object({
        #TOFIX: are we even using name?
        name   = string
        region = string
        ncc_spoke_config = optional(object({
          hub         = string
          description = string
          labels      = map(string)
        }))
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
        stack_type = optional(string)
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
      peering_config = optional(map(object({
        peer_network = string
        routes_config = optional(object({
          export        = optional(bool, true)
          import        = optional(bool, true)
          public_export = optional(bool)
          public_import = optional(bool)
          }
        ), {})
        stack_type = optional(string)
      })), {})
      ncc_config = optional(object({
        hub                   = string
        description           = optional(string, "Terraform-managed.")
        labels                = optional(map(string))
        group                 = optional(string)
        exclude_export_ranges = optional(list(string), null)
        include_export_ranges = optional(list(string), null)
      }))
    })))
  }))
  default = null
}

variable "parent_id" {
  description = "Root node for the projects created by the factory. Must be either organizations/XXXXXXXX or folders/XXXXXXXX."
  type        = string
}

variable "prefix" {
  description = "Prefix used for projects."
  type        = string
}

variable "project_reuse" {
  description = "Reuse existing project if not null. If name and number are not passed in, a data source is used."
  type = object({
    use_data_source = optional(bool, true)
    attributes = optional(object({
      name             = string
      number           = number
      services_enabled = optional(list(string), [])
    }))
  })
  default = null
  validation {
    condition = (
      try(var.project_reuse.use_data_source, null) != false ||
      try(var.project_reuse.attributes, null) != null
    )
    error_message = "Reuse datasource can be disabled only if attributes are set."
  }
}
