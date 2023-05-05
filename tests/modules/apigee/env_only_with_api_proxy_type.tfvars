project_id = "my-project"
environments = {
  apis-test = {
    display_name   = "APIs test"
    description    = "APIs Test"
    api_proxy_type = "PROGRAMMABLE"
    envgroups      = ["test"]
    node_config = {
      min_node_count = 2
      max_node_count = 5
    }
  }
}
