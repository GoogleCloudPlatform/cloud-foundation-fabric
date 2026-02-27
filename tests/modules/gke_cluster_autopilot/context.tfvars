project_id = "$project_ids:project"
name       = "test"
location   = "$locations:ew1"
vpc_config = {
  network    = "$networks:vpc"
  subnetwork = "$subnetworks:subnet"
}
node_config = {
  boot_disk_kms_key = "$kms_key:key"
}
enable_features = {
  database_encryption = {
    state    = "ENCRYPTED"
    key_name = "$kms_keys:key"
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
