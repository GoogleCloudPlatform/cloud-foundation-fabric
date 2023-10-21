project_id = "my-project"
region     = "europe-west1"
name       = "nlb-test"
backends = [{
  group    = "foo"
  failover = false
}]
forwarding_rules_config = {
  ipv4 = {
    ip_version = "IPV4"
  }
  ipv6 = {
    ip_version = "IPV6"
  }
}
