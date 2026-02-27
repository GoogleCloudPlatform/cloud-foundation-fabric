
context = {
  project_ids = {
    my-project = "project-1"
  }
  locations = {
    ew1 = "europe-west1"
  }
}

project_id        = "$project_ids:my-project"
location          = "$locations:ew1"
name              = "mig-1"
instance_template = "projects/my-project/global/instanceTemplates/default"
target_size       = 1
