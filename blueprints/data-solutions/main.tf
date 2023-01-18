module "test" {
  source     = "./data-playground"
  prefix     = "plg-202301"
  project_id = "cg1-dev-data-cmn-0"
  network_config = {
    host_project      = "cgg-dev-net-spoke-0"
    network_self_link = "https://www.googleapis.com/compute/v1/projects/cgg-dev-net-spoke-0/global/networks/dev-spoke-0"
    subnet_self_link  = "https://www.googleapis.com/compute/v1/projects/cgg-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-dataplatform-ew1"
  }
}
