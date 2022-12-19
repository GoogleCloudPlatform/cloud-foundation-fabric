automation = {
  federated_identity_pool      = null
  federated_identity_providers = null
  project_id                   = "fast-prod-automation"
  project_number               = 123456
  outputs_bucket               = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  # organization_iam_admin = "organizations/123456789012/roles/organizationIamAdmin",
  service_project_network_admin = "organizations/123456789012/roles/xpnServiceAdmin"
}
groups = {
  gcp-billing-admins      = "gcp-billing-admins",
  gcp-devops              = "gcp-devops",
  gcp-network-admins      = "gcp-network-admins",
  gcp-organization-admins = "gcp-organization-admins",
  gcp-security-admins     = "gcp-security-admins",
  gcp-support             = "gcp-support"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
tag_keys = {
  context     = "tagKeys/1234567890",
  environment = "tagKeys/4567890123",
  tenant      = "tagKeys/7890123456"
}
tenant_configs = {
  tn01 = {
    groups = {
      gcp-admins = "gcp-tn01-admins"
    }
    descriptive_name = "Tenant 01"
    locations = {
      gcs     = "europe-west8"
      logging = "europe-west8"
    }
  }
  tn02 = {
    groups = {
      gcp-admins = "gcp-tn02-admins"
    }
    descriptive_name = "Tenant 02"
  }
}
