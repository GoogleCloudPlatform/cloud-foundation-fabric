project_id = "project"
name       = "test"
location   = "ew1"
vpc_config = {
  network    = "vpc"
  subnetwork = "subnet"
}
node_config = {
  boot_disk_kms_key = "key"
}
enable_features = {
  database_encryption = {
    state    = "ENCRYPTED"
    key_name = "key"
  }
}
context = {
  project_ids = {
    project = "my-project"
  }
  locations = {
    ew1 = "europe-west1"
  }
  networks = {
    vpc = "projects/my-project/global/networks/my-network"
  }
  subnetworks = {
    subnet = "projects/my-project/regions/europe-west1/subnetworks/my-subnetwork"
  }
  kms_keys = {
    key = "projects/my-project/locations/europe-west1/keyRings/my-ring/cryptoKeys/my-key"
  }
}
