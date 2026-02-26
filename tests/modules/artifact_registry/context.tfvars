context = {
  iam_principals = {
    user   = "user:foo@example.org"
    viewer = "user:bar@example.org"
  }
  kms_keys = {
    key = "projects/my-project/locations/europe-west1/keyRings/my-keyring/cryptoKeys/my-key"
  }
  locations = {
    r1 = "europe-west1"
  }
  project_ids = {
    p1 = "my-project"
  }
  tag_values = {
    tv1 = "tagValues/1234567890"
  }
}
encryption_key = "$kms_keys:key"
format         = { docker = { standard = {} } }
iam            = { "roles/viewer" = ["$iam_principals:viewer"] }
location       = "$locations:r1"
name           = "registry-default"
project_id     = "$project_ids:p1"
tag_bindings = {
  "$tag_values:tv1" = "$tag_values:tv1"
}
