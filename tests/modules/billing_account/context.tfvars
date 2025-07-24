id = "012345-ABCDEF-012345"
budgets = {
  folder-net-month-current-100 = {
    display_name = "100 dollars in current spend"
    amount = {
      units = 100
    }
    filter = {
      period = {
        calendar = "MONTH"
      }
      projects           = ["$project_ids:foo"]
      resource_ancestors = ["$folder_ids:bar"]
    }
    threshold_rules = [
      { percent = 0.5 },
      { percent = 0.75 }
    ]
  }
}
context = {
  custom_roles = {
    myrole_one   = "organizations/366118655033/roles/myRoleOne"
    myrole_two   = "organizations/366118655033/roles/myRoleTwo"
    myrole_three = "organizations/366118655033/roles/myRoleThree"
    myrole_four  = "organizations/366118655033/roles/myRoleFour"
  }
  folder_ids = {
    bar = "folders/1234567890"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
    myuser2 = "user:test-user2@example.com"
  }
  project_ids = {
    foo = "test-prj-foo"
  }
}
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:myuser"
  ]
  "roles/viewer" = [
    "$iam_principals:mysa"
  ]
}
iam_bindings = {
  myrole_two = {
    role = "$custom_roles:myrole_two"
    members = [
      "$iam_principals:mysa"
    ]
  }
}
iam_bindings_additive = {
  myrole_three = {
    role   = "$custom_roles:myrole_three"
    member = "$iam_principals:mysa"
  }
}
iam_by_principals = {
  "$iam_principals:myuser2" = [
    "$custom_roles:myrole_three",
    "$custom_roles:myrole_four",
    "roles/owner",
  ]
}
projects = ["$project_ids:foo"]
