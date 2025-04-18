automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  project_iam_viewer = "organizations/123456789012/roles/bar"
}
environments = {
  "dev" : {
    "is_default" : true,
    "key" : "dev",
    "name" : "Development",
    "short_name" : "dev",
    "tag_name" : "development"
  }
}
essential_contacts = "gcp-secops-admins@fast.example.com"
folder_ids = {
  secops = "folders/12345678"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
tag_values = {
  "environment/development" = "tagValues/12345"
  "environment/production"  = "tagValues/12346"
}
