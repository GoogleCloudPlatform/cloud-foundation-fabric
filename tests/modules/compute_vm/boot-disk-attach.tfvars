name       = "test"
project_id = "test-project"
zone       = "us-central1-a"
network_interfaces = [{
  network    = "default"
  subnetwork = "default"
}]
boot_disk = {
  source = {
    attach = "projects/test-project/zones/us-central1-a/disks/existing-boot-disk"
  }
}
