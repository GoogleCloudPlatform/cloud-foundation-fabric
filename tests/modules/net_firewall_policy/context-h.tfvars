context = {
  cidr_ranges = {
    rfc1918-10 = "10.0.0.0/8"
  }
  folder_ids = {
    test = "folders/1234567890"
  }
  iam_principals = {
    test = "serviceAccount:test@test-project.iam.gserviceaccount.com"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
}
name      = "test-1"
parent_id = "$folder_ids:test"
attachments = {
  test = "$folder_ids:test"
}
egress_rules = {
  smtp = {
    priority = 900
    match = {
      destination_ranges = ["$cidr_ranges:rfc1918-10"]
      layer4_configs     = [{ protocol = "tcp", ports = ["25"] }]
    }
  }
}
ingress_rules = {
  icmp = {
    priority                = 1000
    enable_logging          = true
    target_resources        = ["$networks:test"]
    target_service_accounts = ["$iam_principals:test"]
    match = {
      source_ranges  = ["$cidr_ranges:rfc1918-10"]
      layer4_configs = [{ protocol = "icmp" }]
    }
  }
}
