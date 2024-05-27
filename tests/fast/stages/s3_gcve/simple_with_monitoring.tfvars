automation = {
  federated_identity_pool      = null
  federated_identity_providers = null
  project_id                   = "fast-prod-automation"
  project_number               = 123456
  outputs_bucket               = "test"
  service_accounts = {
    resman-r = "kschi-dev-resman-gcve-0r@kschi-prod-iac-core-0.iam.gserviceaccount.com"
  }
}

billing_account = {
  id = "000000-111111-222222"
}

folder_ids = {
  gcve-prod = "folders/00000000000000"
}

groups_gcve = {
  gcp-gcve-admins  = "gcp-gcve-admins",
  gcp-gcve-viewers = "gcp-gcve-viewers"
}

host_project_ids = {
  prod-spoke-0 = "prod-spoke-0"
}

organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}

prefix = "fast3"

private_cloud_configs = {
  dev-pc = {
    cidr = "172.26.16.0/22"
    zone = "europe-west8-a"
    management_cluster_config = {
      name         = "mgmt-cluster"
      node_count   = 1
      node_type_id = "standard-72"
    }
  }
}

gcve_monitoring = {
  setup_monitoring        = true
  vm_mon_name             = "bp-agent"
  vm_mon_type             = "e2-small"
  vm_mon_zone             = "europe-west1-b"
  subnetwork              = "prod-default-ew1"
  sa_gcve_monitoring      = "gcve-mon-sa"
  secret_vsphere_server   = "gcve-mon-vsphere-server"
  secret_vsphere_user     = "gcve-mon-vsphere-user"
  secret_vsphere_password = "gcve-mon-vsphere-password"
  gcve_region             = "europe-west1"
  hc_interval_sec         = 4
  hc_timeout_sec          = 5
  hc_healthy_threshold    = 2
  hc_unhealthy_threshold  = 2
  initial_delay_sec       = 180
  create_dashboards       = true
  network_project_id      = "kschi-prod-net-spoke-0"
  network_self_link       = "https://www.googleapis.com/compute/v1/projects/kschi-prod-net-spoke-0/global/networks/prod-spoke-0"
}

vpc_self_links = {
  "prod-spoke-0" = "https://www.googleapis.com/compute/v1/projects/kschi-prod-net-spoke-0/global/networks/prod-spoke-0",
}
