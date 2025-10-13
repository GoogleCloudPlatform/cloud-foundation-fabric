attached_disks = [{
  name = "data-0"
  size = 10
  }
]
context = {
  addresses = {
    ext-test-0 = "35.10.10.10"
    int-test-0 = "10.0.0.10"
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
    ew8a = "europe-west8-a"
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
}
create_template = {
  regional = true
}
encryption = {
  encrypt_boot      = true
  kms_key_self_link = "$kms_keys:test"
}
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:mygroup"
  ]
}
name = "test"
network_interfaces = [{
  network    = "$networks:test"
  subnetwork = "$subnets:test"
  nat        = true
  addresses = {
    external = "$addresses:ext-test-0"
    internal = "$addresses:int-test-0"
  }
}]
project_id = "$project_ids:test"
tag_bindings = {
  foo = "$tag_values:test/one"
}
zone = "$locations:ew8a"
