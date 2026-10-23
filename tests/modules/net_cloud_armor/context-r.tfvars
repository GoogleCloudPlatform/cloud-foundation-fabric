context = {
  cidr_ranges = {
    test = "8.8.8.8/32"
  }
  cidr_ranges_sets = {
    rfc1918 = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }
  locations = {
    ew8 = "europe-west8"
  }
  project_ids = {
    test = "foo-test-0"
  }
}
name       = "test-r"
project_id = "$project_ids:test"
region     = "$locations:ew8"
type       = "CLOUD_ARMOR_NETWORK"
rules = {
  allow-internal = {
    priority = 100
    action   = "allow"
    network_match = {
      dest_ip_ranges = ["$cidr_ranges:test"]
      src_ip_ranges  = ["$cidr_ranges_sets:rfc1918", "10.0.0.0/8"]
    }
  }
}
