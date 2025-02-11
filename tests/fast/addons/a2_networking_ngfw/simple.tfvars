_fast_debug = {
  skip_datasources = true
}
automation = {
  outputs_bucket = "test"
}
certificate_authorities = {
  ngfw-0 = {
    location = "europe-west8"
    ca_configs = {
      ca-0 = {
        deletion_protection = false
        subject = {
          common_name  = "fast.example.com"
          organization = "FAST Test"
        }
      }
    }
  }
}
ngfw_config = {
  name           = "ngfw-0"
  endpoint_zones = ["europe-west8-b"]
  network_associations = {
    prod = {
      vpc_id                = "projects/xxx-prod-net-spoke-0/global/networks/prod-spoke-0"
      tls_inspection_policy = "ngfw-0"
    }
  }
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
project_id = "xxx-prod-net-landing-0"
security_profiles = {
  ngfw-0 = {
    threat_prevention_profile = {
      severity_overrides = {
        informational-allow = {
          action   = "ALLOW"
          severity = "INFORMATIONAL"
        }
      }
      threat_overrides = {
        allow-280647 = {
          action    = "ALLOW"
          threat_id = "280647"
        }
      }
    }
  }
}
tls_inspection_policies = {
  ngfw-0 = {
    ca_pool_id   = "ngfw-0"
    location     = "europe-west8"
    trust_config = "ngfw-0"
  }
}
trust_configs = {
  ngfw-0 = {
    location = "europe-west8"
    allowlisted_certificates = {
      server-0 = "../../../tests/fast/addons/a2_networking_ngfw/data/example.com.cert.pem"
    }
    trust_stores = {
      ludo-joonix = {
        intermediate_cas = {
          issuing-ca-1 = "../../../tests/fast/addons/a2_networking_ngfw/data/intermediate.cert.pem"
        }
        trust_anchors = {
          root-ca-1 = "../../../tests/fast/addons/a2_networking_ngfw/data/ca.cert.pem"
        }
      }
    }
  }
}
vpc_self_links = {
  dev-spoke-0  = "https://www.googleapis.com/compute/v1/projects/123456789/networks/vpc-1"
  prod-spoke-0 = "https://www.googleapis.com/compute/v1/projects/123456789/networks/vpc-2"
}
