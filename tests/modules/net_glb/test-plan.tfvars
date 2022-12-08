name       = "glb-test-0"
project_id = "my-project"
backend_buckets_config = {
  default-gcs = {
    bucket_name = "my-bucket"
  }
}
backend_service_configs = {
  default = {
    backends = [
      { backend = "projects/my-project/zones/europe-west8-b/instanceGroups/ig-b" },
      { backend = "ig-c" }
    ]
  }
  neg-cloudrun = {
    backends      = [{ backend = "neg-cloudrun" }]
    health_checks = []
  }
  neg-gce = {
    backends       = [{ backend = "neg-gce" }]
    balancing_mode = "RATE"
    max_rate       = { per_endpoint = 10 }
  }
  neg-hybrid = {
    backends       = [{ backend = "neg-hybrid" }]
    balancing_mode = "RATE"
    max_rate       = { per_endpoint = 10 }
  }
  neg-internet = {
    backends      = [{ backend = "neg-internet" }]
    health_checks = []
  }
}
group_configs = {
  ig-c = {
    zone = "europe-west8-c"
    instances = [
      "projects/my-project/zones/europe-west8-c/instances/vm-c"
    ]
    named_ports = { http = 80 }
  }
}
health_check_configs = {
  default = {
    http = {
      host               = "hello.example.org"
      port_specification = "USE_SERVING_PORT"
    }
  }
}
neg_configs = {
  neg-cloudrun = {
    cloudrun = {
      region = "europe-west8"
      target_service = {
        name = "hello"
      }
    }
  }
  neg-gce = {
    gce = {
      network    = "projects/my-project/global/networks/shared-vpc"
      subnetwork = "projects/my-project/regions/europe-west8/subnetworks/gce"
      zone       = "europe-west8-b"
      endpoints = [{
        instance   = "nginx-ew8-b"
        ip_address = "10.24.32.25"
        port       = 80
      }]
    }
  }
  neg-hybrid = {
    hybrid = {
      network = "projects/my-project/global/networks/shared-vpc"
      zone    = "europe-west8-b"
      endpoints = [{
        ip_address = "192.168.0.3"
        port       = 80
      }]
    }
  }
  neg-internet = {
    internet = {
      use_fqdn = true
      endpoints = [{
        destination = "hello.example.org"
        port        = 80
      }]
    }
  }
}
urlmap_config = {
  default_service = "default"
  host_rules = [{
    hosts        = ["*"]
    path_matcher = "pathmap"
  }]
  path_matchers = {
    pathmap = {
      default_service = "default"
      path_rules = [
        { paths = ["/cloudrun", "/cloudrun/*"], service = "neg-cloudrun" },
        { paths = ["/gce", "/gce/*"], service = "neg-gce" },
        { paths = ["/hybrid", "/hybrid/*"], service = "neg-hybrid" },
        { paths = ["/internet", "/internet/*"], service = "neg-internet" },
      ]
    }
  }
}
