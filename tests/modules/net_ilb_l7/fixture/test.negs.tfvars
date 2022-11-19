backend_service_configs = {
  default = {
    backends = [{
      group = "custom"
    }]
  }
}
neg_configs = {
  custom = {
    gce = {
      zone = "europe-west1-b"
      endpoints = [{
        ip_address = "10.0.0.10"
        instance   = "test-1"
        port       = 80
      }]
    }
  }
}
