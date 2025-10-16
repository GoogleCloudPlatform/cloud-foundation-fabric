context = {
  cidr_ranges = {
    rfc1918-10 = "10.0.0.0/8"
    test       = "8.8.8.8"
  }
  cidr_ranges_sets = {
    rfc1918 = [
      "10.0.0.0/8",
      "172.16.10.0/12",
      "192.168.0.0/24"
    ]
  }
  iam_principals = {
    test = "serviceAccount:test@test-project.iam.gserviceaccount.com"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
}
project_id = "$project_ids:test"
network    = "$networks:test"
attachments = {
  test = "$networks:test"
}
default_rules_config = {
  admin_ranges = ["$cidr_ranges:rfc1918-10"]
  http_ranges  = ["$cidr_ranges:rfc1918-10"]
  https_ranges = ["$cidr_ranges:rfc1918-10"]
  ssh_ranges   = ["$cidr_ranges:rfc1918-10"]
}
egress_rules = {
  egress-test = {
    deny                 = false
    description          = "Allow egress."
    destination_ranges   = ["$cidr_ranges_sets:rfc1918", "10.0.0.1/32", "$cidr_ranges:test", "10.0.0.0/8"]
    source_ranges        = ["$cidr_ranges_sets:rfc1918", "10.0.0.1/32", "$cidr_ranges:test", "10.0.0.0/8"]
    targets              = ["$iam_principals:test"]
    use_service_accounts = true
  }
}
ingress_rules = {
  ingress-test = {
    description          = "Allow ingress."
    destination_ranges   = ["$cidr_ranges_sets:rfc1918", "10.0.0.1/32", "$cidr_ranges:test", "10.0.0.0/8"]
    source_ranges        = ["$cidr_ranges_sets:rfc1918", "10.0.0.1/32", "$cidr_ranges:test", "10.0.0.0/8"]
    sources              = ["$iam_principals:test"]
    targets              = ["$iam_principals:test"]
    use_service_accounts = true
  }
}
