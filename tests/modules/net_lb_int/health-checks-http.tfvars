project_id = "my-project"
region     = "europe-west1"
name       = "ilb-test"
vpc_config = {
  network    = "default"
  subnetwork = "default"
}
backends = [{
  group    = "foo"
  failover = false
}]
health_check_config = {
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
