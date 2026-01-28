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

variable "compute_kms_key" {
  description = "KMS key for Compute Engine."
  type        = string
  default     = null
}
variable "compute_service_account" {
  description = "Service account for Compute Engine."
  type        = string
  default     = null
}
variable "gke_kms_key" {
  description = "KMS key for GKE."
  type        = string
  default     = null
}
variable "gke_service_account" {
  description = "Service account for GKE nodes."
  type        = string
  default     = null
}
variable "pubsub_kms_key" {
  description = "KMS key for Pub/Sub."
  type        = string
  default     = null
}
variable "project_id" {
  description = "Project ID."
  type        = string
}
variable "project_number" {
  description = "Project Number."
  type        = string
}
variable "region" {
  description = "Region."
  type        = string
  default     = "europe-west1"
}
