locals {
  domains    = var.domains
  name       = var.name
  project_id = var.project_id != null ? var.project_id : data.google_client_config.current[0].project
}

data "google_client_config" "current" {
  count = var.project_id == null ? 1 : 0
}

resource "google_compute_global_address" "address" {
  name    = local.name
  project = local.project_id
}

resource "google_compute_managed_ssl_certificate" "cert" {
  provider = google-beta

  managed { domains = local.domains }
  name    = local.name
  project = local.project_id
}