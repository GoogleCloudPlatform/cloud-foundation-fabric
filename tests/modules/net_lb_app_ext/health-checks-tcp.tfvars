name       = "hc-test-0"
project_id = "my-project"
health_check_configs = {
  tcp = {
    tcp = {
      port               = 5123
      port_name          = "tcp_port_name"
      port_specification = "USE_FIXED_PORT"
      proxy_header       = "PROXY_V1"
      request            = "tcp_request"
      response           = "tcp_response"
    }
  }
}
