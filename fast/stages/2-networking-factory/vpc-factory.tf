locals {
  # read and decode factory files
  _vpcs_path = try(
    pathexpand(var.factories_config.vpcs), null
  )
  _vpcs_files = try(
    fileset(local._vpcs_path, "**/*.yaml"),
    []
  )
  _vpcs = {
    for f in local._vpcs_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._vpcs_path, "-")}/${f}"
    ))
  }

  _vpns = {
    for k, v in local._vpcs : k => v.vpn_configs if try(v.vpn_configs != null, false)
  }

  vpns = merge([
    for vpc, vpn_configs in local._vpns : {
      for vpn, config in vpn_configs :
      "${vpc}/${vpn}" => merge(config, {
        vpc_name   = vpc
        vpn_name   = vpn
        project_id = local.vpcs[vpc].project_id
      })
  }]...)

  vpcs = merge(
    # normalize factory data attributes with defaults and nulls
    {
      for k, v in local._vpcs : k => merge({
        project_id                        = try(v.project_id, null)
        name                              = try(v.name, k)
        auto_create_subnetworks           = try(v.auto_create_subnetworks, null)
        create_googleapis_routes          = try(v.create_googleapis_routes, null)
        delete_default_routes_on_create   = try(v.delete_default_routes_on_create, null)
        description                       = try(v.description, null)
        dns_policy                        = try(v.dns_policy, null)
        firewall_policy_enforcement_order = try(v.firewall_policy_enforcement_order, null)
        ipv6_config                       = try(v.ipv6_config, null)
        mtu                               = try(v.mtu, null)
        network_attachments               = try(v.network_attachments, null)
        policy_based_routes               = try(v.policy_based_routes, null)
        psa_configs                       = try(v.psa_configs, null)
        routes                            = try(v.routes, null)
        routing_mode                      = try(v.routing_mode, "GLOBAL")
        shared_vpc_host                   = try(v.shared_vpc_host, null)
        shared_vpc_service_projects       = try(v.shared_vpc_service_projects, null)
        subnets_factory_config            = try(v.subnets_factory_config, null)
        firewall_factory_config           = try(v.firewall_factory_config, null)
        vpn_configs                       = try(v.vpn_configs, null)
      })
    },
    var.vpc_configs
  )

}

module "vpcs" {
  source                            = "../../../modules/net-vpc"
  for_each                          = local.vpcs
  project_id                        = each.value.project_id
  name                              = each.value.name
  description                       = each.value.description
  auto_create_subnetworks           = each.value.auto_create_subnetworks
  create_googleapis_routes          = each.value.create_googleapis_routes
  delete_default_routes_on_create   = each.value.delete_default_routes_on_create
  dns_policy                        = each.value.dns_policy
  factories_config                  = each.value.subnets_factory_config
  firewall_policy_enforcement_order = each.value.firewall_policy_enforcement_order
  ipv6_config                       = each.value.ipv6_config
  mtu                               = each.value.mtu
  network_attachments               = each.value.network_attachments
  policy_based_routes               = each.value.policy_based_routes
  psa_configs                       = each.value.psa_configs
  routes                            = each.value.routes
  routing_mode                      = each.value.routing_mode
  shared_vpc_host                   = each.value.shared_vpc_host
  shared_vpc_service_projects       = each.value.shared_vpc_service_projects
}

module "firewall" {
  source               = "../../../modules/net-vpc-firewall"
  for_each             = { for k, v in local.vpcs : k => v if v.firewall_factory_config != null }
  project_id           = each.value.project_id
  network              = each.value.name
  factories_config     = each.value.firewall_factory_config
  default_rules_config = { disabled = true }
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  for_each   = local.vpns
  project    = each.value.project_id
  region     = each.value.region
  name       = replace(each.key, "/", "-")
  network    = each.value.vpc_name
  stack_type = "IPV4_ONLY"
}

module "vpn-ha" {
  source             = "../../../modules/net-vpn-ha"
  for_each           = local.vpns
  project_id         = module.vpcs[each.value.vpc_name].project_id
  name               = each.value.vpn_name
  network            = each.value.vpc_name
  region             = each.value.region
  router_config      = each.value.router_config
  tunnels            = each.value.tunnels
  vpn_gateway        = google_compute_ha_vpn_gateway.ha_gateway[each.key].id
  vpn_gateway_create = null
  peer_gateways = {
    for k, gw in each.value.peer_gateways : k => {
      for gw_type, value in gw : gw_type => (
        gw_type == "gcp" ? google_compute_ha_vpn_gateway.ha_gateway[value].id : value
      )
    }
  }
}
