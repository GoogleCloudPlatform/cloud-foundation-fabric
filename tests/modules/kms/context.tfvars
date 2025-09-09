context = {
  condition_vars = {
    organization = {
      id = 1234567890
    }
  }
  custom_roles = {
    myrole_one   = "organizations/366118655033/roles/myRoleOne"
    myrole_two   = "organizations/366118655033/roles/myRoleTwo"
    myrole_three = "organizations/366118655033/roles/myRoleThree"
    myrole_four  = "organizations/366118655033/roles/myRoleFour"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
    myuser2 = "user:test-user2@example.com"
  }
  locations = {
    ew8 = "europe-west8"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
}
project_id = "myproject"
keyring = {
  location = "$locations:ew8"
  name     = "test"
}
keys = {
  key-a = {
    iam = {
      "$custom_roles:myrole_one" = [
        "$iam_principals:myuser"
      ]
      "roles/viewer" = [
        "$iam_principals:mysa"
      ]
    }
    iam_by_principals = {
      "$iam_principals:myuser2" = [
        "$custom_roles:myrole_three",
        "$custom_roles:myrole_four",
        "roles/owner",
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
  }
  key-b = {
    rotation_period = "604800s"
    iam_bindings_additive = {
      myrole_three = {
        role   = "$custom_roles:myrole_three"
        member = "$iam_principals:mysa"
      }
    }
  }
  key-c = {
    labels = {
      env = "test"
    }
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
    condition = {
      title      = "Test"
      expression = "resource.matchTag('$${organization.id}/environment', 'development')"
    }
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
tag_bindings = {
  foo = "$tag_values:test/one"
}
