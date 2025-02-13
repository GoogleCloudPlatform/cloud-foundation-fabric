project_id = "my-project"
region     = "europe-west1"
name       = "nlb-test"
backends = [{
  group    = "foo"
  failover = false
}]
forwarding_rules_config = {
  "port-80" = {
    ports = [80]
  }
}

