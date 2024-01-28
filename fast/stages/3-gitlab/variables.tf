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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type        = object({
    outputs_bucket               = string
    project_id                   = string
    project_number               = string
    federated_identity_pool      = string
    federated_identity_providers = map(object({
      audiences        = list(string)
      issuer           = string
      issuer_uri       = string
      name             = string
      principal_branch = string
      principal_repo   = string
    }))
    service_accounts = object({
      resman-r = string
    })
  })
}

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`."
  type        = object({
    id           = string
    is_org_level = optional(bool, true)
    no_iam       = optional(bool, false)
  })
  nullable = false
}

variable "cloudsql_config" {
  description = "Cloud SQL Postgres config."
  type        = object({
    name             = optional(string, "gitlab-0")
    database_version = optional(string, "POSTGRES_13")
    tier             = optional(string, "db-custom-2-8192")
  })
  default = {}
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folder to be used for the gitlab resources in folders/nnnn format."
  type        = object({
    gitlab = string
  })
}

variable "gcs_config" {
  description = "GCS for Object Storage config."
  type        = object({
    enable_versioning = optional(bool, false)
    location          = optional(string, "EU")
    storage_class     = optional(string, "STANDARD")
  })
  default = {}
}

variable "gitlab_config" {
  type = object({
    hostname = optional(string, "gitlab.gcp.example.com")
    mail     = optional(object({
      enabled  = optional(bool, false)
      sendgrid = optional(object({
        api_key        = optional(string)
        email_from     = optional(string, null)
        email_reply_to = optional(string, null)
      }), null)
    }), {})
    saml = optional(object({
      forced                 = optional(bool, false)
      idp_cert_fingerprint   = string
      sso_target_url         = string
      name_identifier_format = optional(string, "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress")
    }), null)
    ha_required = optional(bool, false)
  })
  default = {}
}

variable "gitlab_instance_config" {
  description = "Gitlab Compute Engine instance config."
  type        = object({
    instance_type = optional(string, "n2-standard-2")
    name          = optional(string, "gitlab-0")
    network_tags  = optional(list(string), [])
    replica_zone  = optional(string, "europe-west1-c")
    zone          = optional(string, "europe-west1-b")
    boot_disk     = optional(object({
      size = optional(number, 20)
      type = optional(string, "pd-standard")
    }), {})
    data_disk = optional(object({
      size         = optional(number, 100)
      type         = optional(string, "pd-ssd")
      replica_zone = optional(string, "europe-west1-c")
    }), {})
  })
  default = {}
}

variable "gitlab_runner_config" {
  description = "Gitlab Runner config."
  type        = object({
    authentication_token = optional(string, null)
    executors_config     = optional(object({
      docker_autoscaler = optional(object({
        gcp_project_id = string
        zone           = optional(string, "europe-west1-b")
        mig_name       = optional(string, "gitlab-runner")
        machine_type   = optional(string, "g1-small")
        machine_image  = optional(string, "coreos-cloud/global/images/family/coreos-stable")
        network_tags   = optional(list(string), ["gitlab-runner"])
      }), null)
      docker = optional(object({
        tls_verify = optional(bool, true)
      }), null)
    }), {})
  })
  validation {
    condition = (
    (try(var.gitlab_runner_config.executors_config.docker_autoscaler, null) == null ? 0 : 1) +
    (try(var.gitlab_runner_config.executors_config.dockerx, null) == null ? 0 : 1) <= 1
    )
    error_message = "Only one type of gitlab runner can be configured at a time."
  }
  default = {}
}

variable "gitlab_runner_instance_config" {
  description = "Gitlab Runner instance config"
  type        = object({
    boot_disk_size = optional(number, 100)
    name           = optional(string, "gitlab-runner-0")
    instance_type  = optional(string, "e2-standard-2")
    network_tags   = optional(list(string), [])
    zone           = optional(string, "europe-west1-b")
  })
  default = {}
}

variable "host_project_ids" {
  type = object({
    dev-spoke-0  = string
    prod-landing = string
  })
}

variable "locations" {
  # tfdoc:variable:source 0-bootstrap
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type        = object({
    bq      = string
    gcs     = string
    logging = string
    pubsub  = list(string)
  })
  nullable = false
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}


variable "prefix" {
  # tfdoc:variable:source 0-globals
  description = "Unique prefix used for resource names. Not used for projects if 'project_create' is null."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 13
    error_message = "Use a maximum of 12 characters for prefix."
  }
}

variable "redis_config" {
  description = "Redis Config."
  type        = object({
    memory_size_gb      = optional(number, 1)
    name                = optional(string, "gitlab-0")
    persistence_mode    = optional(string, "RDB")
    rdb_snapshot_period = optional(string, "TWELVE_HOURS")
    tier                = optional(string, "BASIC")
    version             = optional(string, "REDIS_6_X")
  })
  default = {}
}

variable "regions" {
  description = "Region definitions."
  type        = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "europe-west1"
    secondary = "europe-west4"
  }
}

variable "service_accounts" {
  # tfdoc:variable:source 1-resman
  description = "Automation service accounts in name => email format."
  type        = object({
    data-platform-dev    = string
    data-platform-prod   = string
    gitlab               = string
    gke-dev              = string
    gke-prod             = string
    project-factory-dev  = string
    project-factory-prod = string
  })
  default = null
}

variable "subnet_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC subnet self links."
  type        = object({
    dev-spoke-0  = map(string)
    prod-landing = map(string)
  })
  default = null
}

variable "vpc_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC self links."
  type        = object({
    dev-spoke-0  = string
    prod-landing = string
  })
  default = null
}
