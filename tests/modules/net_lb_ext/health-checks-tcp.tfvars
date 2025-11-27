project_id = "my-project"
region     = "europe-west1"
name       = "nlb-test"
backends = [{
  group    = "foo"
  failover = false
}]

health_check_config = {
  tcp = {
    port               = 5123
    port_name          = "tcp_port_name"
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "PROXY_V1"
    request            = "tcp_request"
    response           = "tcp_response"
  }
}
