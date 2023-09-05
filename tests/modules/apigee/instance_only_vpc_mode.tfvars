project_id = "my-project"
organization = {
  display_name            = "My Organization"
  description             = "My Organization"
  authorized_network      = "my-vpc"
  runtime_type            = "CLOUD"
  billing_type            = "Pay-as-you-go"
  database_encryption_key = "123456789"
  analytics_region        = "europe-west1"
  disable_vpc_peering     = false
}
instances = {
  europe-west1 = {
    runtime_ip_cidr_range         = "10.0.4.0/22"
    troubleshooting_ip_cidr_range = "10.1.1.0/28"
  }
}

