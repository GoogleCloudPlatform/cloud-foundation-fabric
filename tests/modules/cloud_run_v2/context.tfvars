name = "test-run-context"
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
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
  tag_vars = {
    projects = {
      "test-00" = {
        test = "foo-test-0/dynamic_test"
      }
    }
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
revision = {
  vpc_access = {
    egress_settings = "ALL_TRAFFIC"
  }
}
vpc_connector_create = {
  ip_cidr_range = "$cidr_ranges:test"
  name          = "connector_name"
  network       = "$networks:test"
  instances = {
    max = 10
    min = 3
  }
}
tag_bindings = {
  bar = "tagValues/1234567891"
  baz = "$tag_values:test/one"
  foo = "$${projects[\"test-00\"].test}/cc-123"
}
