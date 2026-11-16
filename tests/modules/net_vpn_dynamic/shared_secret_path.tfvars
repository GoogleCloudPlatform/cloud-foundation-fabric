project_id             = "foo-test-0"
network                = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
region                 = "europe-west8"
name                   = "test"
gateway_address_create = false
gateway_address        = "35.242.0.10"
router_config = {
  asn    = 64513
  create = false
  name   = "vpn-to-onprem-ew8"
}
tunnels = {
  remote-0 = {
    bgp_peer = {
      address = "169.254.1.2"
      asn     = 64514
    }
    bgp_session_range = "169.254.1.1/30"
    peer_ip           = "1.1.1.1"
    shared_secret = {
      path       = "./vpn-secret/shared-secret.txt"
      wo_version = 1
    }
  }
}
