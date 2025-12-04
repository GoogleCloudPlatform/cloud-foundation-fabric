name       = "hc-test-0"
project_id = "my-project"
backend_service_configs = {
  default = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-ew1"
      }, {
      group = "projects/myprj/zones/europe-west4-a/instanceGroups/my-ig-ew4"
    }]
  }
}
vpc_config = {
  network = "network"
  subnetworks = {
    europe-west1 = "subnet-ew1"
    europe-west4 = "subnet-ew4"
  }
}
health_check_configs = {
  ssl = {
    ssl = {
      port               = 6123
      port_name          = "ssl_port_name"
      port_specification = "USE_FIXED_PORT"
      proxy_header       = "PROXY_V1"
      request            = "ssl_request"
      response           = "ssl_response"
    }
  }
}
