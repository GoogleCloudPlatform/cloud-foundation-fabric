/**
 * Copyright 2019 Google LLC
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

variable "project_id" {
  description = "Project id used for this fixture."
  type        = string
}

variable "subnets" {
  description = "Subnet definitions."
  default = {
    subnet-a = {
      ip_cidr_range            = "192.168.0.0/24"
      region                   = "europe-west1"
      description              = "First subnet."
      private_ip_google_access = false
      enable_flow_logs         = false
      secondary_ip_range       = {}
    },
    subnet-b = {
      ip_cidr_range            = "192.168.1.0/24"
      region                   = "europe-west1"
      description              = "Second subnet."
      private_ip_google_access = false
      enable_flow_logs         = false
      secondary_ip_range       = {}
    },
    subnet-c = {
      ip_cidr_range            = "192.168.2.0/24"
      region                   = "europe-west1"
      description              = "Third subnet."
      private_ip_google_access = false
      enable_flow_logs         = false
      secondary_ip_range       = {}
    },
  }
}

locals {
  members = [
    for s in google_service_account.binding_members :
    "serviceAccount:${s.email}"
  ]
}

resource "google_service_account" "binding_members" {
  for_each   = toset(split(" ", "a b c d e"))
  project    = var.project_id
  account_id = "user-${each.value}"
}

module "vpc" {
  source      = "../../../../net-vpc"
  project_id  = var.project_id
  name        = "vpc-iam-bindings"
  description = "Created by the vpc-iam-bindings fixture."
  subnets     = var.subnets
  iam_roles = {
    subnet-b = ["roles/compute.networkUser", "roles/compute.networkViewer"]
    subnet-c = ["roles/compute.networkViewer"]
  }
  iam_members = {
    subnet-b = {
      "roles/compute.networkUser"   = slice(local.members, 0, 2)
      "roles/compute.networkViewer" = slice(local.members, 3, 4)
    }
    subnet-c = {
      "roles/compute.networkViewer" = slice(local.members, 3, 5)
    }
  }
}

output "network" {
  description = "Network resource."
  value       = module.vpc.network
}

output "subnets" {
  description = "Subnet resources."
  value       = module.vpc.subnets
}

output "bindings" {
  description = "Subnet IAM bindings."
  value       = module.vpc.bindings
}
