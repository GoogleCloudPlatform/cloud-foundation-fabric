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

variable "name" {
  description = "Network name."
  type        = string
  default     = "net-vpc-standalone"
}

variable "project_id" {
  description = "Project id used for this fixture."
  type        = string
}

module "vpc-simple" {
  source     = "../../../../../modules/net-vpc"
  project_id = var.project_id
  name       = var.name
}

output "name" {
  description = "Network name."
  value       = module.vpc-simple.name
}

output "self_link" {
  description = "Network self link."
  value       = module.vpc-simple.self_link
}

output "subnets" {
  description = "Subnet resources."
  value       = module.vpc-simple.subnets
}
