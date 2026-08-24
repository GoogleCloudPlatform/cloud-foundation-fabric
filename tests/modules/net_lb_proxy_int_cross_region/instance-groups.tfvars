name       = "proxy-cr-ig-test"
project_id = "my-project"

vpc_config = {
  network = "network"
  subnetworks = {
    europe-west1 = "subnet-ew1"
    europe-west4 = "subnet-ew4"
  }
}

group_configs = {
  ig-a = {
    zone = "europe-west1-b"
    instances = [
      "projects/my-project/zones/europe-west1-b/instances/vm-a"
    ]
  }
}

backend_service_config = {
  backends = [{
    group          = "ig-a"
    balancing_mode = "UTILIZATION"
  }]
}
