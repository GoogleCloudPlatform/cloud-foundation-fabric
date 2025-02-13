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

locals {
  access_domain  = { for k, v in var.access : k => v if v.type == "domain" }
  access_group   = { for k, v in var.access : k => v if v.type == "group" }
  access_special = { for k, v in var.access : k => v if v.type == "special_group" }
  access_user    = { for k, v in var.access : k => v if v.type == "user" }
  access_view    = { for k, v in var.access : k => v if v.type == "view" }

  identities_view = {
    for k, v in local.access_view : k => try(
      zipmap(
        ["project_id", "dataset_id", "table_id"],
        split("|", var.access_identities[k])
      ),
      { project_id = null, dataset_id = null, table_id = null }
    )
  }

  authorized_views = merge(
    { for access_key, view in local.identities_view : "${view["project_id"]}_${view["dataset_id"]}_${view["table_id"]}" => view },
  { for view in var.authorized_views : "${view["project_id"]}_${view["dataset_id"]}_${view["table_id"]}" => view })
  authorized_datasets = { for dataset in var.authorized_datasets : "${dataset["project_id"]}_${dataset["dataset_id"]}" => dataset }
  authorized_routines = { for routine in var.authorized_routines : "${routine["project_id"]}_${routine["dataset_id"]}_${routine["routine_id"]}" => routine }

}

resource "google_bigquery_dataset" "default" {
  project       = var.project_id
  dataset_id    = var.id
  friendly_name = var.friendly_name
  description   = var.description
  labels        = var.labels
  location      = var.location

  delete_contents_on_destroy      = var.options.delete_contents_on_destroy
  default_collation               = var.options.default_collation
  default_table_expiration_ms     = var.options.default_table_expiration_ms
  default_partition_expiration_ms = var.options.default_partition_expiration_ms
  is_case_insensitive             = var.options.is_case_insensitive
  max_time_travel_hours           = var.options.max_time_travel_hours
  storage_billing_model           = var.options.storage_billing_model
  dynamic "access" {
    for_each = var.dataset_access ? local.access_domain : {}
    content {
      role   = access.value.role
      domain = try(var.access_identities[access.key])
    }
  }

  dynamic "access" {
    for_each = var.dataset_access ? local.access_group : {}
    content {
      role           = access.value.role
      group_by_email = try(var.access_identities[access.key])
    }
  }

  dynamic "access" {
    for_each = var.dataset_access ? local.access_special : {}
    content {
      role          = access.value.role
      special_group = try(var.access_identities[access.key])
    }
  }

  dynamic "access" {
    for_each = var.dataset_access ? local.access_user : {}
    content {
      role          = access.value.role
      user_by_email = try(var.access_identities[access.key])
    }
  }

  dynamic "access" {
    for_each = var.dataset_access ? local.authorized_views : {}
    content {
      view {
        project_id = each.value.project_id
        dataset_id = each.value.dataset_id
        table_id   = each.value.table_id
      }
    }
  }

  dynamic "access" {
    for_each = var.dataset_access ? local.authorized_datasets : {}
    content {
      dataset {
        dataset {
          project_id = each.value.project_id
          dataset_id = each.value.dataset_id
        }
        target_types = ["VIEWS"]
      }
    }
  }

  dynamic "access" {
    for_each = var.dataset_access ? local.authorized_routines : {}
    content {
      routine {
        project_id = each.value.project_id
        dataset_id = each.value.dataset_id
        routine_id = each.value.routine_id
      }
    }
  }

  dynamic "default_encryption_configuration" {
    for_each = var.encryption_key == null ? [] : [""]
    content {
      kms_key_name = var.encryption_key
    }
  }
}

