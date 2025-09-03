prefix     = "prefix"
project_id = "my-project-id"
name       = "test-sa"
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
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
  }
  folder_ids = {
    test = "folders/1234567890"
  }
  project_ids = {
    test = "prj-test-0"
  }
  service_account_ids = {
    test = "projects/prj-test-0/serviceAccounts/test-0@prj-test-0.iam.gserviceaccount.com"
  }
  storage_buckets = {
    test = "gcs-test-0"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
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
iam_folder_roles = {
  "$folder_ids:test" = [
    "roles/resourcemanager.folderViewer"
  ]
}
iam_project_roles = {
  "$project_ids:test" = [
    "roles/viewer"
  ]
}
iam_sa_roles = {
  "$service_account_ids:test" = [
    "roles/iam.serviceAccountTokenCreator"
  ]
}
iam_storage_roles = {
  "$storage_buckets:test" = [
    "roles/storage.admin"
  ]
}
tag_bindings = {
  foo = "$tag_values:test/one"
}
