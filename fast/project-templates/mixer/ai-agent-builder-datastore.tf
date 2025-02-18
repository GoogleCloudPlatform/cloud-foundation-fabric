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
  # data stores yaml defaults
  agent_builder_data_stores = coalesce({
    for k, v in local.app.agent_builder.data_stores : k => {
      data_store_id                = k
      display_name                 = lookup(v, "display_name", "sample data store")
      location                     = lookup(v, "location", "eu")
      industry_vertical            = lookup(v, "industry_vertical", "GENERIC")
      content_config               = lookup(v, "content_config", "NO_CONTENT")
      solution_types               = lookup(v, "solution_types", ["SOLUTION_TYPE_CHAT"])
      create_advanced_site_search  = lookup(v, "create_advanced_site_search", false)
      skip_default_schema_creation = lookup(v, "skip_default_schema_creation", false)
      advanced_site_search_config = (
        lookup(v, "advanced_site_search_config", null) == null
        ? null
        : {
          disable_automatic_refresh = lookup(
            v.advanced_site_search_config, "disable_automatic_refresh",
            false
          )
          disable_initial_index = lookup(
            v.advanced_site_search_config, "disable_initial_index",
            false
          )
        }
      )
      document_processing_config = (
        lookup(v, "document_processing_config", null) == null
        ? null
        : {
          chunking_config = (
            lookup(v.document_processing_config, "chunking_config", null) == null
            ? null
            : {
              chunk_size                = lookup(v.document_processing_config.chunking_config, "chunk_size", 500)
              include_ancestor_headings = lookup(v.document_processing_config.chunking_config, "include_ancestor_headings", false)
            }
          )
          default_parsing_config = (
            lookup(v.document_processing_config, "default_parsing_config", null) == null
            ? null
            : {
              digital_parsing_config = lookup(v.document_processing_config.default_parsing_config, "digital_parsing_config", false)
              layout_parsing_config  = lookup(v.document_processing_config.default_parsing_config, "layout_parsing_config", false)
              ocr_parsing_config = (
                lookup(v.document_processing_config.default_parsing_config, "ocr_parsing_config", null) == null
                ? null
                : {
                  use_native_text = lookup(v.document_processing_config.default_parsing_config.ocr_parsing_config, "use_native_text", false)
                }
              )
            }
          )
          parsing_config_overrides = (
            lookup(v.document_processing_config, "parsing_config_overrides", null) == null
            ? null
            : [
              for override_rule in v.document_processing_config.parsing_config_overrides : {
                digital_parsing_config = lookup(v.document_processing_config.parsing_config_overrides, "digital_parsing_config", false)
                file_type              = lookup(v.document_processing_config.parsing_config_overrides, "digital_parsing_config", "pdf")
                layout_parsing_config  = lookup(v.document_processing_config.parsing_config_overrides, "layout_parsing_config", false)
                ocr_parsing_config = (
                  lookup(v.document_processing_config.parsing_config_overrides, "ocr_parsing_config", null) == null
                  ? null
                  : {
                    use_native_text = lookup(v.document_processing_config.parsing_config_overrides.ocr_parsing_config, "use_native_text", false)
                  }
                )
              }
            ]
          )
        }
      )
    }
  }, try(var.agent_builder.data_stores, null))
}

resource "google_discovery_engine_data_store" "data_stores" {
  for_each                     = local.agent_builder_data_stores
  data_store_id                = each.key
  display_name                 = each.value.display_name
  project                      = var.project_id
  location                     = each.value.location
  industry_vertical            = each.value.industry_vertical
  content_config               = each.value.content_config
  solution_types               = each.value.solution_types
  create_advanced_site_search  = each.value.create_advanced_site_search
  skip_default_schema_creation = each.value.skip_default_schema_creation

  dynamic "advanced_site_search_config" {
    for_each = each.value.advanced_site_search_config == null ? [] : [""]
    content {
      disable_automatic_refresh = (
        each.value.advanced_site_search_config.disable_automatic_refresh
      )
      disable_initial_index = (
        each.value.advanced_site_search_config.disable_initial_index
      )
    }
  }

  dynamic "document_processing_config" {
    for_each = each.value.document_processing_config == null ? [] : [""]
    content {
      dynamic "chunking_config" {
        for_each = try(each.value.document_processing_config.chunking_config, null) == null ? [] : [""]
        content {
          dynamic "layout_based_chunking_config" {
            for_each = each.value.document_processing_config.chunking_config.layout_based_chunking_config == null ? [] : [""]
            content {
              chunk_size                = each.value.document_processing_config.chunking_config.layout_based_chunking_config.chunk_size
              include_ancestor_headings = each.value.document_processing_config.chunking_config.layout_based_chunking_config.include_ancestor_headings
            }
          }
        }
      }
      dynamic "default_parsing_config" {
        for_each = try(each.value.document_processing_config.default_parsing_config, null) == null ? [] : [""]
        content {
          dynamic "digital_parsing_config" {
            for_each = each.value.document_processing_config.default_parsing_config.digital_parsing_config == null ? [] : [""]
            content {}
          }
          dynamic "layout_parsing_config" {
            for_each = each.value.document_processing_config.default_parsing_config.layout_parsing_config == null ? [] : [""]
            content {}
          }
          dynamic "ocr_parsing_config" {
            for_each = each.value.document_processing_config.default_parsing_config.ocr_parsing_config == null ? [] : [""]
            content {
              use_native_text = each.value.document_processing_config.default_parsing_config.ocr_parsing_config.use_native_text
            }
          }
        }
      }
      dynamic "parsing_config_overrides" {
        for_each = try(each.value.document_processing_config.parsing_config_overrides, [])
        content {
          file_type = each.value.document_processing_config.parsing_config_overrides.file_type
          dynamic "digital_parsing_config" {
            for_each = each.value.document_processing_config.parsing_config_overrides.digital_parsing_config == null ? [] : [""]
            content {}
          }
          dynamic "layout_parsing_config" {
            for_each = each.value.document_processing_config.parsing_config_overrides.layout_parsing_config == null ? [] : [""]
            content {}
          }
          dynamic "ocr_parsing_config" {
            for_each = each.value.document_processing_config.parsing_config_overrides.ocr_parsing_config == null ? [] : [""]
            content {
              use_native_text = each.value.document_processing_config.parsing_config_overrides.ocr_parsing_config.use_native_text
            }
          }
        }
      }
    }
  }
}
