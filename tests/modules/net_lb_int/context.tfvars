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
  project_ids = {
    test = "foo-test-0"
  }
}
project_id = "$project_ids:test"
region     = "$locations:ew8"
name       = "test"
vpc_config = {
  network    = "$networks:test"
  subnetwork = "$subnets:test"
}
backends = [{
  group    = "foo"
  failover = false
}]
forwarding_rules_config = {
  "" = {
    address = "$addresses:test"
  }
}
service_attachments = {
  "" = {
    nat_subnets = ["$subnets:test-nat"]
  }
}
