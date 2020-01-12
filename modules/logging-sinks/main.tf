/**
 * Copyright 2019 Google LLC
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
  bigquery_destinations = {
    for name, destination in var.destinations :
    name => substr(destination, 0, 8) == "bigquery"
  }
  resource_type = element(split("/", var.parent), 0)
  resource_id   = element(split("/", var.parent), 1)
  sink_options = {
    for name, _ in var.sinks :
    name => lookup(var.sink_options, name, var.default_options)
  }
  sink_resources = concat(
    [for _, sink in google_logging_organization_sink.sinks : sink],
    [for _, sink in google_logging_billing_account_sink.sinks : sink],
    [for _, sink in google_logging_folder_sink.sinks : sink],
    [for _, sink in google_logging_project_sink.sinks : sink],
  )
}

resource "google_logging_organization_sink" "sinks" {
  for_each         = local.resource_type == "organizations" ? var.sinks : {}
  name             = each.key
  org_id           = local.resource_id
  filter           = each.value
  destination      = var.destinations[each.key]
  include_children = local.sink_options[each.key].include_children
  dynamic bigquery_options {
    for_each = local.bigquery_destinations[each.key] ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = local.sink_options[each.key].bigquery_partitioned_tables
    }
  }
}

resource "google_logging_billing_account_sink" "sinks" {
  for_each        = local.resource_type == "billing_accounts" ? var.sinks : {}
  name            = each.key
  billing_account = local.resource_id
  filter          = each.value
  destination     = var.destinations[each.key]
  dynamic bigquery_options {
    for_each = local.bigquery_destinations[each.key] ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = local.sink_options[each.key].bigquery_partitioned_tables
    }
  }
}

resource "google_logging_folder_sink" "sinks" {
  for_each         = local.resource_type == "folders" ? var.sinks : {}
  name             = each.key
  folder           = var.parent
  filter           = each.value
  destination      = var.destinations[each.key]
  include_children = local.sink_options[each.key].include_children
  dynamic bigquery_options {
    for_each = local.bigquery_destinations[each.key] ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = local.sink_options[each.key].bigquery_partitioned_tables
    }
  }
}

resource "google_logging_project_sink" "sinks" {
  for_each               = local.resource_type == "projects" ? var.sinks : {}
  name                   = each.key
  project                = local.resource_id
  filter                 = each.value
  destination            = var.destinations[each.key]
  unique_writer_identity = local.sink_options[each.key].unique_writer_identity
  dynamic bigquery_options {
    for_each = local.bigquery_destinations[each.key] ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = local.sink_options[each.key].bigquery_partitioned_tables
    }
  }
}
