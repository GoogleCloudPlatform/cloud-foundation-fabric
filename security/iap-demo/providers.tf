provider "helm" {
  version = "= 1.1.1"
  kubernetes {
    load_config_file       = false
    host                   = "https://${module.gke-cluster.endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(module.gke-cluster.ca_certificate)
  }
}
