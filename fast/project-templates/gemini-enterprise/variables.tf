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

variable "allowed_data_sources" {
  description = "Approved connector data_source types enforced by constraints/discoveryengine.managed.allowedDataSources."
  type        = list(string)
  nullable    = false
  default = [
    "gcs",
    "bigquery",
    "google_drive",
    "google_mail",
    "google_calendar",
    "google_chat",
    "gdrive",
    "gmail",
    "jira",
    "confluence",
    "slack",
    "custom_mcp",
  ]
}

variable "allowed_egress_fqdns" {
  description = "Approved outbound FQDNs (including OAuth token hosts and MCP endpoints) enforced by constraints/discoveryengine.managed.allowedEgressFqdns."
  type        = list(string)
  nullable    = false
  default = [
    "example.atlassian.net",
    "auth.atlassian.com",
    "api.atlassian.com",
    "mcp.internal.example.com",
  ]
}

variable "company_name" {
  description = "Organization display name shown in Gemini Enterprise."
  type        = string
  nullable    = false
  default     = "Example Enterprise"
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    iam_principals = optional(map(string), {})
    kms_keys       = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "enable_audit_logs" {
  description = "Whether to configure project-level Data Access Audit Logs (ADMIN_READ, DATA_READ, DATA_WRITE) on discoveryengine.googleapis.com and aiplatform.googleapis.com in this template (set false when managed via data_access_logs in project.yaml)."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_cmek" {
  description = "Whether to provision and bind a regional Cloud KMS CMEK configuration (initial CMEK Spanner provisioning takes 20 to 45 minutes)."
  type        = bool
  nullable    = false
  default     = false
}

variable "enable_free_trial_license" {
  description = "Whether to provision a 30-day Gemini Enterprise free_trial_gemini LicenseConfig and auto-assign seats via default_user_store when license_config_name is null."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_gcs_connector" {
  description = "Whether to provision a Cloud Storage knowledge bucket and periodic GCS DataConnector with auto_generate_ids = false for unstructured documents."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_jira_connector" {
  description = "Whether to provision the 3P Jira Cloud Federated and Actions DataConnector with an explicit bap_config.enabled_actions HITL allowlist."
  type        = bool
  nullable    = false
  default     = false
}

variable "enable_model_armor" {
  description = "Whether to configure project-wide Model Armor floor settings across Vertex AI and MCP server calls."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_workspace_connectors" {
  description = "Whether to provision the 1P Google Workspace federated connectors (Google Drive, Gmail, Google Calendar, and Google Chat)."
  type        = bool
  nullable    = false
  default     = false
}

variable "enforce_org_policies" {
  description = "Whether to manage the 3 discoveryengine.managed.* project-level organization policies in this template (set false when managed in project.yaml)."
  type        = bool
  nullable    = false
  default     = true
}

variable "idp_config" {
  description = "Identity provider configuration for Gemini Enterprise ACLs and Web App SSO (GSUITE or THIRD_PARTY Workforce Identity Federation)."
  type = object({
    idp_type              = optional(string, "GSUITE")
    workforce_pool_id     = optional(string)
    workforce_provider_id = optional(string)
  })
  nullable = false
  default  = {}
  validation {
    condition     = contains(["GSUITE", "THIRD_PARTY"], var.idp_config.idp_type)
    error_message = "idp_config.idp_type must be one of [GSUITE, THIRD_PARTY]."
  }
  validation {
    condition = (
      var.idp_config.idp_type != "THIRD_PARTY" || (
        var.idp_config.workforce_pool_id != null &&
        var.idp_config.workforce_provider_id != null
      )
    )
    error_message = "workforce_pool_id and workforce_provider_id are required when idp_config.idp_type is THIRD_PARTY."
  }
}

variable "jira_config" {
  description = "Jira Cloud Federated and Actions connector configuration when enable_jira_connector is true."
  type = object({
    client_id               = optional(string, "jira-oauth-client-id")
    client_secret_id        = optional(string, "jira-oauth-client-secret")
    cloud_id                = optional(string, "00000000-0000-0000-0000-000000000000")
    enabled_actions         = optional(list(string), ["create_issue", "update_issue", "create_comment"])
    instance_uri            = optional(string, "https://example.atlassian.net")
    refresh_token_secret_id = optional(string, "jira-oauth-refresh-token")
  })
  nullable = false
  default  = {}
}

variable "license_config_name" {
  description = "Optional existing LicenseConfig resource name (projects/.../locations/.../licenseConfigs/...) for automatic seat assignment."
  type        = string
  default     = null
}

variable "location" {
  description = "Gemini Enterprise multi-region location (us, eu, or global)."
  type        = string
  nullable    = false
  default     = "us"
}

variable "name" {
  description = "Base name for the Gemini Enterprise engines and supporting resources."
  type        = string
  nullable    = false
  default     = "gemini-enterprise"
}

variable "prefix" {
  description = "Optional prefix for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Target Google Cloud project ID for Gemini Enterprise."
  type        = string
  nullable    = false
}

variable "validation_app_principals" {
  description = "IAM principals granted roles/discoveryengine.agentspaceUser on the restricted Connector Validation app."
  type        = list(string)
  nullable    = false
}

variable "workforce_app_principals" {
  description = "IAM principals granted roles/discoveryengine.agentspaceUser on the primary Production Workforce app."
  type        = list(string)
  nullable    = false
}

variable "workspace_oauth_config" {
  description = "Optional Web Application OAuth 2.0 client configuration (redirect URI https://vertexaisearch.cloud.google.com/oauth-redirect) to enable write ACTIONS on Google Drive, Gmail, and Google Calendar connectors when enable_workspace_connectors is true."
  type = object({
    client_id        = optional(string)
    client_secret_id = optional(string)
  })
  nullable = false
  default  = {}
  validation {
    condition = (
      (var.workspace_oauth_config.client_id == null) ==
      (var.workspace_oauth_config.client_secret_id == null)
    )
    error_message = "workspace_oauth_config.client_id and workspace_oauth_config.client_secret_id must both be set or both be null."
  }
}
