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
  project_ids = {
    test = "myproject"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
}
project_id = "$project_ids:test"
location   = "$locations:ew8"
aspect_types = {
  tf-test-template = {
    display_name = "Test template."
    iam = {
      "roles/dataplex.aspectTypeOwner" = ["$iam_principals:mygroup"]
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
      user = {
        role   = "roles/dataplex.aspectTypeUser"
        member = "$iam_principals:mysa"
      }
    }
    metadata_template = "{}"
  }
}
