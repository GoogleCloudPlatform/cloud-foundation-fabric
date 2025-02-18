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

variable "agent_builder" {
  type = object({
    chat_engines = map(object({
      collection_id     = optional(string, "default_collection")
      location          = optional(string, "eu")
      display_name      = optional(string, "sample chat engine")
      industry_vertical = optional(string, "GENERIC")
      data_store_ids    = optional(list(string), [])
      common_config = optional(object({
        company_name = optional(string)
      }))
      chat_engine_config = optional(object({
        dialogflow_agent_to_link = optional(string)
        agent_creation_config = optional(object({
          business              = optional(string)
          default_language_code = optional(string, "en")
          time_zone             = optional(string, "Europe/London")
          location              = optional(string)
        }))
      }))
    }))
    data_stores = map(object({
      content_config               = optional(string, "NO_CONTENT")
      create_advanced_site_search  = optional(bool, false)
      display_name                 = optional(string, "sample data store")
      industry_vertical            = optional(string, "GENERIC")
      location                     = optional(string, "eu")
      solution_types               = optional(list(string), ["SOLUTION_TYPE_CHAT"])
      skip_default_schema_creation = optional(bool, false)
      advanced_site_search_config = optional(object({
        disable_automatic_refresh = optional(bool, false)
        disable_initial_index     = optional(bool, false)
      }))
      document_processing_config = optional(object({
        chunking_config = optional(object({
          chunk_size                = optional(number, 500)
          include_ancestor_headings = optional(bool, false)
        }))
        default_parsing_config = optional(object({
          digital_parsing_config = optional(bool, false)
          layout_parsing_config  = optional(bool, false)
          ocr_parsing_config = optional(object({
            use_native_text = optional(bool, false)
          }))
        }))
        defaultparsing_config_overrides = optional(object({
          digital_parsing_config = optional(bool, false)
          file_type              = optional(string, "pdf")
          layout_parsing_config  = optional(bool, false)
          ocr_parsing_config = optional(object({
            use_native_text = optional(bool, false)
          }))
        }))
      }))
    }))
  })
  default = null
}
