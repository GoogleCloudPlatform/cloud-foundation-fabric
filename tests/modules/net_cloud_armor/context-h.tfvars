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
    excluded     = "folders/2222222222"
    organization = "organizations/1122334455"
    test         = "folders/1234567890"
  }
  project_numbers = {
    excluded = "3333333333"
  }
}
name                = "test-h"
parent_id           = { organization_id = "$folder_ids:organization" }
default_rule_config = null
attachments = {
  organization = {
    id                = "$folder_ids:organization"
    excluded_folders  = ["$folder_ids:excluded", "folders/4444444444"]
    excluded_projects = ["$project_numbers:excluded", "projects/5555555555"]
  }
  test = {
    id                = "$folder_ids:test"
    excluded_projects = ["$project_numbers:excluded"]
  }
}
rules = {
  deny-internal = {
    priority = 100
    action   = "deny(403)"
    match = {
      src_ip_ranges = ["$cidr_ranges_sets:rfc1918", "$cidr_ranges:test", "10.0.0.0/8"]
    }
  }
}
