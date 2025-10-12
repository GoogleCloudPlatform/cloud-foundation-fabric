services = [
  "container.googleapis.com",
  "run.googleapis.com"
]
shared_vpc_service_config = {
  host_project = "host-project"
  service_agent_iam = {
    "roles/compute.networkUser" = [
      "$service_agents:cloudservices", "$service_agents:container-engine"
    ]
    "roles/vpcaccess.user" = [
      "$service_agents:cloudrun"
    ]
    "roles/container.hostServiceAgentUser" = [
      "$service_agents:container-engine"
    ]
  }
}
project_reuse = {
  use_data_source = false
  attributes = {
    name   = "my-project"
    number = 12345
  }
}
universe = {
  prefix = "alpha"
  unavailable_services = [
    "xxx.googleapis.com",
    "yyy.googleapis.com"
  ]
}
