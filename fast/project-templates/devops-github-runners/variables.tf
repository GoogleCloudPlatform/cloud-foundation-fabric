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
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "crema_config" {
  description = "CREMA autoscaler Cloud Run service configuration."
  type = object({
    cooldown_period              = optional(number, 300)
    deletion_protection          = optional(bool, false)
    image                        = optional(string, "us-central1-docker.pkg.dev/cloud-run-oss-images/crema-v1/autoscaler:1.2")
    polling_interval             = optional(number, 15)
    service_account              = optional(string)
    service_name                 = optional(string, "crema-github-autoscaler")
    target_workflow_queue_length = optional(number, 1)
  })
  default  = {}
  nullable = false
}

variable "github_config" {
  description = "GitHub organization and GitHub App authentication settings."
  type = object({
    app_id          = string
    installation_id = string
    org             = string
  })
  nullable = false
}

variable "location" {
  description = "Google Cloud region for Cloud Run, Artifact Registry, Secret Manager, and Parameter Manager."
  type        = string
  nullable    = false
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

variable "project_config" {
  description = "Target project ID and project number provisioned via project.yaml."
  type = object({
    number     = number
    project_id = string
  })
  nullable = false
}

variable "runner_config" {
  description = "Cloud Run Worker Pool and GitHub Actions runner container configuration."
  type = object({
    artifact_registry_repo = optional(string, "github-runner-repo")
    cpu                    = optional(string, "2")
    deletion_protection    = optional(bool, false)
    group_id               = optional(number, 1)
    image_name             = optional(string, "github-actions-runner")
    image_tag              = optional(string, "latest")
    labels                 = optional(string, "self-hosted,cloud-run,linux")
    max_replicas           = optional(number, 5)
    memory                 = optional(string, "2Gi")
    min_replicas           = optional(number, 0)
    service_account        = optional(string)
    worker_pool_name       = optional(string, "github-runner-pool")
  })
  default  = {}
  nullable = false
}
