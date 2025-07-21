billing_account = {
  id = "000000-111111-222222"
  is_org_level = false
  force_create = {
     dataset    = true
      project    = true
      log_bucket = true
  }
}
essential_contacts = "gcp-organization-admins@fast.example.com"
groups = {
  gcp-support = "group:gcp-support@example.com"
}
org_policies_config = {
  import_defaults = false
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
outputs_location = "/fast-config"
prefix           = "fast"
