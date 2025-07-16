factories_config = {
  context = {
    custom_roles = {
      myrole_one = "organizations/366118655033/roles/myRoleOne"
      myrole_two = "organizations/366118655033/roles/myRoleTwo"
    }
    folder_ids = {
      test        = "folders/1234567890"
      "test/prod" = "folders/6789012345"
    }
    iam_principals = {
      mygroup = "group:test-group@example.com"
      mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
      myuser  = "user:test-user@example.com"
    }
    project_ids = {
      vpc-host = "test-vpc-host"
    }
    tag_keys = {
      test = "tagKeys/1234567890"
    }
    tag_values = {
      "test/one" = "tagValues/1234567890"
    }
  }
}
parent = "$test.prod"
iam = {
  "$myrole_one" = [
    "$myuser"
  ]
  "roles/viewer" = [
    "$mysa"
  ]
}
iam_by_principals = {
  "$mygroup" = [
    "roles/owner",
    "$myrole_one"
  ]
}
iam_bindings = {
  myrole_two = {
    role = "$myrole_two"
    members = [
      "$mysa"
    ]
  }
}
iam_bindings_additive = {
  myrole_two = {
    role   = "$myrole_two"
    member = "$myuser"
  }
}
services = [
  "compute.googleapis.com"
]
shared_vpc_service_config = {
  host_project = "$vpc-host"
  iam_bindings_additive = {
    myrole_two = {
      role   = "$myrole_two"
      member = "$myuser"
    }
  }
  network_users = ["$mysa"]
  service_agent_iam = {
    "roles/compute.networkUser" = [
      "$cloudservices", "$compute"
    ]
  }
  service_iam_grants = ["$compute"]
}
tags = {
  test = {
    description = "Test tag."
    id          = "$test"
    iam = {
      "roles/tagAdmin" = ["$mygroup"]
    }
    iam_bindings = {
      tag_user = {
        role    = "roles/tagUser"
        members = ["$myuser"]
      }
    }
    iam_bindings_additive = {
      tag_viewer = {
        role   = "roles/tagViewer"
        member = "$mysa"
      }
    }
    values = {
      one = {
        description = "Test value one."
        id          = "$test.one"
        iam = {
          "roles/tagAdmin" = ["$mygroup"]
        }
        iam_bindings = {
          tag_user = {
            role    = "roles/tagUser"
            members = ["$myuser"]
          }
        }
        iam_bindings_additive = {
          tag_viewer = {
            role   = "roles/tagViewer"
            member = "$mysa"
          }
        }
      }
    }
  }
}
