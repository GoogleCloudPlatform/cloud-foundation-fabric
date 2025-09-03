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
  folder_ids = {
    "test/prod" = "folders/6789012345"
  }
  kms_keys = {
    compute-prod-ew1 = "projects/kms-central-prj/locations/europe-west1/keyRings/my-keyring/cryptoKeys/ew1-compute"
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
  vpc_sc_perimeters = {
    default = "accessPolicies/888933661165/servicePerimeters/default"
  }
}
parent = "$folder_ids:test/prod"
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:myuser"
  ]
  "roles/viewer" = [
    "$iam_principals:mysa",
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
  sa_test = {
    role   = "roles/browser"
    member = "$service_agents:compute"
  }
}
services = [
  "compute.googleapis.com"
]
service_encryption_key_ids = {
  "compute.googleapis.com" = [
    "$kms_keys:compute-prod-ew1"
  ]
}
shared_vpc_service_config = {
  host_project = "$project_ids:vpc-host"
  iam_bindings_additive = {
    myrole_two = {
      role   = "$custom_roles:myrole_two"
      member = "$iam_principals:myuser"
    }
  }
  network_users = ["$iam_principals:mysa"]
  service_agent_iam = {
    "roles/compute.networkUser" = [
      "$service_agents:cloudservices", "$service_agents:compute"
    ]
  }
  service_iam_grants = ["$service_agents:compute"]
}
tag_bindings = {
  foo = "$tag_values:test/one"
}
tags = {
  test = {
    id = "$tag_keys:test"
    iam = {
      "roles/tagAdmin" = ["$iam_principals:mygroup"]
    }
    iam_bindings = {
      tag_user = {
        role    = "roles/tagUser"
        members = ["$iam_principals:myuser"]
      }
    }
    iam_bindings_additive = {
      tag_viewer = {
        role   = "roles/tagViewer"
        member = "$iam_principals:mysa"
      }
    }
    values = {
      one = {
        id = "$tag_values:test/one"
        iam = {
          "roles/tagAdmin" = ["$iam_principals:mygroup"]
        }
        iam_bindings = {
          tag_user = {
            role    = "roles/tagUser"
            members = ["$iam_principals:myuser"]
          }
        }
        iam_bindings_additive = {
          tag_viewer = {
            role   = "roles/tagViewer"
            member = "$iam_principals:mysa"
          }
        }
      }
    }
  }
}
vpc_sc = {
  perimeter_name = "$vpc_sc_perimeters:default"
}
