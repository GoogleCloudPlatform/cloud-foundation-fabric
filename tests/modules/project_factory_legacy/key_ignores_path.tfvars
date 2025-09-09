data_defaults = {
  billing_account  = "1245-5678-9012"
  parent           = "folders/1234"
  storage_location = "EU"
  contacts = {
    "admin-default@example.org" = ["ALL"]
  }
  tag_bindings = {
    name1 = "default-id1"
    name2 = "default-id2"
  }
  services = [
    "default-service.googleapis.com"
  ]
}
data_overrides = {
  prefix = "test-pf"
}
factories_config = {
  folders_data_path  = "key_ignores_path/hierarchy"
  projects_data_path = "key_ignores_path/projects"
  projects_config = {
    key_ignores_path = true
  }
  context = {
    folder_ids = {
      default = "folders/5678901234"
      teams   = "folders/5678901234"
    }
    iam_principals = {
      gcp-devops = "group:gcp-devops@example.org"
    }
    tag_values = {
      "org-policies/drs-allow-all" = "tagValues/123456"
    }
    vpc_host_projects = {
      dev-spoke-0 = "test-pf-dev-net-spoke-0"
    }
  }
}
