locals {
  vpn_config = {
    remote_asn = var.router_configs.landing-ew1.asn
    local_asn  = var.router_configs.onprem-ew1.asn
    peer1 = {
      local_bgp_address     = cidrhost(var.vpn_onprem_configs.landing-ew1.tunnels[0].session_range, 1)
      peer_ip               = module.landing-to-onprem-ew1-vpn.gateway.vpn_interfaces[0].ip_address
      peer_bgp_address      = cidrhost(var.vpn_onprem_configs.landing-ew1.tunnels[0].session_range, 2)
      remote_ip_cidr_ranges = var.custom_adv.gcp_all
      shared_secret         = var.vpn_onprem_configs.landing-ew1.tunnels[0].secret
    }
    peer2 = {
      local_bgp_address     = cidrhost(var.vpn_onprem_configs.landing-ew1.tunnels[1].session_range, 1)
      peer_ip               = module.landing-to-onprem-ew1-vpn.gateway.vpn_interfaces[1].ip_address
      peer_bgp_address      = cidrhost(var.vpn_onprem_configs.landing-ew1.tunnels[1].session_range, 2)
      remote_ip_cidr_ranges = var.custom_adv.gcp_all
      shared_secret         = var.vpn_onprem_configs.landing-ew1.tunnels[1].secret
    }
  }
}

variable "hetzner_token" {
  description = "Hetzner API Token"
}

variable "onprem_cidr" {
  description = "CIDR to use for the Hetzner VPC."
}

variable "ssh_key" {
  description = "Path to the SSH key that will be uploaded on the instance for remote access."
}

module "onprem" {
  source              = "github.com/sruffilli/fast-onprem-lab//modules/hetzner-lab"
  cloud_init_template = "../../contrib/onprem-lab/vpngw.yaml"
  hetzner_token       = var.hetzner_token
  net_cidr            = var.onprem_cidr
  ssh_key             = var.ssh_key
  vpn_config          = local.vpn_config
}
