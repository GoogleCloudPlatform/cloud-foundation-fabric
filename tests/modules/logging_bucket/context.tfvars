context = {
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
    mykey = "projects/366118655033/locations/europe-west8/keyRings/mykeyring/cryptoKeys/mykey"
  }
  locations = {
    ew8 = "europe-west8"
  }
  project_ids = {
    myproject = "foo-logging-0"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
}
kms_key_name = "$kms_keys:mykey"
name         = "mybucket"
location     = "$locations:ew8"
parent       = "$project_ids:myproject"
tag_bindings = {
  foo = "$tag_values:test/one"
}
views = {
  myview = {
    filter = "LOG_ID(\"stdout\")"
    iam = {
      "$custom_roles:myrole_one" = [
        "$iam_principals:myuser"
      ]
      "roles/viewer" = [
        "$iam_principals:mysa"
      ]
    }
  }
}
