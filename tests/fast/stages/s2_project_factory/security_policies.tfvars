automation = {
  outputs_bucket = "fast2-prod-iac-core-outputs"
}
prefix = "test"
billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  dataset = "data-secpol"
}
folder_ids = {
  teams = "folders/1234567890"
}
networking_security_policies = {
  org-baseline = "locations/global/securityPolicies/1111111111"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
security_security_policies = {
  teams-waf = "locations/global/securityPolicies/2222222222"
}
