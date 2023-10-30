modules_config = {
  repository_name = "GoogleCloudPlatform/cloud-foundation-fabric"
  source_ref      = "v25.0.0"
  module_prefix   = "modules/"
}

repositories = {
  gcp-fast-00-bootstrap = {
    # create_options = {
    #   description = "FAST bootstrap."
    #   features = {
    #     issues = true
    #   }
    # }
    populate_from = "../../stages/0-bootstrap"
  }
  gcp-fast-01-resman = {
    # create_options = {
    #   description = "FAST resource management."
    #   features = {
    #     issues = true
    #   }
    # }
    populate_from = "../../stages/1-resman"
  }
  gcp-fast-02-networking = {
    create_options = {
      description = "FAST Networking setup"
      features = {
        issues = true
      }
    }
    populate_from = "../../stages/2-networking-d-separate-envs"
  }  
}
# tftest skip
organization = "ozone-project"