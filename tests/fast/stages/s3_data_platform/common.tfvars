automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "012345-67890A-BCDEF0",
}
folder_ids = {
  data-platform-dev = "folders/12345678"
}
host_project_ids = {
  dev-spoke-0 = "fast-dev-net-spoke-0"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
subnet_self_links = {
  dev-spoke-0 = {
    "europe-west1/dev-dataplatform-ew1" : "https://www.googleapis.com/compute/v1/projects/fast-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-dataplatform-ew1",
    "europe-west1/dev-default-ew1" : "https://www.googleapis.com/compute/v1/projects/fast-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-default-ew1"
  }
}
vpc_self_links = { dev-spoke-0 = "https://www.googleapis.com/compute/v1/projects/fast-dev-net-spoke-0/global/networks/dev-spoke-0" }
