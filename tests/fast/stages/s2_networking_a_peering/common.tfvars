automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  service_project_network_admin = "organizations/123456789012/roles/foo"
}
folder_ids = {
  networking      = null
  networking-dev  = null
  networking-prod = null
}
service_accounts = {
  data-platform-dev    = "string"
  data-platform-prod   = "string"
  gke-dev              = "string"
  gke-prod             = "string"
  project-factory-dev  = "string"
  project-factory-prod = "string"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
vpn_onprem_primary_config = {
  peer_external_gateways = {
    default = {
      redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
      interfaces      = ["8.8.8.8"]
    }
  }
  router_config = {
    asn = 65501
    custom_advertise = {
      all_subnets = false
      ip_ranges   = { "10.1.0.0/16" = "gcp" }
    }
  }
  tunnels = {
    "0" = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 65500
      }
      bgp_session_range     = "169.254.1.2/30"
      shared_secret         = "foo"
      vpn_gateway_interface = 0
    }
    "1" = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      shared_secret         = "foo"
      vpn_gateway_interface = 1
    }
  }
}
