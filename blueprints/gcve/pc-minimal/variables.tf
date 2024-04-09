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

variable "gcve_monitoring" {
  description = "Inputs for GCVE Monitoring"
  type = object({
    create_dashboards       = optional(bool, true)
    gcve_region             = optional(string)
    hc_healthy_threshold    = optional(number, 2)
    hc_interval_sec         = optional(number, 4)
    hc_timeout_sec          = optional(number, 5)
    hc_unhealthy_threshold  = optional(number, 2)
    initial_delay_sec       = optional(number, 180)
    network_project_id      = optional(string)
    network_self_link       = optional(string)
    sa_gcve_monitoring      = optional(string, "gcve-mon-sa")
    secret_vsphere_password = optional(string, "gcve-mon-vsphere-password")
    secret_vsphere_server   = optional(string, "gcve-mon-vsphere-server")
    secret_vsphere_user     = optional(string, "gcve-mon-vsphere-user")
    setup_monitoring        = optional(bool, false)
    subnetwork              = optional(string)
    vm_mon_name             = optional(string, "bp-agent")
    vm_mon_type             = optional(string, "e2-small")
    vm_mon_zone             = optional(string)
  })
  nullable = true
  default  = {}
}
