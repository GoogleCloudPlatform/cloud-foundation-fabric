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

locals {
  net_mon_agent_config_filename = "net-mon-agent.conf"
  net_mon_config = merge({
    mon_project_id = var.monitoring_project_id
  }, var.agent_config)
  net_mon_config_sync_source_zip_filename = "config-sync-source-code.zip"
  net_mon_config_sync_config_filename     = "config-sync.conf"
  net_mon_source_code_zip_filename        = "net-mon-source-code.zip"
  network_self_link                       = local.use_shared_vpc ? var.vpc_config.network : module.vpc.0.self_link
  subnetwork_self_link                    = local.use_shared_vpc ? var.vpc_config.subnetwork : module.vpc.0.subnet_self_links["${var.region}/agent"]
  startup_script_config = {
    bucket_name             = module.net_mon_bucket.name
    config_sync_source_name = local.net_mon_config_sync_source_zip_filename
    config_sync_config_name = local.net_mon_config_sync_config_filename
    net_mon_source_name     = local.net_mon_source_code_zip_filename
    net_mon_config_name     = local.net_mon_agent_config_filename
  }
  use_shared_vpc = var.vpc_config != null
}

module "monitoring_project" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project"
  name           = var.monitoring_project_id
  project_create = false
  iam = {
    "roles/monitoring.metricWriter" = [
      "serviceAccount:${module.net-mon-vm.service_account_email}"
    ]
  }
}

module "agent_project" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project"
  name           = var.agent_project_id
  project_create = false
  services = [
    "storage.googleapis.com",
    "compute.googleapis.com"
  ]
}

#######################################################################
#                          NETWORK SETUP                              #
#######################################################################

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.agent_project.project_id
  name       = "${var.prefix}-net-mon-vpc"
  subnets = [
    {
      ip_cidr_range = var.cidrs.agent
      name          = "agent"
      region        = var.region
    }
  ]
}

module "firewall" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.agent_project.project_id
  network    = module.vpc.0.name
}

module "nat" {
  source                = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat"
  count                 = local.use_shared_vpc ? 0 : 1
  project_id            = module.agent_project.project_id
  config_source_subnets = "LIST_OF_SUBNETWORKS"
  logging_filter        = var.nat_logging
  name                  = "default"
  region                = var.region
  router_network        = module.vpc.0.name
  config_port_allocation = {
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
  }
  subnetworks = [
    {
      self_link            = module.vpc.0.subnet_self_links["${var.region}/agent"]
      config_source_ranges = ["ALL_IP_RANGES"]
      secondary_ranges     = null
    }
  ]
}

#######################################################################
#                          STORAGE SETUP                              #
#######################################################################

data "archive_file" "net_mon_source_archived" {
  output_path = "net_mon_source.zip"
  source_dir  = "${path.module}/source/net-mon-agent"
  type        = "zip"
}

data "archive_file" "config_sync_source_archived" {
  output_path = "config_sync.zip"
  source_dir  = "${path.module}/source/config-sync"
  type        = "zip"
}

module "net_mon_bucket" {
  source        = "github.com/terraform-google-modules/cloud-foundation-fabric//modules//gcs"
  project_id    = module.agent_project.project_id
  location      = var.region
  name          = "${var.net_mon_agent_vm_config.name}_${var.agent_project_id}"
  prefix        = var.prefix
  storage_class = "STANDARD"
  iam = {
    "roles/storage.objectViewer" = [
      "serviceAccount:${module.net-mon-vm.service_account_email}"
    ]
    "roles/storage.legacyBucketReader" = [
      "serviceAccount:${module.net-mon-vm.service_account_email}"
    ]
  }
  notification_config = {
    enabled            = true
    payload_format     = "JSON_API_V1"
    sa_email           = module.agent_project.service_accounts.robots.storage
    topic_name         = "${var.prefix}-${var.net_mon_agent_vm_config.name}.configuration"
    event_types        = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
    custom_attributes  = {}
    object_name_prefix = local.net_mon_agent_config_filename
  }
  objects_to_upload = {
    net-mon-source-code = {
      name   = local.net_mon_source_code_zip_filename
      source = data.archive_file.net_mon_source_archived.output_path
    }
    net-mon-agent-config = {
      name    = local.net_mon_agent_config_filename
      content = templatefile("${path.module}/data/net-mon-agent.conf.tpl", local.net_mon_config)
    }
    config-sync-source-code = {
      name   = local.net_mon_config_sync_source_zip_filename
      source = data.archive_file.config_sync_source_archived.output_path
    }
    conf-sync-config = {
      name    = local.net_mon_config_sync_config_filename
      content = file("${path.module}/data/config-sync.conf")
    }
  }
}

#######################################################################
#                      PUBSUB CONFIGURATION                           #
#######################################################################

resource "google_pubsub_subscription" "config_update_sub" {
  name                    = var.net_mon_agent_vm_config.name
  project                 = module.agent_project.project_id
  ack_deadline_seconds    = 20
  enable_message_ordering = false
  topic                   = module.net_mon_bucket.topic
  retry_policy {
    minimum_backoff = "10s"
  }
}

resource "google_pubsub_subscription_iam_member" "config_update_iam" {
  project      = module.agent_project.project_id
  member       = "serviceAccount:${module.net-mon-vm.service_account_email}"
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.config_update_sub.name
}

#######################################################################
#                          COMPUTE VM AGENT                           #
#######################################################################

module "addresses" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-address"
  project_id = module.agent_project.project_id
  external_addresses = {
    net-mon-public-ip = { region = var.region }
  }
}

module "net-mon-vm" {
  source        = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm"
  project_id    = var.agent_project_id
  instance_type = var.net_mon_agent_vm_config.instance_type
  name          = var.net_mon_agent_vm_config.name
  tags          = var.net_mon_agent_vm_config.network_tags
  zone          = "${var.region}-a"
  metadata = {
    pubsub-subscription = google_pubsub_subscription.config_update_sub.name
    startup-script      = templatefile("${path.module}/data/startup-script.sh.tpl", local.startup_script_config)
  }
  network_interfaces = [
    {
      network    = local.network_self_link
      subnetwork = local.subnetwork_self_link
      addresses = {
        nat      = var.net_mon_agent_vm_config.public_ip
        internal = var.net_mon_agent_vm_config.private_ip
        external = var.net_mon_agent_vm_config.public_ip ? module.addresses.external_addresses["net-mon-public-ip"].address : ""
      }
    }
  ]
  service_account = {
    auto_create = true
  }
}
