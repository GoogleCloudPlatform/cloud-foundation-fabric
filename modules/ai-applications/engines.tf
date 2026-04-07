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

resource "google_discovery_engine_chat_engine" "default" {
  count         = var.engines_configs.chat_engine_config == null ? 0 : 1
  engine_id     = var.name
  display_name  = var.name
  collection_id = var.engines_configs.collection_id
  project       = var.project_id
  data_store_ids = [
    for ds in var.engines_configs.data_store_ids
    : coalesce(
      try(google_discovery_engine_data_store.default[ds].data_store_id, null),
      ds
    )
  ]
  industry_vertical = coalesce(
    try(var.engines_configs.industry_vertical, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].industry_vertical, null),
    "GENERIC"
  )
  location = coalesce(
    try(var.engines_configs.location, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].location, null),
    var.location
  )

  chat_engine_config {
    allow_cross_region = var.engines_configs.chat_engine_config.allow_cross_region
    dialogflow_agent_to_link = try(
      coalesce(
        var.engines_configs.chat_engine_config.agent_config.id,
        google_dialogflow_cx_agent.default[0].id
      ),
      null
    )
  }

  dynamic "common_config" {
    for_each = (
      var.engines_configs.chat_engine_config.company_name == null
      ? [] : [""]
    )

    content {
      company_name = var.engines_configs.chat_engine_config.company_name
    }
  }
}

resource "google_discovery_engine_search_engine" "default" {
  count         = var.engines_configs.search_engine_config == null ? 0 : 1
  engine_id     = var.name
  display_name  = var.name
  collection_id = var.engines_configs.collection_id
  project       = var.project_id
  data_store_ids = [
    for ds in var.engines_configs.data_store_ids
    : coalesce(
      try(google_discovery_engine_data_store.default[ds].data_store_id, null),
      ds
    )
  ]
  industry_vertical = coalesce(
    try(var.engines_configs.industry_vertical, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].industry_vertical, null),
    "GENERIC"
  )
  location = coalesce(
    try(var.engines_configs.location, null),
    try(google_discovery_engine_data_store.default[var.engines_configs.data_store_ids[0]].location, null),
    var.location
  )
  search_engine_config {
    search_add_ons = var.engines_configs.search_engine_config.search_add_ons
    search_tier    = var.engines_configs.search_engine_config.search_tier
  }
}
