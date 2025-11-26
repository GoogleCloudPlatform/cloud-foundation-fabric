name       = "hc-test-0"
project_id = "my-project"
region     = "europe-west4"
backend_service_config = {
  backends = [{
    group = "projects/myprj/zones/europe-west4-a/instanceGroups/my-ig"
  }]
}
vpc_config = {
  network    = "network"
  subnetwork = "subnet"
}
