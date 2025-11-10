parent = "$folder_ids:default"
name   = "Test Context"
context = {
  condition_vars = {
    organization = {
      id = 1234567890
    }
  }
  custom_roles = {
    myrole_one = "organizations/366118655033/roles/myRoleOne"
    myrole_two = "organizations/366118655033/roles/myRoleTwo"
  }
  email_addresses = {
    default = "foo@example.com"
  }
  folder_ids = {
    default = "organizations/1234567890"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
}
contacts = {
  "$email_addresses:default" = ["ALL"]
}
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:myuser"
  ]
  "roles/viewer" = [
    "$iam_principals:mysa"
  ]
}
iam_by_principals = {
  "$iam_principals:mygroup" = [
    "roles/owner",
    "$custom_roles:myrole_one"
  ]
}
iam_bindings = {
  myrole_two = {
    role = "$custom_roles:myrole_two"
    members = [
      "$iam_principals:mysa"
    ]
    condition = {
      title      = "Test"
      expression = "resource.matchTag('$${organization.id}/environment', 'development')"
    }
  }
}
iam_bindings_additive = {
  myrole_two = {
    role   = "$custom_roles:myrole_two"
    member = "$iam_principals:myuser"
  }
}
logging_data_access = {
  allServices = {
    ADMIN_READ = {
      exempted_members = ["$iam_principals:mygroup"]
    }
    DATA_READ = {}
  }
}
pam_entitlements = {
  net-admins = {
    max_request_duration = "3600s"
    manual_approvals = {
      require_approver_justification = true
      steps = [{
        approvers = ["$iam_principals:mygroup"]
      }]
    }
    eligible_users = ["$iam_principals:mygroup"]
    privileged_access = [
      { role = "roles/compute.networkAdmin" },
      { role = "roles/compute.admin" },
      { role = "$custom_roles:myrole_two" }
    ]
  }
}
tag_bindings = {
  foo = "$tag_values:test/one"
}
