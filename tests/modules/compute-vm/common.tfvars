project_id = "my-project"
zone       = "us-central1-b"
name       = "test"
network_interfaces = [{
  network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default"
  subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/subnetworks/default"
}]
