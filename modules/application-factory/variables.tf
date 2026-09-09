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
  description = "Context-specific interpolations. Keys are the union of those supported by the wrapped modules, and are enriched with factory-managed resources."
  type = object({
    addresses           = optional(map(string), {})
    artifact_registries = optional(map(string), {})
    bigquery_datasets   = optional(map(string), {})
    cidr_ranges         = optional(map(string), {})
    condition_vars      = optional(map(map(string)), {})
    custom_roles        = optional(map(string), {})
    folder_ids          = optional(map(string), {})
    iam_principals      = optional(map(string), {})
    instance_groups     = optional(map(string), {})
    kms_keys            = optional(map(string), {})
    locations           = optional(map(string), {})
    networks            = optional(map(string), {})
    project_ids         = optional(map(string), {})
    pubsub_topics       = optional(map(string), {})
    secrets             = optional(map(string), {})
    service_account_ids = optional(map(string), {})
    storage_buckets     = optional(map(string), {})
    subnets             = optional(map(string), {})
    tag_keys            = optional(map(string), {})
    tag_values          = optional(map(string), {})
    tag_vars = optional(object({
      projects     = optional(map(map(string)), {})
      organization = optional(map(string), {})
    }), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Path configuration for YAML resource description data files. Paths are relative to basepath unless absolute or starting with a dot."
  type = object({
    basepath = string
    paths = optional(object({
      artifact_registry = optional(string, "artifact-registry")
      bigquery          = optional(string, "bigquery")
      cloud_run         = optional(string, "cloud-run")
      cloudsql          = optional(string, "cloudsql")
      compute_vm        = optional(string, "compute-vm")
      gcs               = optional(string, "gcs")
      net_address       = optional(string, "net-address")
      net_lb_app_int    = optional(string, "net-lb-app-int")
      net_lb_int        = optional(string, "net-lb-int")
      pubsub            = optional(string, "pubsub")
      secret_manager    = optional(string, "secret-manager")
      service_accounts  = optional(string, "service-accounts")
    }), {})
  })
  nullable = false
}
