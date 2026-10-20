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
  folder_ids = {
    test = "folders/1234567890"
  }
}
name      = "test-h"
parent_id = "$folder_ids:test"
rules = {
  deny-internal = {
    priority = 100
    action   = "deny(403)"
    match = {
      src_ip_ranges = ["$cidr_ranges_sets:rfc1918", "$cidr_ranges:test", "10.0.0.0/8"]
    }
  }
}
