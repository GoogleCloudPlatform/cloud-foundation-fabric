automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
certificate_authorities = {
  ngfw-0 = {
    environments = ["prod"]
    ca_configs = {
      ca-0 = {
        deletion_protection = false
        subject = {
          common_name  = "fast.example.com"
          organization = "FAST Test"
        }
      }
    }
    ca_pool_config = {
      create_pool = {
        name = "ca-pool-0"
      }
    }
    location = "europe-west8"
  }
}
custom_roles = {
  project_iam_viewer            = "organizations/123456789012/roles/bar"
  service_project_network_admin = "organizations/123456789012/roles/foo"
}
environments = {
  dev = {
    is_default = false
    name       = "Development"
    short_name = "dev"
    tag_name   = "development"
  }
  prod = {
    is_default = true
    name       = "Production"
    short_name = "prod"
    tag_name   = "production"
  }
}
essential_contacts = "gcp-security-admins@fast.example.com"
folder_ids = {
  security = "folders/12345678"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
kms_keys = {
  compute = {
    iam = {
      "roles/cloudkms.admin" = ["user:user1@example.com"]
    }
    labels          = { service = "compute" }
    locations       = null
    rotation_period = null
  }
}
service_accounts = {
  security             = "foobar@iam.gserviceaccount.com"
  data-platform-dev    = "foobar@iam.gserviceaccount.com"
  data-platform-prod   = "foobar@iam.gserviceaccount.com"
  nsec                 = "foobar@iam.gserviceaccount.com"
  nsec-r               = "foobar@iam.gserviceaccount.com"
  project-factory      = "foobar@iam.gserviceaccount.com"
  project-factory-dev  = "foobar@iam.gserviceaccount.com"
  project-factory-prod = "foobar@iam.gserviceaccount.com"
}
stage_config = {
  security = {
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
