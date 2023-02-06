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
