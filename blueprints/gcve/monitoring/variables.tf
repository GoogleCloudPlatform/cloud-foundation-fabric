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

variable "create_dashboards" {
  description = "Specify sample GCVE monitoring dashboards should be installed."
  type        = bool
  default     = true
}

variable "create_firewall_rule" {
  description = "Specify whether a firewall rule to allow Load Balancer Healthcheck should be implemented."
  type        = bool
  default     = true
}

variable "gcve_region" {
  description = "Region where the Private Cloud is deployed."
  type        = string
}

variable "initial_delay_sec" {
  description = "How long to delay checking for healthcheck upon initialization."
  type        = number
  default     = 180
}

variable "monitoring_image" {
  description = "Resource URI for OS image used to deploy monitoring agent."
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-11"
}

variable "project_create" {
  description = "Project configuration for newly created project. Leave null to use existing project. Project creation forces VPC and cluster creation."
  type = object({
    billing_account = string
    parent          = optional(string)
    shared_vpc_host = optional(string)
  })
  default = null
}

variable "project_id" {
  description = "Project id of existing or created project."
  type        = string
}

variable "sa_gcve_monitoring" {
  description = "Service account for GCVE monitoring agent."
  type        = string
  default     = "gcve-mon-sa"
}

variable "vm_mon_config" {
  description = "GCE monitoring instance configuration."
  type = object({
    vm_mon_name = optional(string, "bp-agent")
    vm_mon_type = optional(string, "e2-small")
    vm_mon_zone = string
  })
  nullable = false
}

variable "vpc_config" {
  description = "Shared VPC project and VPC details."
  type = object({
    host_project_id      = string
    vpc_self_link        = string
    subnetwork_self_link = string
  })
  nullable = false
}

variable "vsphere_secrets" {
  description = "Secret Manager secrets that contain vSphere credentials and FQDN."
  type = object({
    vsphere_password = optional(string, "gcve-mon-vsphere-password")
    vsphere_server   = optional(string, "gcve-mon-vsphere-server")
    vsphere_user     = optional(string, "gcve-mon-vsphere-user")
  })
  nullable = false
  default  = {}
}
