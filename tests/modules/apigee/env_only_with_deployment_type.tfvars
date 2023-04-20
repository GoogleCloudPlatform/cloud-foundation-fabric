project_id = "my-project"
environments = {
  apis-test = {
    display_name    = "APIs test"
    description     = "APIs Test"
    deployment_type = "ARCHIVE"
    envgroups       = ["test"]
    node_config = {
      min_node_count = 2
      max_node_count = 5
    }
  }
}
