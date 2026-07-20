context = {
  addresses = {
    test = "10.0.0.10"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
  subnets = {
    test     = "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
    test-nat = "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/test-nat"
  }
}
project_id = "$project_ids:test"
region     = "$locations:ew8"
vpc_config = {
  network    = "$networks:test"
  subnetwork = "$subnets:test"
}
address = "$addresses:test"
backend_service_configs = {
  default = {
    backends = [{
      group = "projects/foo-test-0/zones/europe-west8-a/instanceGroups/my-ig"
    }]
  }
}
service_attachment = {
  nat_subnets = ["$subnets:test-nat"]
}
