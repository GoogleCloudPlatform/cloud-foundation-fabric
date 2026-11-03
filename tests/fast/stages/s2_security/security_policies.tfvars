automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  paths = {
    defaults          = "./data-secpol/defaults.yaml"
    security_policies = "./data-secpol/security-policies"
  }
}
folder_ids = {
  sandbox  = "folders/87654321"
  security = "folders/12345678"
  teams    = "folders/11111111"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
service_accounts = {
  "iac-0/iac-pf-rw" = "iac-pf-rw@test.iam.gserviceaccount.com"
}
storage_buckets = {
  "iac-0/iac-outputs" = "test"
}
