name       = "proxy-cr-test"
project_id = "my-project"
backend_service_config = {
  backends = [{
    group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
  }]
}
vpc_config = {
  network = "network"
  subnetworks = {
    europe-west1 = "subnet-ew1"
    europe-west4 = "subnet-ew4"
  }
}
