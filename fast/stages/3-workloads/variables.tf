/**
 * Copyright 2026 Google LLC
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

variable "project_ids" {
  description = "Project IDs compiled from previous stages."
  type        = map(string)
  default     = {}
}

variable "subnet_self_links" {
  description = "Subnet self-links compiled from previous stages."
  type        = map(map(string))
  default     = {}
}

# -----------------------------------------------------------------------------
# Workload Factories
# -----------------------------------------------------------------------------

variable "compute_instances" {
  description = "Map of compute instances to create, keyed by unique VM name."
  type = map(object({
    project_key  = string                  # e.g., "lon-dev-project-0"
    machine_type = optional(string, "e2-micro")
    zone         = string                  # e.g., "europe-west2-a"
    image        = optional(string, "projects/debian-cloud/global/images/family/debian-12")
    vpc_key      = string                  # e.g., "london", "new-york", "los-angeles"
    subnet_key   = string                  # e.g., "europe-west2/subnet-london"
    size         = optional(number, 10)
    type         = optional(string, "pd-standard")
    metadata     = optional(map(string), { enable-oslogin = "TRUE" })
    labels       = optional(map(string), {}) # Custom labels for billing and cost queries
  }))
  default = {} # Clear default so no VMs are created unless explicitly declared in .tfvars!

  # -----------------------------------------------------------------------------
  # Allowed Images Validation Guardrail (The pre-approved array)
  # -----------------------------------------------------------------------------
  validation {
    condition = alltrue([
      for vm in var.compute_instances :
      contains([
        "projects/debian-cloud/global/images/family/debian-12",
        "projects/windows-cloud/global/images/family/windows-2022"
      ], coalesce(vm.image, "projects/debian-cloud/global/images/family/debian-12"))
    ])
    error_message = "ERROR: Allowed images are restricted to:\n  - 'projects/debian-cloud/global/images/family/debian-12'\n  - 'projects/windows-cloud/global/images/family/windows-2022'"
  }
}

variable "gcs_buckets" {
  description = "Map of Cloud Storage buckets to create, keyed by unique bucket name."
  type = map(object({
    project_key = string                   # e.g., "lon-dev-project-0"
    location    = optional(string, "europe-west2")
    class       = optional(string, "STANDARD")
    labels      = optional(map(string), {}) # Custom labels for billing and cost queries
  }))
  default = {}
}
