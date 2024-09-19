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

variable "access" {
  description = "Map of access rules with role and identity type. Keys are arbitrary and must match those in the `access_identities` variable, types are `domain`, `group`, `special_group`, `user`, `view`."
  type = map(object({
    role = string
    type = string
  }))
  default = {}
  validation {
    condition = can([
      for k, v in var.access :
      index(["domain", "group", "special_group", "user", "view"], v.type)
    ])
    error_message = "Access type must be one of 'domain', 'group', 'special_group', 'user', 'view'."
  }
}

variable "access_identities" {
  description = "Map of access identities used for basic access roles. View identities have the format 'project_id|dataset_id|table_id'."
  type        = map(string)
  default     = {}
}

variable "authorized_datasets" {
  description = "An array of datasets to be authorized on the dataset."
  type = list(object({
    dataset_id = string,
    project_id = string,
  }))
  default = []
}

variable "authorized_routines" {
  description = "An array of routines to be authorized on the dataset."
  type = list(object({
    project_id = string,
    dataset_id = string,
    routine_id = string
  }))
  default = []
}

variable "authorized_views" {
  description = "An array of views to be authorized on the dataset."
  type = list(object({
    dataset_id = string,
    project_id = string,
    table_id   = string # this is the view id, but we keep table_id to stay consistent as the resource
  }))
  default = []
}

variable "dataset_access" {
  description = "Set access in the dataset resource instead of using separate resources."
  type        = bool
  default     = false
}

variable "description" {
  description = "Optional description."
  type        = string
  default     = "Terraform managed."
}

variable "encryption_key" {
  description = "Self link of the KMS key that will be used to protect destination table."
  type        = string
  default     = null
}

variable "friendly_name" {
  description = "Dataset friendly name."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format. Mutually exclusive with the access_* variables used for basic roles."
  type        = map(list(string))
  default     = {}
}

variable "id" {
  description = "Dataset id."
  type        = string
}

variable "labels" {
  description = "Dataset labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Dataset location."
  type        = string
  default     = "EU"
}

variable "materialized_views" {
  description = "Materialized views definitions."
  type = map(object({
    query                            = string
    allow_non_incremental_definition = optional(bool)
    deletion_protection              = optional(bool)
    description                      = optional(string, "Terraform managed.")
    enable_refresh                   = optional(bool)
    friendly_name                    = optional(string)
    labels                           = optional(map(string), {})
    refresh_interval_ms              = optional(bool)
    require_partition_filter         = optional(bool)
    options = optional(object({
      clustering      = optional(list(string))
      expiration_time = optional(number)
    }), {})
    partitioning = optional(object({
      field = optional(string)
      range = optional(object({
        end      = number
        interval = number
        start    = number
      }))
      time = optional(object({
        type          = string
        expiration_ms = optional(number)
        field         = optional(string)
      }))
    }))
  }))
  default = {}
}

variable "options" {
  description = "Dataset options."
  type = object({
    default_collation               = optional(string)
    default_table_expiration_ms     = optional(number)
    default_partition_expiration_ms = optional(number)
    delete_contents_on_destroy      = optional(bool, false)
    is_case_insensitive             = optional(bool)
    max_time_travel_hours           = optional(number, 168)
    storage_billing_model           = optional(string)
  })
  default = {}
}

variable "project_id" {
  description = "Id of the project where datasets will be created."
  type        = string
}

variable "routines" {
  description = "Routine definitions."
  type = map(object({
    description          = optional(string)
    routine_type         = string
    language             = optional(string)
    definition_body      = string
    imported_libraries   = optional(list(string))
    determinism_level    = optional(string)
    data_governance_type = optional(string)
    return_table_type    = optional(string)
    arguments = optional(map(object({
      argument_kind = optional(string)
      mode          = optional(string)
      data_type     = optional(string)
    })), {})
    spark_options = optional(object({
      archive_uris    = optional(list(string), [])
      connection      = string
      container_image = optional(string)
      file_uris       = optional(list(string), [])
      jar_uris        = optional(list(string), [])
      main_file_uri   = optional(string)
      main_class      = optional(string)
      properties      = optional(map(string), {})
      py_file_uris    = optional(list(string), [])
      runtime_version = optional(string)
    }))
    remote_function_options = optional(object({
      connection           = string
      endpoint             = optional(string)
      max_batching_rows    = optional(string)
      user_defined_context = optional(map(string), {})
    }))
  }))
  default = {}
}

variable "tables" {
  description = "Table definitions. Options and partitioning default to null. Partitioning can only use `range` or `time`, set the unused one to null."
  type = map(object({
    deletion_protection      = optional(bool)
    description              = optional(string, "Terraform managed.")
    friendly_name            = optional(string)
    labels                   = optional(map(string), {})
    require_partition_filter = optional(bool)
    schema                   = optional(string)
    external_data_configuration = optional(object({
      autodetect                = bool
      source_uris               = list(string)
      avro_logical_types        = optional(bool)
      compression               = optional(string)
      connection_id             = optional(string)
      file_set_spec_type        = optional(string)
      ignore_unknown_values     = optional(bool)
      metadata_cache_mode       = optional(string)
      object_metadata           = optional(string)
      json_options_encoding     = optional(string)
      reference_file_schema_uri = optional(string)
      schema                    = optional(string)
      source_format             = optional(string)
      max_bad_records           = optional(number)
      csv_options = optional(object({
        quote                 = string
        allow_jagged_rows     = optional(bool)
        allow_quoted_newlines = optional(bool)
        encoding              = optional(string)
        field_delimiter       = optional(string)
        skip_leading_rows     = optional(number)
      }))
      google_sheets_options = optional(object({
        range             = optional(string)
        skip_leading_rows = optional(number)
      }))
      hive_partitioning_options = optional(object({
        mode                     = optional(string)
        require_partition_filter = optional(bool)
        source_uri_prefix        = optional(string)
      }))
      parquet_options = optional(object({
        enum_as_string        = optional(bool)
        enable_list_inference = optional(bool)
      }))

    }))
    options = optional(object({
      clustering      = optional(list(string))
      encryption_key  = optional(string)
      expiration_time = optional(number)
      max_staleness   = optional(string)
    }), {})
    partitioning = optional(object({
      field = optional(string)
      range = optional(object({
        end      = number
        interval = number
        start    = number
      }))
      time = optional(object({
        type          = string
        expiration_ms = optional(number)
        field         = optional(string)
      }))
    }))
    table_constraints = optional(object({
      primary_key_columns = optional(list(string))
      foreign_keys = optional(object({
        referenced_table = object({
          project_id = string
          dataset_id = string
          table_id   = string
        })
        column_references = object({
          referencing_column = string
          referenced_column  = string
        })
        name = optional(string)
      }))
    }))
  }))
  default = {}
}

variable "tag_bindings" {
  description = "Tag bindings for this dataset, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "views" {
  description = "View definitions."
  type = map(object({
    query               = string
    deletion_protection = optional(bool)
    description         = optional(string, "Terraform managed.")
    friendly_name       = optional(string)
    labels              = optional(map(string), {})
    use_legacy_sql      = optional(bool)
  }))
  default = {}
}
