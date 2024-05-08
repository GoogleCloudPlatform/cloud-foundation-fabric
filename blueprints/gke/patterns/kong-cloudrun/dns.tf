module "private_dns_ilb" {
  source     = "../../../../modules/dns"
  project_id = var.project_id
  name       = "dns-ilb"
  zone_config = {
    domain = format("%s.", var.custom_domain)
    private = {
      client_networks = [data.google_compute_network.host-network.id]
    }
  }
  recordsets = {
    "A " = { records = [module.ilb-l7.address] }
  }
}