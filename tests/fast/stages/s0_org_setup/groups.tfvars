factories_config = {
  paths = {
    cicd_workflows = "./data-simple/cicd-workflows.yaml"
    defaults       = "./data-simple/defaults.yaml"
  }
}

# trim the predefined iam_principals map to just the bound group
groups = ["gcp-organization-admins"]
