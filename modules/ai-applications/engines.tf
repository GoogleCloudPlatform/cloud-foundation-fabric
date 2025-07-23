/**
 * Copyright 2025 Google LLC
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
  for_each = ({
    for k, v in var.engines_configs
    : k => v if v.chat_engine_config != null
  })
  engine_id     = "${var.name}-${each.key}"
  display_name  = "${var.name}-${each.key}"
  collection_id = each.value.collection_id
  project       = var.project_id
  data_store_ids = [
    for ds in each.value.data_store_ids
    : coalesce(
      try(google_discovery_engine_data_store.default[ds].data_store_id, null),
      ds
    )
  ]
  industry_vertical = coalesce(
    try(each.value.industry_vertical, null),
    try(google_discovery_engine_data_store.default[each.value.data_store_ids[0]].industry_vertical, null)
  )
  location = coalesce(
    try(each.value.location, null),
    try(google_discovery_engine_data_store.default[each.value.data_store_ids[0]].location, null),
    var.location
  )

  chat_engine_config {
    allow_cross_region       = each.value.chat_engine_config.allow_cross_region
    dialogflow_agent_to_link = each.value.chat_engine_config.dialogflow_agent_to_link

    agent_creation_config {
      business              = each.value.chat_engine_config.business
      default_language_code = each.value.chat_engine_config.default_language_code
      time_zone             = each.value.chat_engine_config.time_zone
      location = coalesce(
        try(each.value.location, null),
        try(google_discovery_engine_data_store.default[each.value.data_store_ids[0]].location, null),
        var.location
      )
    }
  }

  dynamic "common_config" {
    for_each = each.value.chat_engine_config.company_name == null ? [] : [""]

    content {
      company_name = each.value.chat_engine_config.company_name
    }
  }
}

resource "google_discovery_engine_search_engine" "default" {
  for_each = ({
    for k, v in var.engines_configs
    : k => v if v.search_engine_config != null
  })
  engine_id     = "${var.name}-${each.key}"
  display_name  = "${var.name}-${each.key}"
  collection_id = each.value.collection_id
  project       = var.project_id
  data_store_ids = [
    for ds in each.value.data_store_ids
    : coalesce(
      try(google_discovery_engine_data_store.default[ds].data_store_id, null),
      ds
    )
  ]
  industry_vertical = coalesce(
    try(each.value.industry_vertical, null),
    try(google_discovery_engine_data_store.default[each.value.data_store_ids[0]].industry_vertical, null)
  )
  location = coalesce(
    try(each.value.location, null),
    try(google_discovery_engine_data_store.default[each.value.data_store_ids[0]].location, null),
    var.location
  )

  search_engine_config {
    search_add_ons = each.value.search_engine_config.search_add_ons
    search_tier    = each.value.search_engine_config.search_tier
  }
}
