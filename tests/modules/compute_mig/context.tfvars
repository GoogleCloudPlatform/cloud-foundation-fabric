
context = {
  project_ids = {
    my-project = "project-1"
  }
  locations = {
    my-region = "europe-west1"
  }
}

project_id        = "$project_ids:my-project"
location          = "$locations:my-region"
name              = "mig-1"
instance_template = "projects/my-project/global/instanceTemplates/default"
target_size       = 1
