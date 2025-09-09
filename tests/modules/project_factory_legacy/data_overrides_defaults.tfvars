data_defaults = {
  billing_account  = "1245-5678-9012"
  parent           = "folders/1234"
  storage_location = "EU"
  contacts = {
    "admin-default@example.org" = ["ALL"] # should not surface, as overrides provide value
  }
  tag_bindings = { # should not surface, as overrides provide empty value
    name1 = "default-id1"
    name2 = "default-id2"
  }
  services = [
    "default-service.googleapis.com"
  ]
}
# make sure the environment label and stackdriver service are always added
data_merges = {
  labels = {
    environment = "test"
  }
  services = [
    "stackdriver.googleapis.com"
  ]
}
# always use this contacts and prefix, regardless of what is in the yaml file
data_overrides = {
  contacts = {
    "admin@example.org" = ["ALL"]
  }
  tag_bindings = {} # prevent setting any encryption keys
  prefix       = "test-pf"
}
# location where the yaml files are read from
factories_config = {
  projects_data_path = "projects"
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
