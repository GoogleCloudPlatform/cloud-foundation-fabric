health_check_config = {
  http2 = {
    host               = "http2_host"
    port               = 3123
    port_name          = "http2_port_name"
    port_specification = "USE_FIXED_PORT" # USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT
    proxy_header       = "PROXY_V1"
    request_path       = "http2_request_path"
    response           = "http2_response"
  }
}
