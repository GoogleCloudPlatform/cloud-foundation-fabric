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
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
service_accounts = {
  data-platform-dev    = "string"
  data-platform-prod   = "string"
  gke-dev              = "string"
  gke-prod             = "string"
  project-factory      = "string"
  project-factory-dev  = "string"
  project-factory-prod = "string"
}
spoke_configs = {
  vpn_configs = {}
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
