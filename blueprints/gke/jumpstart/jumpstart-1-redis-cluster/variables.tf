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

variable "workload_config" {
  description = "Workload configuration. Registry prefix will only work if registry is created by this module."
  type = object({
    image     = optional(string, "redis:6.2")
    namespace = optional(string, "redis")
    statefulset_config = optional(object({
      replicas = optional(number, 6)
      resource_requests = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "1Gi")
      }), {})
      volume_claim_size = optional(string, "1Gi")
    }), {})
    templates_path = optional(string, "manifest-templates")
  })
  nullable = false
  default  = {}
  validation {
    condition     = var.workload_config.statefulset_config.replicas >= 6
    error_message = "At least 6 cluster nodes are required."
  }
}
