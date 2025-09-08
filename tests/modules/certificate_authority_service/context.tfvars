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
  kms_keys = {
    prod-default = "projects/test-0/locations/europe-west8/keyRings/prod-ew8/cryptoKeys/prod-default"
  }
  locations = {
    ew8 = "europe-west8"
  }
  storage_buckets = {
    test = "test-prod-cas"
  }
}
project_id = "test-0"
location   = "$locations:ew8"
ca_pool_config = {
  create_pool = {
    name = "test-ca"
  }
}
ca_configs = {
  root_ca_1 = {
    gcs_bucket = "$storage_buckets:test"
    key_spec = {
      kms_key_id = "$kms_keys:prod-default"
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
