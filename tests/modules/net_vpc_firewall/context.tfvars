context = {
  cidr_ranges = {
    rfc1918-10 = "10.0.0.0/8"
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
  allow-egress-rfc1918 = {
    deny        = false
    description = "Allow egress."
    destination_ranges = [
      "$cidr_ranges:rfc1918-10", "172.16.0.0/12", "192.168.0.0/16"
    ]
    source_ranges        = ["$cidr_ranges:rfc1918-10"]
    targets              = ["$iam_principals:test"]
    use_service_accounts = true
  }
}
ingress_rules = {
  allow-ingress-tag = {
    description          = "Allow ingress."
    destination_ranges   = ["$cidr_ranges:rfc1918-10"]
    source_ranges        = ["$cidr_ranges:rfc1918-10"]
    sources              = ["$iam_principals:test"]
    targets              = ["$iam_principals:test"]
    use_service_accounts = true
  }
}
