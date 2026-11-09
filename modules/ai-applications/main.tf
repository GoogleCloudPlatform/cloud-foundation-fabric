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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p = "$"
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
  location   = lookup(local.ctx.locations, var.location, var.location)
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
}

resource "google_discovery_engine_cmek_config" "default" {
  for_each       = var.encryption_configs
  project        = local.project_id
  location       = lookup(local.ctx.locations, each.key, each.key)
  cmek_config_id = var.name
  kms_key = lookup(
    local.ctx.kms_keys, each.value.kms_key, each.value.kms_key
  )
  set_default = each.value.set_default

  dynamic "single_region_keys" {
    for_each = each.value.single_region_keys

    content {
      kms_key = lookup(
        local.ctx.kms_keys, single_region_keys.value, single_region_keys.value
      )
    }
  }
}

resource "google_discovery_engine_data_store" "default" {
  for_each      = var.data_stores_configs
  data_store_id = "${var.name}-${each.key}"
  project       = local.project_id
  location = (
    each.value.location == null
    ? local.location
    : lookup(local.ctx.locations, each.value.location, each.value.location)
  )
  industry_vertical            = each.value.industry_vertical
  content_config               = each.value.content_config
  solution_types               = each.value.solution_types
  create_advanced_site_search  = each.value.create_advanced_site_search
  skip_default_schema_creation = each.value.skip_default_schema_creation
  kms_key_name = (
    each.value.kms_key == null
    ? null
    : lookup(local.ctx.kms_keys, each.value.kms_key, each.value.kms_key)
  )
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

  # CMEK has to be registered before data stores are created
  depends_on = [google_discovery_engine_cmek_config.default]
}

resource "google_discovery_engine_schema" "default" {
  for_each = ({
    for k, v in var.data_stores_configs
    : k => v if try(v.json_schema, null) != null
  })
  schema_id     = "${var.name}-${each.key}"
  project       = local.project_id
  location      = google_discovery_engine_data_store.default[each.key].location
  data_store_id = google_discovery_engine_data_store.default[each.key].data_store_id
  json_schema   = each.value.json_schema
}

resource "google_discovery_engine_sitemap" "default" {
  for_each = ({
    for k, v in var.data_stores_configs
    : k => v if try(v.sites_search_config.sitemap_uri, null) != null
  })
  project       = local.project_id
  location      = google_discovery_engine_data_store.default[each.key].location
  data_store_id = google_discovery_engine_data_store.default[each.key].data_store_id
  uri           = each.value.sites_search_config.sitemap_uri
}

resource "google_discovery_engine_target_site" "default" {
  for_each             = local.data_stores_target_sites
  project              = local.project_id
  location             = google_discovery_engine_data_store.default[each.value.data_store_id].location
  data_store_id        = google_discovery_engine_data_store.default[each.value.data_store_id].data_store_id
  provided_uri_pattern = each.value.provided_uri_pattern
  type                 = each.value.type
  exact_match          = each.value.exact_match
}

resource "google_discovery_engine_acl_config" "default" {
  count    = var.acl_config == null ? 0 : 1
  project  = local.project_id
  location = local.location

  idp_config {
    idp_type = var.acl_config.idp_type

    dynamic "external_idp_config" {
      for_each = var.acl_config.idp_type == "THIRD_PARTY" ? [""] : []

      content {
        workforce_pool_name = var.acl_config.workforce_pool_name
      }
    }
  }
}

resource "google_discovery_engine_license_config" "default" {
  count             = try(var.license_config.create_free_trial, false) ? 1 : 0
  project           = local.project_id
  location          = local.location
  license_config_id = var.license_config.license_config_id
  license_count     = var.license_config.license_count
  subscription_tier = var.license_config.subscription_tier
  subscription_term = var.license_config.subscription_term
  free_trial        = true

  start_date {}

  lifecycle {
    ignore_changes = [
      start_date,
      end_date,
      license_count,
    ]
  }
}

resource "google_discovery_engine_user_store" "default" {
  count         = var.license_config == null ? 0 : 1
  project       = local.project_id
  location      = local.location
  user_store_id = "default_user_store"
  default_license_config = coalesce(
    var.license_config.license_config_name,
    try(google_discovery_engine_license_config.default[0].name, null)
  )
  enable_license_auto_register       = var.license_config.enable_license_auto_register
  enable_expired_license_auto_update = var.license_config.enable_expired_license_auto_update

  depends_on = [google_discovery_engine_license_config.default]
}

resource "google_discovery_engine_data_connector" "default" {
  for_each = var.data_connectors_configs
  project  = local.project_id
  location = (
    each.value.location == null
    ? local.location
    : lookup(local.ctx.locations, each.value.location, each.value.location)
  )
  collection_id           = coalesce(each.value.collection_id, "${var.name}-${each.key}")
  collection_display_name = each.value.collection_display_name
  data_source             = each.value.data_source
  kms_key_name = (
    each.value.kms_key == null
    ? null
    : lookup(local.ctx.kms_keys, each.value.kms_key, each.value.kms_key)
  )
  refresh_interval  = each.value.refresh_interval
  connector_modes   = each.value.connector_modes
  sync_mode         = each.value.sync_mode
  auto_run_disabled = each.value.auto_run_disabled
  params            = each.value.params
  json_params       = each.value.json_params

  dynamic "destination_configs" {
    for_each = each.value.destination_configs

    content {
      key    = destination_configs.value.key
      params = destination_configs.value.params

      dynamic "destinations" {
        for_each = destination_configs.value.destinations

        content {
          host = destinations.value.host
          port = destinations.value.port
        }
      }
    }
  }

  dynamic "action_config" {
    for_each = each.value.action_config == null ? [] : [""]

    content {
      create_bap_connection = each.value.action_config.create_bap_connection
      action_params         = each.value.action_config.action_params
    }
  }

  dynamic "bap_config" {
    for_each = each.value.bap_config == null ? [] : [""]

    content {
      supported_connector_modes = each.value.bap_config.supported_connector_modes
      enabled_actions           = each.value.bap_config.enabled_actions
    }
  }

  dynamic "entities" {
    for_each = each.value.entities

    content {
      entity_name           = entities.value.entity_name
      data_store            = entities.value.data_store
      params                = entities.value.params
      key_property_mappings = entities.value.key_property_mappings
    }
  }

  lifecycle {
    ignore_changes = [
      entities,
      kms_key_name,
      bap_config,
      action_config,
      destination_configs,
      json_params,
      params,
    ]
  }

  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
  ]
}
