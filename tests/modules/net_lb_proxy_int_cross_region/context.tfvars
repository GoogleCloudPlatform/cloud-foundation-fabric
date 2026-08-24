name       = "proxy-cr-ctx-test"
project_id = "$project_ids:my-project"

context = {
  project_ids = {
    my-project = "concrete-project-id"
  }
  networks = {
    my-vpc = "projects/concrete-project-id/global/networks/concrete-vpc"
  }
  subnets = {
    my-subnet-1 = "projects/concrete-project-id/regions/europe-west1/subnetworks/concrete-subnet-1"
    my-subnet-2 = "projects/concrete-project-id/regions/europe-west4/subnetworks/concrete-subnet-2"
  }
  addresses = {
    my-addr-1 = "10.0.0.10"
  }
}

vpc_config = {
  network = "$networks:my-vpc"
  subnetworks = {
    europe-west1 = "$subnets:my-subnet-1"
    europe-west4 = "$subnets:my-subnet-2"
  }
}

addresses = {
  europe-west1 = "$addresses:my-addr-1"
}

neg_configs = {
  neg-a = {
    gce = {
      zone       = "europe-west1-b"
      network    = "$networks:my-vpc"
      subnetwork = "$subnets:my-subnet-1"
      endpoints = {
        vm-a = {
          instance   = "my-vm-a"
          ip_address = "10.0.0.2"
          port       = 80
        }
      }
    }
  }
}

backend_service_config = {
  backends = [{
    group = "neg-a"
    max_connections = {
      per_endpoint = 100
    }
  }]
}
