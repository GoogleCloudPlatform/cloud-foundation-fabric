/**
 * Copyright 2020 Google LLC
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

variable "config" {
  description = "Initial configuration applied to the gateway."
  type        = string
  default     = null
}

variable "hostname" {
  description = "Instance FQDN name."
  type        = string
  default     = null
}

variable "iam_members" {
  description = "List of identities for each IAM role set on the instance."
  type        = map(list(string))
  default     = {}
}

variable "iam_roles" {
  description = "List of IAM roles set on the instance."
  type        = list(string)
  default     = []
}

variable "image" {
  description = "Cisco CSR1000v image to use."
  type        = string
  default     = "projects/cisco-public/global/images/csr1000v1721r-byol"
}

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "e2-highcpu-4"
}

variable "labels" {
  description = "Instance labels."
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "Instance metadata."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Instance name."
  type        = string
}

variable "network_interfaces" {
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed."
  type = list(object({
    network    = string
    subnetwork = string
    address    = string
    alias = object({
      ip_cidr_range = string
      range_name    = string
    })
  }))
}

variable "options" {
  description = "Instance options."
  type = object({
    allow_stopping_for_update = bool
    deletion_protection       = bool
    preemptible               = bool
  })
  default = {
    allow_stopping_for_update = true
    deletion_protection       = false
    preemptible               = false
  }
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "region" {
  description = "Compute region."
  type        = string
}

variable "service_account" {
  description = "Service account email."
  type        = string
  default     = null
}

# scopes and scope aliases list
# https://cloud.google.com/sdk/gcloud/reference/compute/instances/create#--scopes
variable "service_account_scopes" {
  description = "Scopes applied to service account."
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "ssh_key" {
  description = "Initial admin SSH key."
  type        = string
}

variable "tags" {
  description = "Instance tags."
  type        = list(string)
  default     = ["gw", "ssh"]
}

variable "zone" {
  description = "Compute zone."
  type        = string
}
