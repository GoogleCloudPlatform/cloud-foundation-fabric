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

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "logging" {
  # tfdoc:variable:source 0-bootstrap
  description = "Log writer identities for organization / folders."
  type = object({
    project_number    = string
    writer_identities = map(string)
  })
  default = null
}

variable "organization" {
  # tfdoc:variable:source 0-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "root_node" {
  # tfdoc:variable:source 0-bootstrap
  description = "Root node for the hierarchy, if running in tenant mode."
  type        = string
  default     = null
  validation {
    condition = (
      var.root_node == null ||
      startswith(coalesce(var.root_node, "-"), "folders/")
    )
    error_message = "Root node must be in folders/nnnnn format if specified."
  }
}
