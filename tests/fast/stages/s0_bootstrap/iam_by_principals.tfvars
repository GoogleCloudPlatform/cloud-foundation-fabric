organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
billing_account = {
  id = "000000-111111-222222"
}
essential_contacts = "gcp-organization-admins@fast.example.com"
iam_by_principals = {
  "user:other@fast.example.com" = ["roles/browser"]
}
prefix = "fast"
org_policies_config = {
  import_defaults = false
}
outputs_location = "/fast-config"
groups = {
  gcp-support = "group:gcp-support@example.com"
}
