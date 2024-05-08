module "cloud_run" {
  source     = "../../../../modules/cloud-run-v2"
  for_each   = var.project_configs
  //project_id = each.value.project_id
  project_id = module.service-project[each.key].project_id
  name       = local.cloudrun_svcnames[index(keys(var.project_configs), each.key)]
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
