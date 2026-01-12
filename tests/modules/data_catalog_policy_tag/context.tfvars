context = {
  condition_vars = {
    organization = {
      id = 1234567890
    }
  }
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
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
}
project_id = "$project_ids:test"
location   = "$locations:ew8"
name       = "test"
tags = {
  low    = {}
  medium = {}
  high = {
    iam = {
      "roles/datacatalog.categoryFineGrainedReader" = [
        "$iam_principals:mysa"
      ]
    }
  }
}
iam = {
  "roles/datacatalog.categoryAdmin" = [
    "$iam_principals:mygroup"
  ]
}
iam_bindings_additive = {
  am1-admin = {
    member = "$iam_principals:myuser"
    role   = "$custom_roles:myrole"
    condition = {
      title      = "Test"
      expression = "resource.matchTag('$${organization.id}/environment', 'development')"
    }
  }
}
