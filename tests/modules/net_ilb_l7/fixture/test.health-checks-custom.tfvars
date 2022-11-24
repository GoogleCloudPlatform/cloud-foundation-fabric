backend_service_configs = {
  default = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
    health_checks = ["custom"]
  }
}
health_check_configs = {
  custom = {
    tcp = {
      port_specification = "USE_SERVING_PORT"
    }
  }
}

