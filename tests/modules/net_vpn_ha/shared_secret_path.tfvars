project_id = "foo-test-0"
network    = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
region     = "europe-west8"
name       = "test"
router_config = {
  asn    = 64513
  create = false
  name   = "vpn-to-onprem-ew8"
}
peer_gateways = {
  default = {
    gcp = "projects/foo-prod-net-landing-1/regions/europe-west8/vpnGateways/vpn-to-onprem-ew8"
  }
}
tunnels = {
  remote-0 = {
    bgp_peer = {
      address = "169.254.1.2"
      asn     = 64514
    }
    bgp_session_range = "169.254.1.1/30"
    shared_secret = {
      path       = "./vpn-secret/shared-secret.txt"
      wo_version = 1
    }
    vpn_gateway_interface = 0
  }
}
vpn_gateway        = "projects/foo-prod-net-landing-0/regions/europe-west8/vpnGateways/vpn-to-onprem-ew8"
vpn_gateway_create = null
