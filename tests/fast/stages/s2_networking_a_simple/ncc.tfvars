automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  service_project_network_admin = "organizations/123456789012/roles/foo"
}
dns = {
  resolvers      = ["10.10.10.10"]
  enable_logging = true
}
enable_cloud_nat   = true
essential_contacts = "gcp-network-admins@fast.example.com"
folder_ids = {
  networking      = null
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
  ncc_configs = {}
}
