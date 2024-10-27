billing_account = {
  id = "000000-111111-222222"
}
folder_ids = {
  networking      = "folders/12345678900"
  networking-dev  = "folders/12345678901"
  networking-prod = "folders/12345678902"
}
host_project_ids = {
  dev-spoke-0  = "dev-project"
  prod-spoke-0 = "prod-project"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
vpc_self_links = {
  dev-spoke-0  = "https://www.googleapis.com/compute/v1/projects/123456789/networks/vpc-1"
  prod-spoke-0 = "https://www.googleapis.com/compute/v1/projects/123456789/networks/vpc-2"
}
