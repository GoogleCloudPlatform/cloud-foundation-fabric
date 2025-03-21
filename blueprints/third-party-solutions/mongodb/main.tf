terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.0"
    }
  }
}

 Configure the MongoDB Atlas Provider
provider "mongodbatlas" {
  public_key = var.mongodbatlas_public_key
  private_key  = var.mongodbatlas_private_key
}

resource "mongodbatlas_project" "project" {
  name   = var.atlas_project_name
  org_id = var.atlas_org_id
}

resource "mongodbatlas_cluster" "cluster" {
  project_id   = mongodbatlas_project.project.id
  name         = var.cluster_name
  provider_name = "GCP"
  provider_instance_size_name = var.instance_size
  provider_region_name = var.atlas_region
  mongo_db_major_version = var.database_version
}

resource "mongodbatlas_privatelink_endpoint" "psc" {
  project_id    = mongodbatlas_project.project.id
  provider_name = "GCP"
  region        = var.atlas_region
}


# Create a Google Network
resource "google_compute_network" "default" {
  project = var.gcp_project_id
  name    = "my-network"
}

# Create a Google Sub Network
resource "google_compute_subnetwork" "default" {
  project       = google_compute_network.default.project
  name          = "my-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.default.id
}

# Create Google 50 Addresses
resource "google_compute_address" "default" {
  count        = 50
  project      = google_compute_subnetwork.default.project
  name         = "landing-zone-${count.index}"
  subnetwork   = google_compute_subnetwork.default.id
  address_type = "INTERNAL"
  address      = "10.0.42.${count.index}"
  region       = google_compute_subnetwork.default.region

  depends_on = [mongodbatlas_privatelink_endpoint.psc]
}

# Create 50 Forwarding rules
resource "google_compute_forwarding_rule" "default" {
  count                 = 50
  target                = mongodbatlas_privatelink_endpoint.psc.service_attachment_names[count.index]
  project               = google_compute_address.default[count.index].project
  region                = google_compute_address.default[count.index].region
  name                  = google_compute_address.default[count.index].name
  ip_address            = google_compute_address.default[count.index].id
  network               = google_compute_network.default.id
  load_balancing_scheme = ""
}

resource "mongodbatlas_privatelink_endpoint_service" "test" {
  project_id          = mongodbatlas_privatelink_endpoint.psc.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.psc.private_link_id
  provider_name       = "GCP"
  endpoint_service_id = google_compute_network.default.name
  gcp_project_id      = var.gcp_project_id

  dynamic "endpoints" {
    for_each = google_compute_address.default

    content {
      ip_address    = endpoints.value["address"]
      endpoint_name = google_compute_forwarding_rule.default[endpoints.key].name
    }
  }

  depends_on = [google_compute_forwarding_rule.default]
}




