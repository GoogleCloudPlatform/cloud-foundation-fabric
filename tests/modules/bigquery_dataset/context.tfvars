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
    test = "foo-test-0"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
}
project_id     = "$project_ids:test"
id             = "dataset_0"
location       = "$locations:ew8"
encryption_key = "$kms_keys:mykey"
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:myuser"
  ]
  "roles/viewer" = [
    "$iam_principals:mysa"
  ]
}
tag_bindings = {
  foo = "$tag_values:test/one"
}
