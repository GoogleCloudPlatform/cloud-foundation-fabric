_fast_debug = {
  skip_datasources = true
}
automation = {
  outputs_bucket = "test"
}
certificate_authority = {
  ca_configs = {
    swp = {
      deletion_protection = false
      subject = {
        common_name  = "fast-test-00.joonix.net"
        organization = "FAST Test 00"
      }
    }
  }
}
host_project_ids = {
  "prod-landing" = "f00-prod-net-landing-0"
}
locations = {
  pri = "primary"
}
project_id = "prod-landing"
swp_configs = {
  shared = {
    network_id    = "prod-landing"
    subnetwork_id = "net"
  }
}
tls_inspection_policy = {
  exclude_public_ca_set = true
}
subnet_self_links = {
  prod-landing : {
    "europe-west8/net" = "projects/f00-prod-net-landing-0/regions/europe-west8/subnetworks/net"
  }
}
vpc_self_links = {
  prod-landing = "https://www.googleapis.com/compute/v1/projects/123456789/networks/prod-landing-0"
}
