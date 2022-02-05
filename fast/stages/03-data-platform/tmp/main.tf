resource "google_composer_environment" "orch-env-cmp-0" {
  name     = "orc-manual"
  region   = "europe-west1"
  provider = google-beta
  project  = "fs01-orc"
  config {
    node_count = 3
    node_config {
      zone            = "europe-west1-b"
      service_account = "fs01-orc-cmp-0@fs01-orc.iam.gserviceaccount.com"
      network         = "https://www.googleapis.com/compute/v1/projects/fs02-dev-net-spoke-0/global/networks/dev-spoke-0"
      subnetwork      = "https://www.googleapis.com/compute/v1/projects/fs02-dev-net-spoke-0/regions/europe-west1/subnetworks/dev-dp-orc-ew1"
      tags            = ["composer-worker"]
      ip_allocation_policy {
        use_ip_aliases                = "true"
        cluster_secondary_range_name  = "pods"
        services_secondary_range_name = "services"
      }
    }
    software_config {
      image_version = "composer-1.17.5-airflow-2.1.4"
      env_variables = null
    }
    private_environment_config {
      enable_private_endpoint    = "true"
      master_ipv4_cidr_block     = "172.18.30.0/28"
      cloud_sql_ipv4_cidr_block  = "172.18.29.0/24"
      web_server_ipv4_cidr_block = "172.18.30.16/28"
    }
  }
}
