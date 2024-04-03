automation = {
  federated_identity_pool      = null
  federated_identity_providers = null
  project_id                   = "fast-prod-automation"
  project_number               = 123456
  outputs_bucket               = "test"
  service_accounts = {
    resman-r = "em-dev-gcve-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com"
  }
}

billing_account = {
  id = "000000-111111-222222"
}

folder_ids = {
  gcve-prod = "folders/00000000000000"
}

groups_gcve = {
  gcp-gcve-admins  = "gcp-gcve-admins",
  gcp-gcve-viewers = "gcp-gcve-viewers"
}

host_project_ids = {
  prod-spoke-0 = "prod-spoke-0"
}

organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}

prefix = "fast3"

private_cloud_configs = {
  dev-pc = {
    cidr = "172.26.16.0/22"
    zone = "europe-west8-a"
    management_cluster_config = {
      name         = "mgmt-cluster"
      node_count   = 1
      node_type_id = "standard-72"
    }
  }
}

vpc_self_links = {
  "prod-spoke-0" = "https://www.googleapis.com/compute/v1/projects/em-prod-net-spoke-0/global/networks/prod-spoke-0",
}


