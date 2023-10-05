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

variable "cluster_machine_type" {
  description = "Cluster nachine type."
  type        = string
  default     = "e2-standard-4"
}

variable "cluster_network_config" {
  description = "Cluster network configuration."
  type = object({
    nodes_cidr_block              = string
    pods_cidr_block               = string
    services_cidr_block           = string
    master_authorized_cidr_blocks = map(string)
    master_cidr_block             = string
  })
  default = {
    nodes_cidr_block    = "10.0.1.0/24"
    pods_cidr_block     = "172.16.0.0/20"
    services_cidr_block = "192.168.0.0/24"
    master_authorized_cidr_blocks = {
      internal = "10.0.0.0/8"
    }
    master_cidr_block = "10.0.0.0/28"
  }
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters, CloudSQL instances) in this blueprint. When this field is set in Terraform state, a terraform destroy or terraform apply that would delete data storage resources will fail."
  type        = bool
  default     = false
  nullable    = false
}

variable "hostname" {
  description = "Host name."
  type        = string
}

variable "mgmt_server_config" {
  description = "Mgmt server configuration."
  type = object({
    disk_size     = number
    disk_type     = string
    image         = string
    instance_type = string
  })
  default = {
    disk_size     = 50
    disk_type     = "pd-ssd"
    image         = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    instance_type = "n1-standard-2"
  }
}

variable "mgmt_subnet_cidr_block" {
  description = "Management subnet CIDR block."
  type        = string
  default     = "10.0.2.0/28"
}

variable "project_create" {
  description = "Parameters for the creation of the new project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "region" {
  description = "Region."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone."
  type        = string
  default     = "europe-west1-c"
}
