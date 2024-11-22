billing_account = {
  id = "000000-111111-222222"
}

environments = {
  dev = {
    name = "Development"
  }
}

folder_ids = {
  gcve-dev = "folders/00000000000000"
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
  "dev-spoke-0" = "projects/em-prod-net-spoke-0/global/networks/prod-spoke-0",
}


