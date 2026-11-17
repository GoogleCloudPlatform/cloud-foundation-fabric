context = {
  condition_vars = {
    spanner = {
      db_role = "my_role"
    }
  }
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    mygroup = "group:group1@example.com"
    myuser  = "user:user1@example.com"
  }
  kms_keys = {
    spanner = "projects/kms-prj/locations/us-central1/keyRings/kr/cryptoKeys/key"
  }
  locations = {
    primary   = "us-central1"
    secondary = "us-east1"
  }
  project_ids = {
    main = "test-spanner-prj"
  }
}

project_id = "$project_ids:main"

instance = {
  name         = "my-instance"
  display_name = "Custom config instance"
  config = {
    name = "custom-regional-config"
    auto_create = {
      base_config = "nam3"
      replicas = [
        {
          location                = "$locations:primary"
          type                    = "READ_WRITE"
          default_leader_location = true
        },
        {
          location                = "$locations:secondary"
          type                    = "READ_ONLY"
          default_leader_location = false
        }
      ]
    }
  }
  num_nodes = 1
}

iam = {
  "$custom_roles:myrole" = ["$iam_principals:myuser"]
}

iam_by_principals = {
  "$iam_principals:mygroup" = ["roles/spanner.viewer"]
}

iam_bindings = {
  instance-reader = {
    role    = "roles/spanner.databaseReader"
    members = ["$iam_principals:mygroup"]
    condition = {
      title      = "instance-role"
      expression = "resource.name.endsWith('/$${spanner.db_role}')"
    }
  }
}

iam_bindings_additive = {
  instance-admin = {
    role   = "$custom_roles:myrole"
    member = "$iam_principals:myuser"
    condition = {
      title      = "instance-admin-role"
      expression = "resource.name.endsWith('/$${spanner.db_role}')"
    }
  }
}

databases = {
  my-db = {
    kms_key_name = "$kms_keys:spanner"
    iam = {
      "roles/spanner.databaseUser" = ["$iam_principals:myuser"]
    }
    iam_by_principals = {
      "$iam_principals:mygroup" = ["$custom_roles:myrole"]
    }
    iam_bindings = {
      db-reader = {
        role    = "roles/spanner.fineGrainedAccessUser"
        members = ["$iam_principals:mygroup"]
        condition = {
          title      = "db-role"
          expression = "resource.name.endsWith('/$${spanner.db_role}')"
        }
      }
    }
    iam_bindings_additive = {
      db-admin = {
        role   = "roles/spanner.databaseAdmin"
        member = "$iam_principals:myuser"
        condition = {
          title      = "db-admin-role"
          expression = "resource.name.endsWith('/$${spanner.db_role}')"
        }
      }
    }
  }
}
