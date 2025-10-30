name        = "test-cf-kms"
bucket_name = "bucket"
bundle_config = {
  path = "gs://assets/sample-function.zip"
}
context = {
  cidr_ranges = {
    test = "10.10.20.0/28"
  }
  custom_roles = {
    myrole_one = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
  }
  kms_keys = {
    test = "projects/foo-prod-sec-core/locations/global/keyRings/prod-global-default/cryptoKeys/compute"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
  subnets = {
    test = "projects/foo-dev-net-spoke-0/regions/europe-west1/subnetworks/gce"
  }
}
kms_key = "$kms_keys:test"
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:mygroup"
  ]
}
project_id = "$project_ids:test"
region     = "$locations:ew8"
service_account_config = {
  roles = [
    "$custom_roles:myrole_one"
  ]
}
vpc_connector = {
  name = "connector_name"
}
vpc_connector_create = {
  instances = {
    max = 10
    min = 3
  }
  subnet = {
    name = "$subnets:test"
  }
}
