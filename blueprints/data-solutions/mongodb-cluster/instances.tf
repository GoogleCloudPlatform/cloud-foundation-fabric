/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Compute Engine resources.

module "cos-mongodb" {
  source = "../../../modules/cloud-config-container/mongodb"

  admin_username        = "admin"
  admin_password_secret = module.passwords.version_ids[format("%s:v1", local.secret_id)]
  keyfile_secret        = module.passwords.version_ids[format("%s:v1", local.keyfile_secret_id)]

  dns_zone        = module.private-dns.name
  replica_set     = local.replica_set
  mongo_data_disk = "mongodb-data-disk"
  mongo_config    = <<-EOT
  replication:
    replSetName: "${local.replica_set}"
  EOT

  healthcheck_image = var.healthcheck_image
  startup_image     = var.startup_image
}

module "service-account" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = format("mongodb-server-%s", var.cluster_id)

  iam = {}
  iam_project_roles = {
    (module.project.project_id) = ["roles/artifactregistry.reader", "roles/compute.viewer", "roles/monitoring.metricWriter", "roles/logging.logWriter", "roles/dns.admin"]
  }
  iam_sa_roles = {}
}

module "instance-template" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  name       = format("mongodb-server-%s-template", var.cluster_id)
  zone       = "europe-west4-c"
  tags       = ["mongodb-server", "ssh"]

  instance_type = "e2-highmem-4"

  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = var.vpc_config.create ? module.vpc.subnet_self_links[format("%s/%s", var.region, var.vpc_config.subnetwork)] : var.vpc_config.subnetwork_self_link
    addresses  = null
  }]

  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-101-lts"
    type  = "pd-ssd"
    size  = 10
  }

  attached_disks = [{
    name        = ""
    device_name = "mongodb-data-disk"
    size        = var.data_disk_size
    source_type = null
    source      = null
  }]

  service_account_create = false
  service_account        = module.service-account.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  create_template = true
  metadata = {
    user-data              = module.cos-mongodb.cloud_config
    google-logging-enabled = true
  }
}

module "manager-instance-group" {
  source     = "../../../modules/compute-mig"
  project_id = module.project.project_id
  location   = var.region
  name       = local.cluster_name

  target_size       = 3
  instance_template = module.instance-template.template.self_link

  stateful_disks = {
    "mongodb-data-disk" = false
  }

  named_ports = {
    "mongodb" = 27107
  }

  auto_healing_policies = {
    initial_delay_sec = 180 # 3 minutes
  }
  health_check_config = {
    enable_logging      = true
    check_interval_sec  = 10
    healthy_threshold   = 1
    timeout_sec         = 10
    unhealthy_threshold = 2
    http = {
      port = 8080
    }
  }
  distribution_policy = {
    target_shape = "EVEN"
  }
  update_policy = {
    minimal_action = "RESTART"
    type           = "PROACTIVE" # Or set to OPPORTUNISTIC to delay change applying
    max_surge = {
      fixed = 0
    }
    max_unavailable = {
      fixed = 3
    }
    min_ready_sec                = 90 # 1.5 minutes
    most_disruptive_action       = "REPLACE"
    regional_redistribution_type = "NONE"
    replacement_method           = "RECREATE"
  }
}

