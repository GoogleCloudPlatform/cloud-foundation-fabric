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

locals {
  # chat engine yaml defaults
  agent_builder_chat_engines = coalesce({
    for k, v in local.app.agent_builder.chat_engines : k => {
      engine_id         = k
      collection_id     = lookup(v, "collection_id", "default_collection")
      location          = lookup(v, "location", "eu")
      display_name      = lookup(v, "display_name", "sample chat engine")
      industry_vertical = lookup(v, "industry_vertical", "GENERIC")
      data_store_ids    = lookup(v, "data_store_ids", [])

      common_config = lookup(v, "common_config", null) == null ? null : {
        company_name = lookup(v, "company_name", null)
      }

      chat_engine_config = (
        try(v.chat_engine_config.dialogflow_agent_to_link, null) == null ? {
          dialogflow_agent_to_link = null
          agent_creation_config = {
            business              = try(v.chat_engine_config.agent_creation_config.business, null)
            default_language_code = try(v.chat_engine_config.agent_creation_config.default_language_code, "en")
            time_zone             = try(v.chat_engine_config.agent_creation_config.time_zone, "Europe/London")
            location              = try(v.chat_engine_config.agent_creation_config.location, null)
          }
          } : {
          agent_creation_config    = null
          dialogflow_agent_to_link = v.chat_engine_config.dialogflow_agent_to_link
        }
      )
    }
  }, try(var.agent_builder.chat_engines, null))
}

resource "google_discovery_engine_chat_engine" "chat_engines" {
  for_each          = local.agent_builder_chat_engines
  engine_id         = each.key
  project           = var.project_id
  collection_id     = each.value.collection_id
  location          = each.value.location
  display_name      = each.value.display_name
  industry_vertical = each.value.industry_vertical
  data_store_ids = ([
    for data_store_id in each.value.data_store_ids
    : try(
      google_discovery_engine_data_store.data_stores[data_store_id].data_store_id,
      data_store_id
    )
  ])

  dynamic "common_config" {
    for_each = each.value.common_config == null ? [] : [""]
    content {
      company_name = each.value.common_config.company_name
    }
  }

  chat_engine_config {
    dialogflow_agent_to_link = each.value.chat_engine_config.dialogflow_agent_to_link
    dynamic "agent_creation_config" {
      for_each = each.value.chat_engine_config.agent_creation_config == null ? [] : [""]
      content {
        business              = each.value.chat_engine_config.agent_creation_config.business
        default_language_code = each.value.chat_engine_config.agent_creation_config.default_language_code
        location              = each.value.chat_engine_config.agent_creation_config.location
        time_zone             = each.value.chat_engine_config.agent_creation_config.time_zone
      }
    }
  }
}
