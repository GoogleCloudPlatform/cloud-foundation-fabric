project_id   = "$project_ids:project"
cluster_name = "cluster"
location     = "$locations:ew1"
name         = "nodepool"
node_config = {
  boot_disk = {
    kms_key = "$kms_keys:key"
  }
}
context = {
  project_ids = {
    project = "my-project"
  }
  locations = {
    ew1 = "europe-west1"
  }
  kms_keys = {
    key = "projects/my-project/locations/europe-west1/keyRings/my-ring/cryptoKeys/my-key"
  }
}
