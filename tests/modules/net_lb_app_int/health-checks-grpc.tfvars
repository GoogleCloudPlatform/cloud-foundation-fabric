name       = "hc-test-0"
project_id = "my-project"
health_check_configs = {
  grpc = {
    grpc = {
      port               = 1123
      port_name          = "grpc_port_name"
      port_specification = "USE_FIXED_PORT"
      service_name       = "grpc_service_name"
    }
  }
}
