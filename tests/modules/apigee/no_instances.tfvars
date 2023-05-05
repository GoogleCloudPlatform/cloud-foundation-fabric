project_id = "my-project"
organization = {
  display_name            = "My Organization"
  description             = "My Organization"
  authorized_network      = "my-vpc"
  runtime_type            = "CLOUD"
  billing_type            = "PAYG"
  database_encryption_key = "123456789"
  analytics_region        = "europe-west1"
}
envgroups = {
  test = ["test.example.com"]
  prod = ["prod.example.com"]
}
environments = {
  apis-test = {
    display_name = "APIs test"
    description  = "APIs Test"
    envgroups    = ["test"]
  }
  apis-prod = {
    display_name = "APIs prod"
    description  = "APIs prod"
    envgroups    = ["prod"]
  }
}
