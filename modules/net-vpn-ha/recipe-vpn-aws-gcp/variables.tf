/**
 * Copyright 2025 Google LLC
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

variable "_testing" {
  description = "Populate this variable to avoid triggering the data source."
  type = object({
    name             = string
    number           = number
    services_enabled = optional(list(string), [])
  })
  default = null
}

variable "aws_asn" {
  description = "AWS ASN."
  type        = string
}

variable "aws_region" {
  description = "AWS Region."
  type        = string
}

variable "aws_vpc_cidr_block" {
  description = "CIDR block."
  type        = string
}

variable "gcp_asn" {
  description = "Google ASN."
  type        = string
}

variable "gcp_region" {
  description = "GCP Region."
  type        = string
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "propagate_routes" {
  description = "Flag indicating whether routed received by AWS's Virtual Private Gateway should be propagated to main route table."
  type        = bool
  default     = false
}

variable "shared_secret" {
  description = "Shared secret."
  type        = string
}

