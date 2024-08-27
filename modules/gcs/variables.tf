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

variable "autoclass" {
  description = "Enable autoclass to automatically transition objects to appropriate storage classes based on their access pattern. If set to true, storage_class must be set to STANDARD. Defaults to false."
  type        = bool
  default     = null
}

variable "cors" {
  description = "CORS configuration for the bucket. Defaults to null."
  type = object({
    origin          = optional(list(string))
    method          = optional(list(string))
    response_header = optional(list(string))
    max_age_seconds = optional(number)
  })
  default = null
}

variable "custom_placement_config" {
  type        = list(string)
  default     = null
  description = "The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated as REGIONAL or MULTI_REGIONAL, the parameters are empty."
}

variable "default_event_based_hold" {
  description = "Enable event based hold to new objects added to specific bucket, defaults to false."
  type        = bool
  default     = null
}

variable "encryption_key" {
  description = "KMS key that will be used for encryption."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Optional map to set force destroy keyed by name, defaults to false."
  type        = bool
  default     = false
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "labels" {
  description = "Labels to be attached to all buckets."
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "Bucket lifecycle rule."
  type = map(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      created_before             = optional(string)
      custom_time_before         = optional(string)
      days_since_custom_time     = optional(number)
      days_since_noncurrent_time = optional(number)
      matches_prefix             = optional(list(string))
      matches_storage_class      = optional(list(string)) # STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE, DURABLE_REDUCED_AVAILABILITY
      matches_suffix             = optional(list(string))
      noncurrent_time_before     = optional(string)
      num_newer_versions         = optional(number)
      with_state                 = optional(string) # "LIVE", "ARCHIVED", "ANY"
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.lifecycle_rules : v.action != null && v.condition != null
    ])
    error_message = "Lifecycle rules action and condition cannot be null."
  }
  validation {
    condition = alltrue([
      for k, v in var.lifecycle_rules : contains(
        ["Delete", "SetStorageClass", "AbortIncompleteMultipartUpload"],
        v.action.type
      )
    ])
    error_message = "Lifecycle rules action type has unsupported value."
  }
  validation {
    condition = alltrue([
      for k, v in var.lifecycle_rules :
      v.action.type != "SetStorageClass"
      ||
      v.action.storage_class != null
    ])
    error_message = "Lifecycle rules with action type SetStorageClass require a storage class."
  }
}

variable "location" {
  description = "Bucket location."
  type        = string
  # default     = "EU"
}

variable "logging_config" {
  description = "Bucket logging configuration."
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string)
  })
  default = null
}

variable "managed_folders" {
  description = "Managed folders to create within the bucket in {PATH => CONFIG} format."
  type = map(object({
    force_destroy = optional(bool, false)
    iam           = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  default  = {}
  nullable = false
}

variable "name" {
  description = "Bucket name suffix."
  type        = string
}

variable "notification_config" {
  description = "GCS Notification configuration."
  type = object({
    enabled            = bool
    payload_format     = string
    topic_name         = string
    sa_email           = string
    create_topic       = optional(bool, true)
    event_types        = optional(list(string))
    custom_attributes  = optional(map(string))
    object_name_prefix = optional(string)
  })
  default = null
}

variable "objects_to_upload" {
  description = "Objects to be uploaded to bucket."
  type = map(object({
    name                = string
    metadata            = optional(map(string))
    content             = optional(string)
    source              = optional(string)
    cache_control       = optional(string)
    content_disposition = optional(string)
    content_encoding    = optional(string)
    content_language    = optional(string)
    content_type        = optional(string)
    event_based_hold    = optional(bool)
    temporary_hold      = optional(bool)
    detect_md5hash      = optional(string)
    storage_class       = optional(string)
    kms_key_name        = optional(string)
    customer_encryption = optional(object({
      encryption_algorithm = optional(string)
      encryption_key       = string
    }))
  }))
  default  = {}
  nullable = false
}

variable "prefix" {
  description = "Optional prefix used to generate the bucket name."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Bucket project id."
  type        = string
}

variable "public_access_prevention" {
  description = "Prevents public access to the bucket."
  type        = string
  default     = null
  validation {
    condition     = var.public_access_prevention == null || contains(["enforced", "inherited"], coalesce(var.public_access_prevention, "none"))
    error_message = "public_access_prevention must be either enforced or inherited."
  }
}

variable "requester_pays" {
  description = "Enables Requester Pays on a storage bucket."
  type        = bool
  default     = null
}

variable "retention_policy" {
  description = "Bucket retention policy."
  type = object({
    retention_period = number
    is_locked        = optional(bool)
  })
  default = null
}

variable "rpo" {
  description = "Bucket recovery point objective."
  type        = string
  default     = null
  validation {
    condition     = var.rpo == null || contains(["ASYNC_TURBO", "DEFAULT"], coalesce(var.rpo, "none"))
    error_message = "rpo must be one of ASYNC_TURBO, DEFAULT."
  }
}

variable "soft_delete_retention" {
  description = "The duration in seconds that soft-deleted objects in the bucket will be retained and cannot be permanently deleted. Set to 0 to override the default and disable."
  type        = number
  default     = null
}

variable "storage_class" {
  description = "Bucket storage class."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "tag_bindings" {
  description = "Tag bindings for this folder, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "uniform_bucket_level_access" {
  description = "Allow using object ACLs (false) or not (true, this is the recommended behavior) , defaults to true (which is the recommended practice, but not the behavior of storage API)."
  type        = bool
  default     = true
}

variable "versioning" {
  description = "Enable versioning, defaults to false."
  type        = bool
  default     = null
}

variable "website" {
  description = "Bucket website."
  type = object({
    main_page_suffix = optional(string)
    not_found_page   = optional(string)
  })
  default = null
}
