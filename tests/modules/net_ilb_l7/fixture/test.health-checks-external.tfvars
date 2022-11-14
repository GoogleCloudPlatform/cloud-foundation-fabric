backend_service_configs = {
  default = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
    health_checks = ["projects/myprj/global/healthChecks/custom"]
  }
}
health_check_configs = {}

