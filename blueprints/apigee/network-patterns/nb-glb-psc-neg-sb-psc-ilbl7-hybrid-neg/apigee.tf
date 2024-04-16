/**
 * Copyright 2022 Google LLC
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
  envgroup    = "test"
  environment = "apis-test"
}

module "apigee_project" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account_id
  parent          = var.parent
  name            = var.apigee_project_id
  services = [
    "apigee.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

module "apigee_vpc" {
  source     = "../../../../modules/net-vpc"
  project_id = module.apigee_project.project_id
  name       = "vpc"
  subnets_proxy_only = [
    {
      ip_cidr_range = var.apigee_proxy_only_subnet_ip_cidr_range
      name          = "regional-proxy"
      region        = var.region
      active        = true
    }
  ]
  subnets = [
    {
      ip_cidr_range = var.apigee_subnet_ip_cidr_range
      name          = "subnet"
      region        = var.region
    }
  ]
  subnets_psc = [{
    ip_cidr_range = var.apigee_psc_subnet_ip_cidr_range
    name          = "subnet-psc"
    region        = var.region
  }]
  psa_configs = [{
    ranges = {
      "apigee-runtime"         = var.apigee_runtime_ip_cidr_range
      "apigee-troubleshooting" = var.apigee_troubleshooting_ip_cidr_range
    }
  }]
}

module "apigee" {
  source     = "../../../../modules/apigee"
  project_id = module.apigee_project.project_id
  organization = {
    authorized_network = module.apigee_vpc.network.name
    analytics_region   = var.region
  }
  envgroups = {
    (local.envgroup) = [var.hostname]
  }
  environments = {
    (local.environment) = {
      envgroups = [local.envgroup]
    }
  }
  instances = {
    (var.region) = {
      environments                  = [local.environment]
      runtime_ip_cidr_range         = var.apigee_runtime_ip_cidr_range
      troubleshooting_ip_cidr_range = var.apigee_troubleshooting_ip_cidr_range
    }
  }
  endpoint_attachments = {
    backend = {
      region             = var.region
      service_attachment = google_compute_service_attachment.service_attachment.id
    }
  }
  depends_on = [
    module.apigee_vpc
  ]
}
