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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars       = optional(map(map(string)), {})
    custom_roles         = optional(map(string), {})
    email_addresses      = optional(map(string), {})
    folder_ids           = optional(map(string), {})
    iam_principals       = optional(map(string), {})
    kms_keys             = optional(map(string), {})
    locations            = optional(map(string), {})
    log_buckets          = optional(map(string), {})
    notification_channels = optional(map(string), {})
    project_ids          = optional(map(string), {})
    project_numbers      = optional(map(string), {})
    pubsub_topics        = optional(map(string), {})
    storage_buckets      = optional(map(string), {})
    tag_keys             = optional(map(string), {})
    tag_values           = optional(map(string), {})
    vpc_host_projects    = optional(map(string), {})
    vpc_sc_perimeters    = optional(map(string), {})
    # new keys for application-factory
    secrets              = optional(map(string), {})
    datasets             = optional(map(string), {})
    artifact_registries  = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Path configuration for YAML resource description data files."
  type = object({
    basepath = string
    paths = optional(object({
      service_accounts  = optional(string, "service-accounts")
      gcs               = optional(string, "gcs")
      pubsub            = optional(string, "pubsub")
      bigquery          = optional(string, "bigquery")
      secret_manager    = optional(string, "secret-manager")
      artifact_registry = optional(string, "artifact-registry")
      compute_vm        = optional(string, "compute-vm")
      cloudsql          = optional(string, "cloudsql")
      net_lb_int        = optional(string, "net-lb-int")
      net_lb_app_int    = optional(string, "net-lb-app-int")
    }), {})
  })
  nullable = false
}
