project_id = "my-project"
region     = "europe-west1"
name       = "ilb-test"
vpc_config = {
  network    = "default"
  subnetwork = "default"
}
backends = [{
  group    = "foo"
  failover = false
}]
