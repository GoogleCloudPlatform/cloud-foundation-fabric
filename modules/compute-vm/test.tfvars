project_id    = "tf-playground-svpc-gce"
zone          = "europe-west8-b"
name          = "test-sa"
instance_type = "e2-small"
network_interfaces = [{
  network    = "https://www.googleapis.com/compute/v1/projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
  subnetwork = "https://www.googleapis.com/compute/v1/projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
}]
# service_account = null
