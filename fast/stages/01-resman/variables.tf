/**
 * Copyright 2022 Google LLC
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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "automation_project_id" {
  # tfdoc:variable:source 00-bootstrap
  description = "Project id for the automation project created by the bootstrap stage."
  type        = string
}

variable "billing_account" {
  # tfdoc:variable:source 00-bootstrap
  description = "Billing account id and organization id ('nnnnnnnn' or null)."
  type = object({
    id              = string
    organization_id = number
  })
}

variable "custom_roles" {
  # tfdoc:variable:source 00-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    service_project_network_admin = string
  })
  default = null
}

variable "groups" {
  # tfdoc:variable:source 00-bootstrap
  description = "Group names to grant organization-level permissions."
  type        = map(string)
  # https://cloud.google.com/docs/enterprise/setup-checklist
  default = {
    gcp-billing-admins      = "gcp-billing-admins",
    gcp-devops              = "gcp-devops",
    gcp-network-admins      = "gcp-network-admins"
    gcp-organization-admins = "gcp-organization-admins"
    gcp-security-admins     = "gcp-security-admins"
    gcp-support             = "gcp-support"
  }
}

variable "organization" {
  # tfdoc:variable:source 00-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "organization_policy_configs" {
  description = "Organization policies customization."
  type = object({
    allowed_policy_member_domains = list(string)
  })
  default = null
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 00-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "team_folders" {
  description = "Team folders to be created. Format is described in a code comment."
  type = map(object({
    descriptive_name     = string
    group_iam            = map(list(string))
    impersonation_groups = list(string)
  }))
  default = null
  # default = {
  #   team-a = {
  #     descriptive_name = "Team A"
  #     group_iam = {
  #       team-a-group@example.com = ["roles/owner", "roles/resourcemanager.projectCreator"]
  #     }
  #     impersonation_groups = ["team-a-admins@example.com"]
  #   }
  # }
}
