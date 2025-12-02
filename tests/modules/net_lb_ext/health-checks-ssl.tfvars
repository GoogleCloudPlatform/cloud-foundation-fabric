project_id = "my-project"
region     = "europe-west1"
name       = "nlb-test"
backends = [{
  group    = "foo"
  failover = false
}]

health_check_config = {
  ssl = {
    port               = 6123
    port_name          = "ssl_port_name"
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "PROXY_V1"
    request            = "ssl_request"
    response           = "ssl_response"
  }
}
