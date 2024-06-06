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

variable "network_project_id" {
  description = "Project ID of shared VPC."
  type        = string
}

variable "network_self_link" {
  description = "Self link of VPC in which Monitoring instance is deployed."
  type        = string
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

variable "secret_vsphere_password" {
  type        = string
  description = "The secret name containing the password for the vCenter admin user."
  default     = "gcve-mon-vsphere-password"
}

variable "secret_vsphere_server" {
  type        = string
  description = "The secret name conatining the FQDN of the vSphere vCenter server."
  default     = "gcve-mon-vsphere-server"
}

variable "secret_vsphere_user" {
  type        = string
  description = "The secret name containing the user for the vCenter server. Must be an admin user."
  default     = "gcve-mon-vsphere-user"
}

variable "subnetwork_self_link" {
  description = "Subnetwork where the VM will be deployed to."
  type        = string
}

variable "vm_mon_name" {
  description = "GCE VM name where GCVE monitoring agent will run."
  type        = string
  default     = "bp-agent"
}

variable "vm_mon_type" {
  description = "GCE VM machine type."
  type        = string
  default     = "e2-small"
}

variable "vm_mon_zone" {
  description = "GCP zone where GCE VM will be deployed."
  type        = string
}
