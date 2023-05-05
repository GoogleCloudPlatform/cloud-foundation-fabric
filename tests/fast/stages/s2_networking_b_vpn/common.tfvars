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
