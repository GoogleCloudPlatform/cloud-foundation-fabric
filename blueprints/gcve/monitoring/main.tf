/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  base_gcve_agent_endpoint   = "https://storage.googleapis.com/gcve-observability-agent/latest/vmware-linux-amd64"
  base_gcloud_secret_manager = "gcloud secrets versions access latest --secret="
  sa_gcve_monitoring_roles = toset([
    "roles/secretmanager.secretAccessor",
    "roles/monitoring.admin",
    "roles/logging.logWriter",
  ])
  use_shared_vpc = (
    try(var.project_create.shared_vpc_host, null) != null
  )
  vpc_name = split("/", var.vpc_config.vpc_self_link)[length(split("/", var.vpc_config.vpc_self_link)) - 1]
}

module "project" {
  source          = "../../../modules/project"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account, null)
  name            = var.project_id
  project_create  = var.project_create != null
  services = [
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  shared_vpc_service_config = !local.use_shared_vpc ? null : {
    //attach       = true
    host_project       = var.project_create.shared_vpc_host
    service_iam_grants = module.project.services
  }
}

module "sa_gcve_monitoring" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_id
  name       = var.sa_gcve_monitoring
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/secretmanager.secretAccessor",
      "roles/monitoring.admin",
      "roles/logging.logWriter",
    ]
  }
}

module "gcve-mon-template" {
  source          = "../../../modules/compute-vm"
  project_id      = var.project_id
  name            = "gcve-mon-template"
  zone            = var.vm_mon_config.vm_mon_zone
  instance_type   = var.vm_mon_config.vm_mon_type
  create_template = true
  can_ip_forward  = false
  network_interfaces = [
    {
      network    = var.vpc_config.vpc_self_link
      subnetwork = var.vpc_config.subnetwork_self_link
      nat        = false
      addresses  = null
    }
  ]
  boot_disk = {
    initialize_params = {
      image = var.monitoring_image
      size  = 100
      type  = "pd-balanced"
    }
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = false
    termination_action        = "STOP"
  }

  metadata = {
    startup-script = templatefile("${path.module}/scripts/installer.sh",
      {
        endpoint_agent                 = "${local.base_gcve_agent_endpoint}/artifacts/bpagent-headless-vmware.tar.gz"
        endpoint_install               = "${local.base_gcve_agent_endpoint}/installer/install.sh"
        gcloud_secret_vsphere_server   = "${local.base_gcloud_secret_manager}${var.vsphere_secrets.vsphere_server}"
        gcloud_secret_vsphere_user     = "${local.base_gcloud_secret_manager}${var.vsphere_secrets.vsphere_user}"
        gcloud_secret_vsphere_password = "${local.base_gcloud_secret_manager}${var.vsphere_secrets.vsphere_password}"
        gcve_region                    = var.gcve_region
        project_id                     = var.project_id
    })
  }

  service_account = {
    email  = module.sa_gcve_monitoring.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

module "gcve-mon-mig" {
  source            = "../../../modules/compute-mig"
  project_id        = var.project_id
  location          = var.gcve_region
  name              = "${var.vm_mon_config.vm_mon_name}-mig"
  instance_template = module.gcve-mon-template.template.self_link
  target_size       = 1
  auto_healing_policies = {
    initial_delay_sec = var.initial_delay_sec
  }
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 5142
    }
  }
}

module "secret-manager" {
  source     = "../../../modules/secret-manager"
  project_id = var.project_id
  secrets = {
    (var.vsphere_secrets.vsphere_server)   = { locations = [var.gcve_region] },
    (var.vsphere_secrets.vsphere_user)     = { locations = [var.gcve_region] },
    (var.vsphere_secrets.vsphere_password) = { locations = [var.gcve_region] }
  }
}

module "firewall" {
  source = "../../../modules/net-vpc-firewall"
  count  = var.create_firewall_rule ? 1 : 0

  project_id = var.vpc_config.host_project_id
  network    = local.vpc_name
  default_rules_config = {
    disabled = true
  }

  ingress_rules = {
    allow-healthcheck = {
      description = "Allow healthcheck for Syslog port."
      source_ranges : ["35.191.0.0/16", "130.211.0.0/22"]
      targets : [module.sa_gcve_monitoring.email]
      use_service_accounts : true
      rules = [{
        protocol = "tcp"
        ports    = [5142]
      }]
    }
  }
}

resource "google_monitoring_dashboard" "gcve_mon_dashboards" {
  for_each       = var.create_dashboards ? fileset("${path.module}/dashboards", "*.json") : []
  dashboard_json = file("${path.module}/dashboards/${each.value}")
  project        = var.project_id
}
