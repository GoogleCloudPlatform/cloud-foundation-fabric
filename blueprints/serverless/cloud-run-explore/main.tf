module "cloud_run" {
  source     = "../../../modules/cloud-run"
  project_id = var.project_id
  name       = var.run_svc_name
  region     = var.region
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

module "glb" {
  source     = "../../../modules/net-glb"
  count      = var.glb_create ? 1 : 0
  project_id = var.project_id
  name       = "glb"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
          name = var.run_svc_name
        }
      }
    }
  }
}
