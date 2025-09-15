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
  kms_keys = {
    compute-prod-ew1 = "projects/kms-central-prj/locations/europe-west1/keyRings/my-keyring/cryptoKeys/ew1-compute"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
  }
  locations = {
    ew1 = "europe-west1"
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
project_id = "test-0"
secrets = {
  test-global = {
    kms_key = "$kms_keys:compute-prod-ew1"
    iam = {
      "$custom_roles:myrole_one" = [
        "$iam_principals:myuser"
      ]
      "roles/viewer" = [
        "$iam_principals:mysa",
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
    tag_bindings = {
      foo = "$tag_values:test/one"
    }
  }
  test-regional = {
    location = "$locations:ew1"
    kms_key  = "$kms_keys:compute-prod-ew1"
    iam = {
      "$custom_roles:myrole_one" = [
        "$iam_principals:myuser"
      ]
      "roles/viewer" = [
        "$iam_principals:mysa",
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
    tag_bindings = {
      foo = "$tag_values:test/one"
    }
  }
}
