automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  certificate_authorities = "data-simple/certificate-authorities"
  defaults                = "data-simple/defaults.yaml"
}
folder_ids = {
  security = "folders/12345678"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
service_accounts = {
  "iac-0/iac-pf-rw"     = "iac-pf-rw@test.iam.gserviceaccount.com"
  "iac-0/iac-pf-ro"     = "iac-pf-ro@test.iam.gserviceaccount.com"
  "iac-0/iac-dp-dev-rw" = "iac-dp-dev-rw@test.iam.gserviceaccount.com"
}
storage_buckets = {
  "iac-0/iac-outputs" = "test"
}
tag_values = {
  "environment/development" = "tagValues/12345"
  "environment/production"  = "tagValues/12346"
}
