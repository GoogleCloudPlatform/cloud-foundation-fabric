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

variable "billing_account_id" {
  description = "Billing account ID."
  type        = string
}

variable "folder_id" {
  description = "Folder used for the GCVE project in folders/nnnnnnnnnnn format."
  type        = string
}

variable "groups" {
  description = "GCVE groups."
  type = object({
    gcp-gcve-admins  = string
    gcp-gcve-viewers = string
  })
  nullable = false
}

variable "iam" {
  description = "Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "labels" {
  description = "Project-level labels."
  type        = map(string)
  default     = {}
}

variable "network_peerings" {
  description = "The network peerings between users' VPCs and the VMware Engine networks. The key is the peering name suffix."
  type = map(object({
    peer_network           = string
    configure_peer_network = optional(bool, false)
    custom_routes = optional(object({
      export_to_peer   = optional(bool, false)
      import_from_peer = optional(bool, false)
      export_to_ven    = optional(bool, false)
      import_from_ven  = optional(bool, false)
    }), {})
    custom_routes_with_public_ip = optional(object({
      export_to_peer   = optional(bool, false)
      import_from_peer = optional(bool, false)
      export_to_ven    = optional(bool, false)
      import_from_ven  = optional(bool, false)
    }), {})
    description                   = optional(string, "Managed by Terraform.")
    peer_project_id               = optional(string)
    peer_to_vmware_engine_network = optional(bool, false)
  }))
  nullable = false
  default  = {}
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "private_cloud_configs" {
  description = "The VMware private cloud configurations. The key is the unique private cloud name suffix."
  type = map(object({
    cidr = string
    zone = string
    # The key is the unique additional cluster name suffix
    additional_cluster_configs = optional(map(object({
      custom_core_count = optional(number)
      node_count        = optional(number, 3)
      node_type_id      = optional(string, "standard-72")
    })), {})
    management_cluster_config = optional(object({
      custom_core_count = optional(number)
      name              = optional(string, "mgmt-cluster")
      node_count        = optional(number, 3)
      node_type_id      = optional(string, "standard-72")
    }), {})
    description = optional(string, "Managed by Terraform.")
  }))
  nullable = false
}

variable "project_id" {
  description = "ID of the project that will contain the GCVE private cloud."
  type        = string
}

variable "project_services" {
  description = "Additional project services to enable."
  type        = list(string)
  default     = []
  nullable    = false
}

// Monitoring inputs

variable "vm_mon_name" {
  description = "GCE VM name where GCVE monitoring agent will run"
  type        = string
  default     = "bp-agent"
}

variable "vm_mon_type" {
  description = "GCE VM machine type"
  type        = string
  default     = "e2-small"
}

variable "vm_mon_zone" {
  description = "GCP zone where GCE VM will be deployed"
  type        = string
  default     = "europe-west1-b"
}

variable "subnetwork" {
  description = "Subnetwork where the VM will be deployed to"
  type        = string
  default     = "prod-default-ew1"
}

variable "sa_gcve_monitoring" {
  description = "Service account for GCVE monitoring agent"
  type        = string
  default     = "gcve-mon-sa"
}

variable "secret_vsphere_server" {
  type        = string
  description = "The secret name conatining the FQDN of the vSphere vCenter server"
  default     = "gcve-mon-vsphere-server"
}

variable "secret_vsphere_user" {
  type        = string
  description = "The secret name containing the user for the vCenter server. Must be an admin user"
  default     = "gcve-mon-vsphere-user"
}

variable "secret_vsphere_password" {
  type        = string
  description = "The secret name containing the password for the vCenter admin user"
  default     = "gcve-mon-vsphere-password"
}

variable "gcve_region" {
  description = "Region where the Private Cloud is deployed"
  type        = string
  default     = "europe-west1"
}

variable "hc_interval_sec" {
  description = "Healthcheck interval in seconds"
  type        = number
  default     = 5
}

variable "hc_timeout_sec" {
  description = "Healthcheck timeout in seconds"
  type        = number
  default     = 5
}

variable "hc_healthy_threshold" {
  description = "How many consecutive success checks to consider the VM as healthy"
  type        = number
  default     = 2
}

variable "hc_unhealthy_threshold" {
  description = "How many consecutive success checks to consider the VM as unhealthy"
  type        = number
  default     = 2
}

variable "initial_delay_sec" {
  description = "How long to delay checking for healthcheck upon initialization"
  type        = number
  default     = 180
}

variable "create_dashboards" {
  description = "Define if sample GCVE monitoring dashboards should be installed"
  type        = bool
  default     = true
}

variable "network_project_id" {
  description = "Project ID of shared VPC"
  type        = string
}

variable "network_self_link" {
  description = "Self Link of shared VPC in which Monitoring VMs will be placed"
  type        = string
}