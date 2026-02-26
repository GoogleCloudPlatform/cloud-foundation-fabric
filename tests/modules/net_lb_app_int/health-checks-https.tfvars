name       = "hc-test-0"
project_id = "my-project"
health_check_configs = {
  https = {
    https = {
      host               = "https_host"
      port               = 4123
      port_name          = "https_port_name"
      port_specification = "USE_FIXED_PORT" # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
      proxy_header       = "PROXY_V1"
      request_path       = "https_request_path"
      response           = "https_response"
    }
  }
}
