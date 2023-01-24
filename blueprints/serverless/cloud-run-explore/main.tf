module "cloud_run" {
  source     = "../../../modules/cloud-run"
  project_id = var.project_id
  name       = "hello"
  containers = [{
    image         = var.image
    options       = null
    ports         = null
    resources     = null
    volume_mounts = null
  }]
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
}
