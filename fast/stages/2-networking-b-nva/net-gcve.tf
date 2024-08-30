# GCVE Primary VPC

module "gcve-primary-vpc" {
  count                           = (var.network_mode == "gcve") ? 1 : 0
  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-gcve-primary-0"
  delete_default_routes_on_create = true
  mtu                             = 1500
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.data_dir}/subnets/gcve-pri"
  }
  dns_policy = {
    inbound = true
  }
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      next_hop_type = "ilb"
      next_hop      = module.ilb-gcve-nva-gcve["primary"].forwarding_rule_addresses[""]
    }
  }
  # Set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "gcve-primary-firewall" {
  count      = (var.network_mode == "gcve") ? 1 : 0
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.gcve-primary-vpc[0].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/gcve-pri"
  }
}

# GCVE Secondary VPC

module "gcve-secondary-vpc" {
  count = (var.network_mode == "gcve") ? 1 : 0

  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-gcve-secondary-0"
  delete_default_routes_on_create = true
  mtu                             = 1500
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.data_dir}/subnets/gcve-sec"
  }
  dns_policy = {
    inbound = true
  }
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      next_hop_type = "ilb"
      next_hop      = module.ilb-gcve-nva-gcve["secondary"].forwarding_rule_addresses[""]
    }
  }
  # Set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "gcve-secondary-firewall" {
  count = (var.network_mode == "gcve") ? 1 : 0

  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.gcve-secondary-vpc[0].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/gcve-sec"
  }
}
