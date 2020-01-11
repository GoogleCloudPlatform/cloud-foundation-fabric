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
  sinks = [
    for sink in var.sinks : merge(
      sink,
      zipmap(["resource_type", "resource_id"], split("/", sink.resource)),
      {
        to_bigquery = substr(sink.destination, 0, 8) == "bigquery",
        options     = sink.options == null ? {} : sink.options
      }
    )
  ]
  sink_resources = concat(
    [for _, sink in google_logging_organization_sink.sinks : sink],
    [for _, sink in google_logging_billing_account_sink.sinks : sink],
    [for _, sink in google_logging_folder_sink.sinks : sink],
    [for _, sink in google_logging_project_sink.sinks : sink],
  )
}

resource "google_logging_organization_sink" "sinks" {
  for_each = {
    for sink in local.sinks :
    "${sink.resource}/${sink.name}" => sink if sink.resource_type == "organizations"
  }
  name             = each.value.name
  org_id           = each.value.resource_id
  filter           = each.value.filter
  destination      = each.value.destination
  include_children = lookup(each.value.options, "include_children", true)
  dynamic bigquery_options {
    for_each = each.value.to_bigquery ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = lookup(
        each.value.options, "bigquery_partitioned_tables", true
      )
    }
  }
}

resource "google_logging_billing_account_sink" "sinks" {
  for_each = {
    for sink in local.sinks :
    "${sink.resource}/${sink.name}" => sink if sink.resource_type == "billing_accounts"
  }
  name            = each.value.name
  billing_account = each.value.resource_id
  filter          = each.value.filter
  destination     = each.value.destination
  dynamic bigquery_options {
    for_each = each.value.to_bigquery ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = lookup(
        each.value.options, "bigquery_partitioned_tables", true
      )
    }
  }
}

resource "google_logging_folder_sink" "sinks" {
  for_each = {
    for sink in local.sinks :
    "${sink.resource}/${sink.name}" => sink if sink.resource_type == "folders"
  }
  name             = each.value.name
  folder           = each.value.resource
  filter           = each.value.filter
  destination      = each.value.destination
  include_children = lookup(each.value.options, "include_children", true)
  dynamic bigquery_options {
    for_each = each.value.to_bigquery ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = lookup(
        each.value.options, "bigquery_partitioned_tables", true
      )
    }
  }
}

resource "google_logging_project_sink" "sinks" {
  for_each = {
    for sink in local.sinks :
    "${sink.resource}/${sink.name}" => sink if sink.resource_type == "projects"
  }
  name                   = each.value.name
  project                = each.value.resource_id
  filter                 = each.value.filter
  destination            = each.value.destination
  unique_writer_identity = lookup(each.value.options, "unique_writer_identity", false)
  dynamic bigquery_options {
    for_each = each.value.to_bigquery ? ["1"] : []
    iterator = config
    content {
      use_partitioned_tables = lookup(
        each.value.options, "bigquery_partitioned_tables", true
      )
    }
  }
}
