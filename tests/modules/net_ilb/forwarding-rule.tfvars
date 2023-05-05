project_id = "my-project"
region     = "europe-west1"
name       = "ilb-test"
vpc_config = {
  network    = "default"
  subnetwork = "default"
}
backends = [{
  balancing_mode = "CONNECTION"
  group          = "foo"
  failover       = false
}]
global_access = true
ports         = [80]
