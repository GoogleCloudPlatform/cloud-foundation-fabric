project_id = "my-project"
region     = "europe-west1"
name       = "nlb-test"
backends = [{
  group    = "foo"
  failover = false
}]
forwarding_rules_config = {
  ipv4 = {
    ipv6 = false
  }
  ipv6 = {
    ipv6 = true
  }
}
