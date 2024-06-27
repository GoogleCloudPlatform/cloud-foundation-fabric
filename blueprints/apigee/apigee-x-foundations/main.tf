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

module "project" {
  source                  = "../../../modules/project"
  billing_account         = var.project_config.billing_account_id
  compute_metadata        = var.project_config.compute_metadata
  custom_roles            = var.project_config.custom_roles
  default_service_account = var.project_config.default_service_account
  deletion_policy         = var.project_config.deletion_policy
  iam                     = var.project_config.iam
  iam_bindings            = var.project_config.iam_bindings
  iam_bindings_additive   = var.project_config.iam_bindings_additive
  labels                  = var.project_config.labels
  lien_reason             = var.project_config.lien_reason
  logging_data_access     = var.project_config.logging_data_access
  logging_exclusions      = var.project_config.log_exclusions
  logging_sinks           = var.project_config.logging_sinks
  metric_scopes           = var.project_config.metric_scopes
  name                    = var.project_config.name
  org_policies            = var.project_config.org_policies
  parent                  = var.project_config.parent
  prefix                  = var.project_config.prefix
  services = distinct(concat(var.project_config.services, [
    "apigee.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "eventarc.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "servicenetworking.googleapis.com",
    ], var.int_cross_region_lb_config == null ?
    [] : [
      "certificatemanager.googleapis.com"
      ], var.enable_monitoring ? [
      "cloudbuild.googleapis.com",
      "cloudfunctions.googleapis.com",
      "logging.googleapis.com",
      "monitoring.googleapis.com",
      "pubsub.googleapis.com",
      "run.googleapis.com"
  ] : []))

  shared_vpc_service_config = var.project_config.shared_vpc_service_config
  tag_bindings              = var.project_config.tag_bindings
}

module "shared_vpc" {
  count      = var.network_config.shared_vpc == null ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = var.project_config.shared_vpc_service_config.host_project
  name       = var.network_config.shared_vpc.name
  vpc_create = false
}

module "apigee_vpc" {
  count      = var.network_config.apigee_vpc == null ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = coalesce(var.network_config.apigee_vpc.name, "apigee-vpc")
  vpc_create = var.network_config.apigee_vpc.auto_create
  psa_configs = [{
    ranges = merge(flatten([for k, v in var.apigee_config.instances : merge(
      v.runtime_ip_cidr_range == null ? {} : { "apigee-22-${k}" = v.runtime_ip_cidr_range },
      v.troubleshooting_ip_cidr_range == null ? {} : { "apigee-28-${k}" = v.troubleshooting_ip_cidr_range }
    )])...)
    export_routes  = true
    import_routes  = false
    peered_domains = local.peered_domains
  }]
  subnets = [for k, v in var.network_config.apigee_vpc.subnets :
    {
      name          = coalesce(v.name, "subnet-${k}")
      region        = k
      ip_cidr_range = v.ip_cidr_range
      description   = "Subnet in ${k} region"
    }
  if v.ip_cidr_range != null && (nonsensitive(var.int_cross_region_lb_config != null) || nonsensitive(var.int_lb_config != null))]
  subnets_proxy_only = [for k, v in var.network_config.apigee_vpc.subnets_proxy_only :
    {
      name          = coalesce(v.name, "subnet-proxy-only-${k}")
      region        = k
      ip_cidr_range = v.ip_cidr_range
      description   = "Proxy-only subnet in ${k} region"
      global        = var.int_cross_region_lb_config != null
    }
  if v.ip_cidr_range != null && (nonsensitive(var.int_cross_region_lb_config != null) || nonsensitive(var.int_lb_config != null))]
  subnets_psc = [for k, v in var.network_config.apigee_vpc.subnets_psc :
    {
      name          = coalesce(v.name, "subnet-psc-${k}")
      region        = k
      ip_cidr_range = v.ip_cidr_range
      description   = "PSC Subnet in ${k} region"
      global        = var.int_cross_region_lb_config != null
    }
  if v.ip_cidr_range != null]
}

