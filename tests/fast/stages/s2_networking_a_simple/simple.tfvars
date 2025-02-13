automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  project_iam_viewer            = "organizations/123456789012/roles/bar"
  service_project_network_admin = "organizations/123456789012/roles/foo"
}
dns = {
  resolvers = ["10.10.10.10"]
}
environments = {
  dev = {
    is_default = false
    name       = "Development"
    tag_name   = "development"
  }
  prod = {
    is_default = true
    name       = "Production"
    tag_name   = "production"
  }
}
essential_contacts = "gcp-network-admins@fast.example.com"
folder_ids = {
  networking      = "folders/12345"
  networking-dev  = null
  networking-prod = null
}
groups = {
  gcp-network-admins = "gcp-vpc-network-admins"
}
service_accounts = {
  data-platform-dev    = "string"
  data-platform-prod   = "string"
  gke-dev              = "string"
  gke-prod             = "string"
  project-factory      = "string"
  project-factory-dev  = "string"
  project-factory-prod = "string"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
stage_config = {
  networking = {
    iam_delegated_principals = {
      dev = [
        "serviceAccount:fast2-dev-resman-gcve-0@fast2-prod-iac-core-0.iam.gserviceaccount.com",
        "serviceAccount:fast2-dev-resman-pf-0@fast2-prod-iac-core-0.iam.gserviceaccount.com"
      ]
      prod = [
        "serviceAccount:fast2-prod-resman-gcve-0@fast2-prod-iac-core-0.iam.gserviceaccount.com",
        "serviceAccount:fast2-prod-resman-pf-0@fast2-prod-iac-core-0.iam.gserviceaccount.com"
      ]
    }
    iam_viewer_principals = {
      dev = [
        "serviceAccount:fast2-dev-resman-gcve-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com",
        "serviceAccount:fast2-dev-resman-pf-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com"
      ]
      prod = [
        "serviceAccount:fast2-prod-resman-gcve-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com",
        "serviceAccount:fast2-prod-resman-pf-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com"
      ]
    }
    short_name = "net"
  }
}
tag_values = {
  "environment/development" = "tagValues/12345"
  "environment/production"  = "tagValues/12346"
}
vpc_configs = {
  dev = {
    cloudnat = {
      enable = true
    }
  }
  landing = {
    cloudnat = {
      enable = true
    }
  }
  prod = {
    cloudnat = {
      enable = true
    }
  }
}
# spoke_configs defaults to peering
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
