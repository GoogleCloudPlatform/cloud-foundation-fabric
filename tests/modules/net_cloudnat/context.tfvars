context = {
  addresses = {
    test = "35.10.10.10"
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
    test = "projects/foo-dev-net-spoke-0/regions/europe-west1/subnetworks/gce"
  }
}
addresses = ["$addresses:test"]
config_source_subnetworks = {
  all = false
  subnetworks = [{
    self_link = "$subnets:test"
  }]
}
name           = "test"
project_id     = "$project_ids:test"
region         = "$locations:ew8"
router_network = "$networks:test"
