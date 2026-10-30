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
  project_ids = {
    test = "foo-test-0"
  }
}
name      = "test-g"
parent_id = { project_id = "$project_ids:test" }
rules = {
  allow-internal = {
    priority = 100
    action   = "allow"
    match = {
      src_ip_ranges = ["$cidr_ranges_sets:rfc1918", "$cidr_ranges:test", "10.0.0.0/8"]
    }
  }
}
