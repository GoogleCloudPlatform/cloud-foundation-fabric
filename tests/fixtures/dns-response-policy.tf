module "dns-policy-existing" {
  source     = "./fabric/modules/dns-response-policy"
  project_id = var.project_id
  name       = "googleapis"
  networks = {
    landing = var.vpc.self_link
  }
}