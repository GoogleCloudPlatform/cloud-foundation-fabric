context = {
  custom_roles = {
    myrole_one = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
  }
  locations = {
    ew8 = "europe-west8"
  }
  project_ids = {
    myproject = "foo-logging-0"
  }
}
project_id = "$project_ids:myproject"
regions    = ["$locations:ew8"]
name       = "my-topic"
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:mygroup"
  ]
}
