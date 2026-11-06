attached_disks = {
  data-0 = {}
}
boot_disk = {
  use_independent_disk = {}
}
encryption = {
  encrypt_boot      = false
  kms_key_self_link = "projects/foo-prod-sec-core/locations/global/keyRings/prod-global-default/cryptoKeys/compute"
}
name = "test"
network_interfaces = [{
  network    = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  subnetwork = "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
}]
project_id = "foo-test-0"
zone       = "europe-west8-a"
