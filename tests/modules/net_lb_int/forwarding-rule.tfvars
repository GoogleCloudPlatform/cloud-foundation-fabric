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
global_access = true

forwarding_rules_config = {
  "port-80" = {
    ports = [80]
  }
}

