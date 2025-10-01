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

# inputs:
#   local._projects_input: raw projects data
# outputs:
#   local.data_defaults: normalized defaults/overrides
#   local._projects_output: normalized project data

locals {
  _data_defaults = {
    defaults  = try(var.data_defaults, {})
    overrides = try(var.data_overrides, {})
  }

 data_defaults = {
    defaults = merge(
      {
        # VPC defaults - all attributes used in vpc_inputs
        vpcs = {
          project_id                      = null
          network_name                    = null
          description                     = "Managed by Terraform."
          routing_mode                    = null
          auto_create_subnetworks         = false
          delete_default_routes_on_create = true
          mtu                             = null
          dns_policy                      = null
          peering_config                  = null
          network_attachments             = null
          routers                         = {}
          vpc_reuse                       = null
          tag_bindings                    = {}
        }

        # Subnet defaults - all attributes used in subnet_inputs
        subnets = {
          name                     = null
          network_id               = null
          region                   = null
          ip_cidr_range            = null
          description              = null
          private_ip_google_access = null
          enable_flow_logs         = null
          log_config               = null
          purpose                  = null
          role                     = null
          secondary_ip_ranges      = {}  # Empty map for for_each compatibility
          subnet_create            = null
          iam                      = {}
          iam_bindings             = {}
          iam_bindings_additive    = {}
          iam_by_principals        = {}
          tag_bindings             = {}
        }

        # Firewall rule defaults - all attributes used in firewall_rule_inputs
        firewall_rules = {
          name                    = null
          network_id              = null
          project_id              = null
          direction               = "INGRESS"
          description             = null
          priority                = 1000
          disabled                = false
          deny                    = []
          allow                   = []
          source_ranges           = null
          source_tags             = null
          source_service_accounts = null
          destination_ranges      = null
          target_tags             = null
          target_service_accounts = null
          enable_logging          = null
          log_config              = null
          rule_create             = null
        }

        # Route defaults - all attributes used in route_inputs
        routes = {
          name                = null
          network_id          = null
          description         = null
          dest_range          = null
          priority            = 1000
          tags                = null
          next_hop_gateway    = null
          next_hop_instance   = null
          next_hop_ip         = null
          next_hop_vpn_tunnel = null
          next_hop_ilb        = null
          route_create        = null
        }

        # Serverless connector defaults - all attributes used in serverless_connector_inputs
        serverless_connectors = {
          name              = null
          network_id        = null
          region            = null
          ip_cidr_range     = null
          subnet            = null
          subnet_project_id = null
          min_instances     = null
          max_instances     = null
          min_throughput    = null
          max_throughput    = null
          machine_type      = "e2-micro"
          connector_create  = true
        }

        # PSC endpoint defaults - all attributes used in psc_endpoint_inputs
        psc_endpoints = {
          name               = null
          project_id         = null
          region             = null
          subnetwork         = null
          network            = null
        }

        # Address defaults - all attributes used in address_inputs
        addresses = {
          name               = null
          project_id         = null
          address_type       = "INTERNAL"
          address            = null
          region             = null
          description        = "Terraform managed."
          vpc_subnet_id      = null
          vpc_id             = null
          purpose            = null
          prefix_length      = null
          ipv6               = null
          labels             = {}
          tier               = "PREMIUM"
          address_create     = null
          service_attachment = null

        }

        # Cloud NAT defaults - all attributes used in cloud_nat_inputs
        cloud_nats = {
          name                               = null
          vpc_router_id                      = null
          nat_ip_allocate_option             = "AUTO_ONLY"
          nat_ips                            = []
          auto_network_tier                  = "PREMIUM"
          source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
          subnetworks                        = []
          icmp_idle_timeout_sec              = 30
          tcp_established_idle_timeout_sec   = 1200
          tcp_transitory_idle_timeout_sec    = 30
          tcp_time_wait_timeout_sec          = 120
          udp_idle_timeout_sec               = 30
          min_ports_per_vm                   = 64
          max_ports_per_vm                   = null
          enable_dynamic_port_allocation     = false
          enable_endpoint_independent_mapping = true
          log_config                         = null
          drain_nat_ips                      = []
          rules                              = []
          type                               = "PUBLIC"
          nat_create                         = null
        }
      },
      try(local._data_defaults.defaults, {})
    )

    # VPC/Subnet Overrides - force certain values across all resources
    overrides = merge(
       {
        # VPC overrides - all attributes used in vpc_inputs
        vpcs = {
          project_id                      = null
          network_name                    = null
          description                     = null
          routing_mode                    = null
          auto_create_subnetworks         = null
          delete_default_routes_on_create = null
          mtu                             = null
          dns_policy                      = null
          peering_config                  = null
          network_attachments             = null
          routers                         = null
          vpc_reuse                       = null
          tag_bindings                    = null
        }

        # Subnet overrides - all attributes used in subnet_inputs
        subnets = {
          name                     = null
          network_id               = null
          region                   = null
          ip_cidr_range            = null
          description              = null
          private_ip_google_access = null
          enable_flow_logs         = null
          log_config               = null
          purpose                  = null
          role                     = null
          secondary_ip_ranges      = null  # null allows override, {} would force empty
          subnet_create            = null
          iam                      = null
          iam_bindings             = null
          iam_bindings_additive    = null
          iam_by_principals        = null
          tag_bindings             = null
        }

        # Firewall rule overrides - all attributes used in firewall_rule_inputs
        firewall_rules = {
          name                    = null
          network_id              = null
          project_id              = null
          direction               = null
          description             = null
          priority                = null
          disabled                = null
          deny                    = null
          allow                   = null
          source_ranges           = null
          source_tags             = null
          source_service_accounts = null
          destination_ranges      = null
          target_tags             = null
          target_service_accounts = null
          enable_logging          = null
          log_config              = null
          rule_create             = null
        }

        # Route overrides - all attributes used in route_inputs
        routes = {
          name                = null
          network_id          = null
          description         = null
          dest_range          = null
          priority            = null
          tags                = null
          next_hop_gateway    = null
          next_hop_instance   = null
          next_hop_ip         = null
          next_hop_vpn_tunnel = null
          next_hop_ilb        = null
          route_create        = null
        }

        # Serverless connector overrides - all attributes used in serverless_connector_inputs
        serverless_connectors = {
          name              = null
          network_id        = null
          region            = null
          ip_cidr_range     = null
          subnet            = null
          subnet_project_id = null
          min_instances     = null
          max_instances     = null
          min_throughput    = null
          max_throughput    = null
          machine_type      = null
          connector_create  = null
        }

        # PSC endpoint overrides - all attributes used in psc_endpoint_inputs
        psc_endpoints = {
          name               = null
          project_id         = null
          region             = null
          subnetwork         = null
          network            = null
        }

        # Address overrides - all attributes used in address_inputs
        addresses = {
          name               = null
          project_id         = null
          address_type       = null
          address            = null
          region             = null
          description        = null
          vpc_subnet_id      = null
          vpc_id             = null
          purpose            = null
          prefix_length      = null
          ipv6               = null
          labels             = null
          tier               = null
          address_create     = null
          service_attachment = null

        }

        # Cloud NAT overrides - all attributes used in cloud_nat_inputs
        cloud_nats = {
          name                               = null
          vpc_router_id                      = null
          nat_ip_allocate_option             = null
          nat_ips                            = null
          auto_network_tier                  = null
          source_subnetwork_ip_ranges_to_nat = null
          subnetworks                        = null
          icmp_idle_timeout_sec              = null
          tcp_established_idle_timeout_sec   = null
          tcp_transitory_idle_timeout_sec    = null
          tcp_time_wait_timeout_sec          = null
          udp_idle_timeout_sec               = null
          min_ports_per_vm                   = null
          max_ports_per_vm                   = null
          enable_dynamic_port_allocation     = null
          enable_endpoint_independent_mapping = null
          log_config                         = null
          drain_nat_ips                      = null
          rules                              = null
          type                               = null
          nat_create                         = null
        }
      },
      try(local._data_defaults.overrides, {})
    )
  }
 

}