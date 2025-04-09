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

variable "billing_account" {
  description = "Billing account id used for the project."
  type        = string
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "project_id" {
  description = "Project id for the monitoring project."
  type        = string
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = true
}

variable "create_notification_channels" {
  description = "Create notification channels for alerts."
  type        = bool
  default     = false
}

variable "notification_email" {
  description = "Email address for notifications."
  type        = string
  default     = null
}

variable "create_alert_policies" {
  description = "Create alert policies for common metrics."
  type        = bool
  default     = true
}

variable "create_dashboards" {
  description = "Create monitoring dashboards."
  type        = bool
  default     = true
}