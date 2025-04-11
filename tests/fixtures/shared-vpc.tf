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

module "project-host" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "host"
  parent          = var.folder_id
  prefix          = var.prefix
  shared_vpc_host_config = {
    enabled = true
  }
}

module "project-service" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "service"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    # trimmed down list of services, to be extended as needed
    "apigee.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "eventarc.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "vpcaccess.googleapis.com",
  ]
  shared_vpc_service_config = {
    host_project = module.project-host.project_id
    # reuse the list of services from the module's outputs
    service_iam_grants = module.project-service.services
  }
}

module "net-vpc-host" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project-host.project_id
  name       = "host-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "fixture-subnet-24"
      region        = var.region
      secondary_ip_ranges = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
    },
    {
      ip_cidr_range = "10.0.1.0/28"
      name          = "fixture-subnet-28"
      region        = var.region
      secondary_ip_ranges = {
        pods     = "172.16.16.0/20"
        services = "192.168.1.0/24"
      }
    }

  ]
}