resource "google_bigquery_dataset_access" "domain" {
  for_each   = var.dataset_access ? {} : local.access_domain
  provider   = google-beta
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  role       = each.value.role
  domain     = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "group_by_email" {
  for_each       = var.dataset_access ? {} : local.access_group
  provider       = google-beta
  project        = var.project_id
  dataset_id     = google_bigquery_dataset.default.dataset_id
  role           = each.value.role
  group_by_email = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "special_group" {
  for_each      = var.dataset_access ? {} : local.access_special
  provider      = google-beta
  project       = var.project_id
  dataset_id    = google_bigquery_dataset.default.dataset_id
  role          = each.value.role
  special_group = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "user_by_email" {
  for_each      = var.dataset_access ? {} : local.access_user
  provider      = google-beta
  project       = var.project_id
  dataset_id    = google_bigquery_dataset.default.dataset_id
  role          = each.value.role
  user_by_email = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "authorized_views" {
  for_each   = var.dataset_access ? {} : local.authorized_views
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  view {
    project_id = each.value.project_id
    dataset_id = each.value.dataset_id
    table_id   = each.value.table_id
  }
}

resource "google_bigquery_dataset_access" "authorized_datasets" {
  for_each   = var.dataset_access ? {} : local.authorized_datasets
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  dataset {
    dataset {
      project_id = each.value.project_id
      dataset_id = each.value.dataset_id
    }
    target_types = ["VIEWS"]
  }
}

resource "google_bigquery_dataset_access" "authorized_routines" {
  for_each   = var.dataset_access ? {} : local.authorized_routines
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  routine {
    project_id = each.value.project_id
    dataset_id = each.value.dataset_id
    routine_id = each.value.routine_id
  }
}

resource "google_bigquery_dataset_iam_binding" "bindings" {
  for_each   = var.iam
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  role       = each.key
  members    = each.value
}

resource "google_bigquery_table" "default" {
  provider                 = google-beta
  for_each                 = var.tables
  project                  = var.project_id
  dataset_id               = google_bigquery_dataset.default.dataset_id
  table_id                 = each.key
  friendly_name            = each.value.friendly_name
  description              = each.value.description
  clustering               = each.value.options.clustering
  expiration_time          = each.value.options.expiration_time
  labels                   = each.value.labels
  max_staleness            = each.value.options.max_staleness
  schema                   = each.value.schema
  deletion_protection      = each.value.deletion_protection
  require_partition_filter = each.value.require_partition_filter

  dynamic "encryption_configuration" {
    for_each = each.value.options.encryption_key != null ? [""] : []
    content {
      kms_key_name = each.value.options.encryption_key
    }
  }

  dynamic "external_data_configuration" {
    for_each = each.value.external_data_configuration != null ? [""] : []
    content {
      autodetect                = each.value.external_data_configuration.autodetect
      compression               = each.value.external_data_configuration.compression
      connection_id             = each.value.external_data_configuration.connection_id
      file_set_spec_type        = each.value.external_data_configuration.file_set_spec_type
      ignore_unknown_values     = each.value.external_data_configuration.ignore_unknown_values
      max_bad_records           = each.value.external_data_configuration.max_bad_records
      metadata_cache_mode       = each.value.external_data_configuration.metadata_cache_mode
      object_metadata           = each.value.external_data_configuration.object_metadata
      reference_file_schema_uri = each.value.external_data_configuration.reference_file_schema_uri
      schema                    = each.value.external_data_configuration.schema
      source_format             = each.value.external_data_configuration.source_format
      source_uris               = each.value.external_data_configuration.source_uris

      dynamic "avro_options" {
        for_each = each.value.external_data_configuration.avro_logical_types != null ? [""] : []
        content {
          use_avro_logical_types = each.value.external_data_configuration.avro_logical_types
        }
      }
      dynamic "csv_options" {
        for_each = each.value.external_data_configuration.csv_options != null ? [""] : []
        content {
          quote                 = each.value.external_data_configuration.csv_options.quote
          allow_jagged_rows     = each.value.external_data_configuration.csv_options.allow_jagged_rows
          allow_quoted_newlines = each.value.external_data_configuration.csv_options.allow_quoted_newlines
          encoding              = each.value.external_data_configuration.csv_options.encoding
          field_delimiter       = each.value.external_data_configuration.csv_options.field_delimiter
          skip_leading_rows     = each.value.external_data_configuration.csv_options.skip_leading_rows
        }
      }
      dynamic "json_options" {
        for_each = each.value.external_data_configuration.json_options_encoding != null ? [""] : []
        content {
          encoding = each.value.external_data_configuration.json_options_encoding
        }
      }
      dynamic "google_sheets_options" {
        for_each = each.value.external_data_configuration.google_sheets_options != null ? [""] : []
        content {
          range             = each.value.external_data_configuration.google_sheets_options.range
          skip_leading_rows = each.value.external_data_configuration.google_sheets_options.skip_leading_rows
        }
      }
      dynamic "hive_partitioning_options" {
        for_each = each.value.external_data_configuration.hive_partitioning_options != null ? [""] : []
        content {
          mode                     = each.value.external_data_configuration.hive_partitioning_options.mode
          require_partition_filter = each.value.external_data_configuration.hive_partitioning_options.require_partition_filter
          source_uri_prefix        = each.value.external_data_configuration.hive_partitioning_options.source_uri_prefix
        }
      }
      dynamic "parquet_options" {
        for_each = each.value.external_data_configuration.parquet_options != null ? [""] : []
        content {
          enum_as_string        = each.value.external_data_configuration.parquet_options.enum_as_string
          enable_list_inference = each.value.external_data_configuration.parquet_options.enable_list_inference
        }
      }
    }
  }

  dynamic "table_constraints" {
    for_each = each.value.table_constraints != null ? [""] : []
    content {
      dynamic "primary_key" {
        for_each = each.value.table_constraints.primary_key_columns != null ? [""] : []
        content {
          columns = each.value.table_constraints.primary_key_columns
        }
      }
      dynamic "foreign_keys" {
        for_each = each.value.table_constraints.foreign_keys != null ? [""] : []
        content {
          name = each.value.table_constraints.foreign_keys.name
          referenced_table {
            project_id = each.value.table_constraints.foreign_keys.referenced_table.project_id
            dataset_id = each.value.table_constraints.foreign_keys.referenced_table.dataset_id
            table_id   = each.value.table_constraints.foreign_keys.referenced_table.table_id
          }
          column_references {
            referencing_column = each.value.table_constraints.foreign_keys.column_references.referencing_column
            referenced_column  = each.value.table_constraints.foreign_keys.column_references.referenced_column
          }
        }
      }
    }
  }

  dynamic "range_partitioning" {
    for_each = try(each.value.partitioning.range, null) != null ? [""] : []
    content {
      field = each.value.partitioning.field
      range {
        start    = each.value.partitioning.range.start
        end      = each.value.partitioning.range.end
        interval = each.value.partitioning.range.interval
      }
    }
  }

  dynamic "time_partitioning" {
    for_each = try(each.value.partitioning.time, null) != null ? [""] : []
    content {
      expiration_ms = each.value.partitioning.time.expiration_ms
      field         = each.value.partitioning.time.field
      type          = each.value.partitioning.time.type
    }
  }
}

resource "google_bigquery_table" "views" {
  depends_on          = [google_bigquery_table.default]
  for_each            = var.views
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = each.key
  friendly_name       = each.value.friendly_name
  description         = each.value.description
  labels              = each.value.labels
  deletion_protection = each.value.deletion_protection

  view {
    query          = each.value.query
    use_legacy_sql = each.value.use_legacy_sql
  }
}

resource "google_bigquery_table" "materialized_view" {
  depends_on               = [google_bigquery_table.default]
  for_each                 = var.materialized_views
  project                  = var.project_id
  dataset_id               = google_bigquery_dataset.default.dataset_id
  table_id                 = each.key
  friendly_name            = each.value.friendly_name
  description              = each.value.description
  labels                   = each.value.labels
  clustering               = each.value.options.clustering
  expiration_time          = each.value.options.expiration_time
  deletion_protection      = each.value.deletion_protection
  require_partition_filter = each.value.require_partition_filter

  dynamic "range_partitioning" {
    for_each = try(each.value.partitioning.range, null) != null ? [""] : []
    content {
      field = each.value.partitioning.field
      range {
        start    = each.value.partitioning.range.start
        end      = each.value.partitioning.range.end
        interval = each.value.partitioning.range.interval
      }
    }
  }

  dynamic "time_partitioning" {
    for_each = try(each.value.partitioning.time, null) != null ? [""] : []
    content {
      expiration_ms = each.value.partitioning.time.expiration_ms
      field         = each.value.partitioning.time.field
      type          = each.value.partitioning.time.type
    }
  }

  materialized_view {
    query                            = each.value.query
    enable_refresh                   = each.value.enable_refresh
    refresh_interval_ms              = each.value.refresh_interval_ms
    allow_non_incremental_definition = each.value.allow_non_incremental_definition
  }
}

resource "google_bigquery_routine" "default" {
  for_each             = var.routines
  project              = var.project_id
  dataset_id           = google_bigquery_dataset.default.dataset_id
  routine_id           = each.key
  description          = each.value.description
  routine_type         = each.value.routine_type
  language             = each.value.language
  definition_body      = each.value.definition_body
  imported_libraries   = each.value.imported_libraries
  determinism_level    = each.value.determinism_level
  data_governance_type = each.value.data_governance_type
  return_table_type    = each.value.return_table_type
  dynamic "arguments" {
    for_each = each.value.arguments
    content {
      name          = arguments.key
      argument_kind = arguments.value.argument_kind
      mode          = arguments.value.mode
      data_type     = arguments.value.data_type
    }
  }
  dynamic "spark_options" {
    for_each = each.value.spark_options == null ? [] : [""]
    content {
      connection      = each.value.spark_options.connection
      runtime_version = each.value.spark_options.runtime_version
      container_image = each.value.spark_options.container_image
      properties      = each.value.spark_options.properties
      main_file_uri   = each.value.spark_options.main_file_uri
      py_file_uris    = each.value.spark_options.py_file_uris
      jar_uris        = each.value.spark_options.jar_uris
      file_uris       = each.value.spark_options.file_uris
      archive_uris    = each.value.spark_options.archive_uris
      main_class      = each.value.spark_options.main_class
    }
  }
  dynamic "remote_function_options" {
    for_each = each.value.remote_function_options == null ? [] : [""]
    content {
      endpoint             = each.value.remote_function_options.endpoint
      connection           = each.value.remote_function_options.connection
      max_batching_rows    = each.value.remote_function_options.value.max_batching_rows
      user_defined_context = each.value.remote_function_options.user_defined_context
    }
  }
}
