/**
 * Copyright 2020 Google LLC
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
  role_id   = "projects/${module.project.project_id}/roles/${local.role_name}"
  role_name = "feeds_cf"
}

module "project" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v2.3.0"
  name           = var.project_id
  project_create = false
  services = [
    "cloudasset.googleapis.com",
    "compute.googleapis.com",
    "cloudfunctions.googleapis.com"
  ]
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
  custom_roles = {
    (local.role_name) = [
      "compute.instances.list",
      "compute.instances.setTags",
      "compute.zones.list",
      "compute.zoneOperations.get",
      "compute.zoneOperations.list"
    ]
  }
}

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v2.3.0"
  project_id = module.project.project_id
  name       = var.name
  subnets = [{
    ip_cidr_range      = "192.168.0.0/24"
    name               = "${var.name}-default"
    region             = var.region
    secondary_ip_range = {}
  }]
}

module "pubsub" {
  source        = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/pubsub?ref=v2.3.0"
  project_id    = module.project.project_id
  name          = var.name
  subscriptions = { "${var.name}-default" = null }
}

module "service-account" {
  source            = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-accounts?ref=v2.3.0"
  project_id        = module.project.project_id
  names             = ["${var.name}-cf"]
  iam_project_roles = { (module.project.project_id) = [local.role_id] }
}

module "cf" {
  source      = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/cloud-function?ref=v2.3.0"
  project_id  = module.project.project_id
  name        = var.name
  bucket_name = "${var.name}-${random_pet.random.id}"
  bucket_config = {
    location             = var.region
    lifecycle_delete_age = null
  }
  bundle_config = {
    source_dir  = "cf"
    output_path = var.bundle_path
  }
  service_account = module.service-account.email
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub.topic.id
    retry    = null
  }
}

module "simple-vm-example" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm?ref=v2.3.0"
  project_id = module.project.project_id
  region     = var.region
  zone       = "${var.region}-b"
  name       = var.name
  network_interfaces = [{
    network    = module.vpc.self_link,
    subnetwork = module.vpc.subnet_self_links["${var.region}/${var.name}-default"],
    nat        = false,
    addresses  = null
  }]
  tags           = ["${var.project_id}-test-feed", "shared-test-feed"]
  instance_count = 1
}

resource "random_pet" "random" {
  length = 1
}
