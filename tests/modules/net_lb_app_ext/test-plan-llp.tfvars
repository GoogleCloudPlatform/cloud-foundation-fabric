name       = "glb-test-0"
project_id = "my-project"

backend_service_configs = {
  default = {
    backends = [
      { group = "ig-b" },
    ]
    locality_lb_policies = [{
      policy = {
        name = "MAGLEV"
      }
    }]
  }
}
