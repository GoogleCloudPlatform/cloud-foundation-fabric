host_project_ids = {
  "dev-spoke-0" = "f00-dev-net-spoke-0"
}
regions = {
  primary = "europe-west1"
}
subnet_self_links = {
  dev-spoke-0 : {
    "europe-west1/default" = "projects/f00-dev-net-spoke-0/regions/europe-west1/subnetworks/default"
  }
}
vpc_self_links = {
  dev-spoke-0 = "https://www.googleapis.com/compute/v1/projects/123456789/networks/dev-spoke-0"
}
