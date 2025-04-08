project_id = "my-project"
organization = {
  display_name            = "My Organization"
  description             = "My Organization"
  runtime_type            = "CLOUD"
  billing_type            = "Pay-as-you-go"
  database_encryption_key = "123456789"
  analytics_region        = "europe-west1"
  disable_vpc_peering     = true
}
environments = {
  apis-test = {
    display_name = "APIs test"
    description  = "APIs Test"
    envgroups    = ["test"]
  }
}
instances = {
  europe-west1 = {
    environments = ["europe-west1"]
    enable_nat   = true
    activate_nat = true
  }
}