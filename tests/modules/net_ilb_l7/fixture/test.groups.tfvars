backend_service_configs = {
  default = {
    backends = [{
      group = "custom"
    }]
  }
}
group_configs = {
  custom = {
    zone = "europe-west1-b"
    instances = [
      "projects/myprj/zones/europe-west1-b/instances/vm-a"
    ]
    named_ports = { http = 80 }
  }
}
