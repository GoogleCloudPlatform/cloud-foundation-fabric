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
  data_stores_target_sites = {
    for item in flatten([
      for data_store_id, data_store_config in var.data_stores_configs :
      [
        for target_site_key, target_site_config in try(
        data_store_config.sites_search_config.target_sites, {}) :
        merge({
          key           = "${data_store_id}-${target_site_key}"
          data_store_id = data_store_id
        }, target_site_config)
      ]
    ]) : item.key => item
  }
}

resource "google_discovery_engine_data_store" "default" {
  for_each                     = var.data_stores_configs
  data_store_id                = "${var.name}-${each.key}"
  project                      = var.project_id
  location                     = coalesce(each.value.location, var.location)
  industry_vertical            = each.value.industry_vertical
  content_config               = each.value.content_config
  solution_types               = each.value.solution_types
  create_advanced_site_search  = each.value.create_advanced_site_search
  skip_default_schema_creation = each.value.skip_default_schema_creation
  display_name = coalesce(
    each.value.display_name, "${var.name}-${each.key}"
  )

  dynamic "advanced_site_search_config" {
    for_each = (
      try(each.value.advanced_site_search_config, null) == null
      ? [] : [""]
    )

    content {
      disable_initial_index     = each.value.advanced_site_search_config.disable_initial_index
      disable_automatic_refresh = each.value.advanced_site_search_config.disable_automatic_refresh
    }
  }

  dynamic "document_processing_config" {
    for_each = (
      try(each.value.document_processing_config, null) == null
      ? [] : [""]
    )

    content {
      dynamic "chunking_config" {
        for_each = (
          try(each.value.document_processing_config.chunking_config, null) == null
          ? [] : [""]
        )

        content {
          dynamic "layout_based_chunking_config" {
            for_each = (
              try(each.value.document_processing_config.chunking_config.layout_based_chunking_config, null) == null
              ? [] : [""]
            )

            content {
              chunk_size                = each.value.document_processing_config.chunking_config.layout_based_chunking_config.chunk_size
              include_ancestor_headings = each.value.document_processing_config.chunking_config.layout_based_chunking_config.include_ancestor_headings
            }
          }
        }
      }

      dynamic "default_parsing_config" {
        for_each = (
          try(each.value.document_processing_config.default_parsing_config, null) == null
          ? [] : [""]
        )

        content {
          dynamic "digital_parsing_config" {
            for_each = (
              try(each.value.document_processing_config.default_parsing_config.digital_parsing_config, null) == null
              ? [] : [""]
            )

            content {}
          }

          dynamic "layout_parsing_config" {
            for_each = (
              try(each.value.document_processing_config.default_parsing_config.layout_parsing_config, null) == null
              ? [] : [""]
            )

            content {}
          }

          dynamic "ocr_parsing_config" {
            for_each = (
              try(each.value.document_processing_config.default_parsing_config.ocr_parsing_config, null) == null
              ? [] : [""]
            )

            content {
              use_native_text = each.value.document_processing_config.default_parsing_config.ocr_parsing_config.use_native_text
            }
          }
        }
      }

      dynamic "parsing_config_overrides" {
        for_each = coalesce(each.value.document_processing_config.parsing_config_overrides, {})

        content {
          file_type = parsing_config_overrides.key

          dynamic "digital_parsing_config" {
            for_each = (
              try(parsing_config_overrides.value["digital_parsing_config"], null) == null
              ? [] : [""]
            )

            content {}
          }

          dynamic "layout_parsing_config" {
            for_each = (
              try(parsing_config_overrides.value["layout_parsing_config"], null) == null
              ? [] : [""]
            )

            content {}
          }

          dynamic "ocr_parsing_config" {
            for_each = (
              try(parsing_config_overrides.value["ocr_parsing_config"], null) == null
              ? [] : [""]
            )

            content {
              use_native_text = parsing_config_overrides.value["ocr_parsing_config"]["use_native_text"]
            }
          }
        }
      }
    }
  }
}

resource "google_discovery_engine_schema" "default" {
  for_each = ({
    for k, v in var.data_stores_configs
    : k => v if try(v.json_schema, null) != null
  })
  schema_id     = "${var.name}-${each.key}"
  project       = var.project_id
  location      = google_discovery_engine_data_store.default[each.key].location
  data_store_id = google_discovery_engine_data_store.default[each.key].data_store_id
  json_schema   = each.value.json_schema
}

resource "google_discovery_engine_sitemap" "default" {
  for_each = ({
    for k, v in var.data_stores_configs
    : k => v if try(v.sites_search_config.sitemap_uri, null) != null
  })
  project       = var.project_id
  location      = google_discovery_engine_data_store.default[each.key].location
  data_store_id = google_discovery_engine_data_store.default[each.key].data_store_id
  uri           = each.value.sites_search_config.sitemap_uri
}

resource "google_discovery_engine_target_site" "default" {
  for_each             = local.data_stores_target_sites
  project              = var.project_id
  location             = google_discovery_engine_data_store.default[each.value.data_store_id].location
  data_store_id        = google_discovery_engine_data_store.default[each.value.data_store_id].data_store_id
  provided_uri_pattern = each.value.provided_uri_pattern
  type                 = each.value.type
  exact_match          = each.value.exact_match
}
