billing_account = {
  id = "000000-111111-222222"
}
cas_ids = {
  "dev" = {
    "dev-ca-0" = {
      "ca_ids" = {
        "dev-root-ngfw-ca-0" = "projects/dev-sec-core-0/locations/europe-west1/caPools/dev-ngfw-ca-pool-3/certificateAuthorities/dev-root-ngfw-ca-0"
      }
      "ca_pool_id" = "projects/dev-sec-core-0/locations/europe-west1/caPools/dev-ngfw-ca-pool-3"
    }
  }
  "prod" = {
    "prod-ca-0" = {
      "ca_ids" = {
        "prod-root-ngfw-ca-0" = "projects/prod-sec-core-0/locations/europe-west1/caPools/prod-ngfw-ca-pool-3/certificateAuthorities/prod-root-ngfw-ca-0"
      }
      "ca_pool_id" = "projects/prod-sec-core-0/locations/europe-west1/caPools/prod-ngfw-ca-pool-3"
    }
  }
}
folder_ids = {
  networking      = "folders/12345678900"
  networking-dev  = "folders/12345678901"
  networking-prod = "folders/12345678902"
}
host_project_ids = {
  dev-spoke-0  = "dev-project"
  prod-spoke-0 = "prod-project"
}
ngfw_enterprise_config = {
  endpoint_zones = [
    "europe-west1-b",
    "europe-west1-c",
    "europe-west1-d"
  ]
  tls_inspection = {
    enabled = true
  }
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
trust_config_ids = {
  "dev" = {
    "dev-trust-0" = "projects/dev-sec-core-0/locations/europe-west1/trustConfigs/dev-trust-0"
  }
  "prod" = {
    "prod-trust-0" = "projects/prod-sec-core-0/locations/europe-west1/trustConfigs/prod-trust-0"
  }
}
vpc_self_links = {
  dev-spoke-0  = "https://www.googleapis.com/compute/v1/projects/123456789/networks/vpc-1"
  prod-spoke-0 = "https://www.googleapis.com/compute/v1/projects/123456789/networks/vpc-2"
}
