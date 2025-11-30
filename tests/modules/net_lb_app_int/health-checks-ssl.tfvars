name       = "hc-test-0"
project_id = "my-project"
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
