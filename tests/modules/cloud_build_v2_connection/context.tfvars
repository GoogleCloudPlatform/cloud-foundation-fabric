context = {
  condition_vars = {
    conn = {
      name = "my-connection"
    }
  }
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    mygroup = "group:group1@example.com"
    myuser  = "user:user1@example.com"
  }
  locations = {
    primary = "europe-west8"
  }
  project_ids = {
    main = "test-cb-prj"
  }
}

project_id = "$project_ids:main"
location   = "$locations:primary"
name       = "my-connection"

connection_config = {
  github = {
    app_installation_id                  = 123456
    authorizer_credential_secret_version = "projects/prj/secrets/pat/versions/1"
  }
}

repositories = {
  my-repo = {
    remote_uri = "https://github.com/my-org/my-repo.git"
    triggers = {
      main-push = {
        filename = "cloudbuild.yaml"
        push = {
          branch = "^main$"
        }
      }
    }
  }
}

iam = {
  "$custom_roles:myrole" = ["$iam_principals:myuser"]
}

iam_by_principals = {
  "$iam_principals:mygroup" = ["roles/cloudbuild.connectionViewer"]
}

iam_bindings = {
  connection-admin = {
    role    = "roles/cloudbuild.connectionAdmin"
    members = ["$iam_principals:mygroup"]
    condition = {
      title      = "connection-name"
      expression = "resource.name.endsWith('/$${conn.name}')"
    }
  }
}

iam_bindings_additive = {
  connection-custom = {
    role   = "$custom_roles:myrole"
    member = "$iam_principals:myuser"
    condition = {
      title      = "connection-custom-name"
      expression = "resource.name.endsWith('/$${conn.name}')"
    }
  }
}
