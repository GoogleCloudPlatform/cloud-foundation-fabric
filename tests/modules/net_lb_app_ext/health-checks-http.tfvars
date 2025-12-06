name       = "hc-test-0"
project_id = "my-project"
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
