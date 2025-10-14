context = {
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
}
project_id = "$project_ids:test"
name       = "test-example"
zone_config = {
  domain = "test.example."
  private = {
    client_networks = ["$networks:test"]
  }
}
recordsets = {
  "A localhost" = { records = ["127.0.0.1"] }
  "A myhost"    = { ttl = 600, records = ["10.0.0.120"] }
}
iam = {
  "$custom_roles:myrole" = ["$iam_principals:mygroup"]
}

