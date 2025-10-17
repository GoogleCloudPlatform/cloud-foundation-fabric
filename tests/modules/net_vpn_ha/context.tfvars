context = {
  addresses = {
    test = "8.8.8.8"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
  routers = {
    test = "vpn-to-onprem-ew8"
  }
  vpn_gateways = {
    local  = "projects/foo-prod-net-landing-0/regions/europe-west8/vpnGateways/vpn-to-onprem-ew8"
    remote = "projects/foo-prod-net-landing-1/regions/europe-west8/vpnGateways/vpn-to-onprem-ew8"
  }
}
project_id = "$project_ids:test"
network    = "$networks:test"
region     = "$locations:ew8"
name       = "test"
router_config = {
  asn    = 64513
  create = false
  name   = "$routers:test"
}
peer_gateways = {
  default = {
    gcp = "$vpn_gateways:remote"
  }
}
tunnels = {
  remote-0 = {
    bgp_peer = {
      address = "169.254.1.2"
      asn     = 64514
    }
    bgp_session_range     = "169.254.1.1/30"
    shared_secret         = "foo"
    vpn_gateway_interface = 0
  }
  remote-1 = {
    bgp_peer = {
      address = "169.254.2.2"
      asn     = 64514
    }
    bgp_session_range     = "169.254.2.1/30"
    shared_secret         = "foo"
    vpn_gateway_interface = 1
  }
}
vpn_gateway        = "$vpn_gateways:local"
vpn_gateway_create = null
