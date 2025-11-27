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
  http = {
    http = {
      host               = "http_host"
      port               = 2123
      port_name          = "http_port_name"
      port_specification = "USE_FIXED_PORT" # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = "PROXY_V1"
      request_path       = "http_request_path"
      response           = "http_response"
    }
  }
}
