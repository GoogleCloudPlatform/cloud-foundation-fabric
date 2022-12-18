data_dir = "../../../../../fast/stages/02-networking-vpn/data/"
automation = {
  outputs_bucket = "test"
}
billing_account = {
  id              = "000000-111111-222222"
  organization_id = 123456789012
}
custom_roles = {
  service_project_network_admin = "organizations/123456789012/roles/foo"
}
folder_ids = {
  networking      = null
  networking-dev  = null
  networking-prod = null
}
region_trigram = {
  europe-west1 = "ew1"
  europe-west3 = "ew3"
  europe-west8 = "ew8"
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
