module "cloud_run" {
  source     = "../../../../modules/cloud-run-v2"
  project_id = module.service-project.project_id
  name       = var.cloudrun_svcname
  region     = var.region
  containers = {
    default = {
      image = var.image
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}
