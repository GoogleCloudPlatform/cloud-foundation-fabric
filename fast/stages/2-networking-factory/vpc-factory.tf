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

  _peerings = {
    for k, v in local._vpcs : k => v.peering_configs if try(v.peering_configs != null, false)
  }

  peerings = merge([
    for vpc, peering_configs in local._peerings : {
      for peering_name, config in peering_configs :
      "${vpc}/${peering_name}" => {
        local_network                       = module.vpcs[vpc].self_link
        peer_network                        = module.vpcs[config.peer_network].self_link
        export_custom_routes                = try(config.routes_config.export, true)
        import_custom_routes                = try(config.routes_config.import, true)
        export_subnet_routes_with_public_ip = try(config.routes_config.public_export, null)
        import_subnet_routes_with_public_ip = try(config.routes_config.public_import, null)
      }
  }]...)


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
        auto_create_subnetworks           = try(v.auto_create_subnetworks, false)
        create_googleapis_routes          = try(v.create_googleapis_routes, {})
        delete_default_routes_on_create   = try(v.delete_default_routes_on_create, false)
        description                       = try(v.description, "Terraform-managed.")
        dns_policy                        = try(v.dns_policy, {})
        firewall_policy_enforcement_order = try(v.firewall_policy_enforcement_order, "AFTER_CLASSIC_FIREWALL")
        ipv6_config                       = try(v.ipv6_config, {})
        mtu                               = try(v.mtu, null)
        network_attachments               = try(v.network_attachments, {})
        policy_based_routes               = try(v.policy_based_routes, {})
        psa_configs                       = try(v.psa_configs, [])
        routes                            = try(v.routes, {})
        routing_mode                      = try(v.routing_mode, "GLOBAL")
        subnets_factory_config            = try(v.subnets_factory_config, {})
        firewall_factory_config           = try(v.firewall_factory_config, {})
        peering_configs                   = try(v.peering_configs, {})
        vpn_configs                       = try(v.vpn_configs, {})
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
}

module "firewall" {
  source               = "../../../modules/net-vpc-firewall"
  for_each             = { for k, v in local.vpcs : k => v if v.firewall_factory_config != null }
  project_id           = each.value.project_id
  network              = each.value.name
  factories_config     = each.value.firewall_factory_config
  default_rules_config = { disabled = true }
  depends_on           = [module.vpcs]
}

#TODO(sruffilli): implement stack_type
resource "google_compute_network_peering" "local_network_peering" {
  for_each                            = local.peerings
  name                                = replace(each.key, "/", "-")
  network                             = each.value.local_network
  peer_network                        = each.value.peer_network
  export_custom_routes                = each.value.export_custom_routes
  import_custom_routes                = each.value.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
}


resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  for_each   = local.vpns
  project    = each.value.project_id
  region     = each.value.region
  name       = replace(each.key, "/", "-")
  network    = each.value.vpc_name
  stack_type = "IPV4_ONLY"
  depends_on = [module.vpcs]
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
        #TODO(sruffilli): create a lookup table instead, that only does this replacement if value exists, 
        #to allow passing an arbitrary gateway id
        gw_type == "gcp" ? google_compute_ha_vpn_gateway.ha_gateway[value].id : value
      )
    }
  }
}
