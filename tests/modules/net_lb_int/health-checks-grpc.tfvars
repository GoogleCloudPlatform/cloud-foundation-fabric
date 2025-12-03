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
  grpc = {
    port               = 1123
    port_name          = "grpc_port_name"
    port_specification = "USE_FIXED_PORT"
    service_name       = "grpc_service_name"
  }
}
