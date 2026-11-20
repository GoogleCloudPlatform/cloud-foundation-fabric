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

# tfdoc:file:description Native Discovery Engine data stores and schemas.

locals {
  data_stores = {
    for k, v in var.data_stores : k => merge(v, {
      data_store_id = coalesce(v.data_store_id, "${local.prefix}${k}")
      json_schema_normalized = (
        v.json_schema == null
        ? null
        : jsonencode(jsondecode(
          fileexists(pathexpand(v.json_schema))
          ? file(pathexpand(v.json_schema))
          : v.json_schema
        ))
      )
      kms_key_name = (
        v.kms_key == null
        ? null
        : lookup(local.ctx.kms_keys, v.kms_key, v.kms_key)
      )
    })
  }
  data_stores_with_schema = {
    for k, v in local.data_stores : k => v if v.json_schema_normalized != null
  }
}

resource "google_discovery_engine_data_store" "default" {
  for_each          = local.data_stores
  project           = local.project_id
  location          = local.location
  data_store_id     = each.value.data_store_id
  display_name      = coalesce(each.value.display_name, each.value.data_store_id)
  industry_vertical = each.value.industry_vertical
  content_config    = each.value.content_config
  solution_types    = each.value.solution_types
  acl_enabled       = each.value.acl_enabled
  deletion_policy   = local.deletion_policy
  kms_key_name      = each.value.kms_key_name
  skip_default_schema_creation = coalesce(
    each.value.skip_default_schema_creation,
    each.value.json_schema_normalized != null
  )

  dynamic "document_processing_config" {
    for_each = each.value.document_processing_config == null ? [] : [""]

    content {
      dynamic "chunking_config" {
        for_each = (
          try(each.value.document_processing_config.chunking_config, null) == null
          ? [] : [""]
        )

        content {
          dynamic "layout_based_chunking_config" {
            for_each = (
              try(
                each.value.document_processing_config.chunking_config.layout_based_chunking_config,
                null
              ) == null
              ? [] : [""]
            )

            content {
              chunk_size = (
                each.value.document_processing_config.chunking_config.layout_based_chunking_config.chunk_size
              )
              include_ancestor_headings = (
                each.value.document_processing_config.chunking_config.layout_based_chunking_config.include_ancestor_headings
              )
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
              try(
                each.value.document_processing_config.default_parsing_config.digital_parsing_config,
                null
              ) == true
              ? [""] : []
            )

            content {}
          }

          dynamic "layout_parsing_config" {
            for_each = (
              try(
                each.value.document_processing_config.default_parsing_config.layout_parsing_config,
                null
              ) == null
              ? []
              : [each.value.document_processing_config.default_parsing_config.layout_parsing_config]
            )

            content {
              enable_get_processed_document = layout_parsing_config.value.enable_get_processed_document
              enable_image_annotation       = layout_parsing_config.value.enable_image_annotation
              enable_llm_layout_parsing     = layout_parsing_config.value.enable_llm_layout_parsing
              enable_table_annotation       = layout_parsing_config.value.enable_table_annotation
              exclude_html_classes          = layout_parsing_config.value.exclude_html_classes
              exclude_html_elements         = layout_parsing_config.value.exclude_html_elements
              exclude_html_ids              = layout_parsing_config.value.exclude_html_ids
              structured_content_types      = layout_parsing_config.value.structured_content_types
            }
          }

          dynamic "ocr_parsing_config" {
            for_each = (
              try(
                each.value.document_processing_config.default_parsing_config.ocr_parsing_config,
                null
              ) == null
              ? [] : [""]
            )

            content {
              use_native_text = (
                each.value.document_processing_config.default_parsing_config.ocr_parsing_config.use_native_text
              )
            }
          }
        }
      }

      dynamic "parsing_config_overrides" {
        for_each = coalesce(
          each.value.document_processing_config.parsing_config_overrides, {}
        )

        content {
          file_type = parsing_config_overrides.key

          dynamic "digital_parsing_config" {
            for_each = (
              parsing_config_overrides.value.digital_parsing_config == true
              ? [""] : []
            )

            content {}
          }

          dynamic "layout_parsing_config" {
            for_each = (
              parsing_config_overrides.value.layout_parsing_config == null
              ? []
              : [parsing_config_overrides.value.layout_parsing_config]
            )

            content {
              enable_get_processed_document = layout_parsing_config.value.enable_get_processed_document
              enable_image_annotation       = layout_parsing_config.value.enable_image_annotation
              enable_llm_layout_parsing     = layout_parsing_config.value.enable_llm_layout_parsing
              enable_table_annotation       = layout_parsing_config.value.enable_table_annotation
              exclude_html_classes          = layout_parsing_config.value.exclude_html_classes
              exclude_html_elements         = layout_parsing_config.value.exclude_html_elements
              exclude_html_ids              = layout_parsing_config.value.exclude_html_ids
              structured_content_types      = layout_parsing_config.value.structured_content_types
            }
          }

          dynamic "ocr_parsing_config" {
            for_each = (
              parsing_config_overrides.value.ocr_parsing_config == null
              ? [] : [""]
            )

            content {
              use_native_text = parsing_config_overrides.value.ocr_parsing_config.use_native_text
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for app_id in each.value.app_ids : contains(keys(var.apps), app_id)
      ])
      error_message = "Data store '${each.key}' references an app_id in app_ids that is not in var.apps."
    }
  }

  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
    google_discovery_engine_user_store.default,
  ]

  # Discovery Engine rejects deleting a DataStore while it is still listed on
  # an Engine. Detach it from any referencing engine before destruction.
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      endpoint="https://${self.location == "global" ? "" : "${self.location}-"}discoveryengine.googleapis.com/v1"
      ds_id="${self.data_store_id}"
      token="$(gcloud auth print-access-token)"
      lockdir="/tmp/ge-mcp-detach-${self.project}-${self.location}.lock"
      body=$(mktemp)
      resp=$(mktemp)

      while ! mkdir "$lockdir" 2>/dev/null; do
        sleep 1
      done
      trap 'rmdir "$lockdir" 2>/dev/null || true; rm -f "$body" "$resp"' EXIT

      engines_url="$endpoint/projects/${self.project}/locations/${self.location}/collections/default_collection/engines"
      status=$(curl -sS \
        -H "Authorization: Bearer $token" \
        -H "X-Goog-User-Project: ${self.project}" \
        -o "$body" -w '%%{http_code}' \
        "$engines_url")

      if [[ "$status" == "404" ]]; then
        exit 0
      fi
      if [[ "$status" != 2* ]]; then
        echo "Failed to list Discovery Engine apps while detaching $ds_id (HTTP $status)" >&2
        cat "$body" >&2
        exit 1
      fi

      engines=$(jq -r --arg ds "$ds_id" '.engines[]? | select((.dataStoreIds // []) | index($ds)) | .name' "$body")
      for engine in $engines; do
        payload=$(jq -c --arg eng "$engine" --arg ds "$ds_id" \
          '.engines[] | select(.name == $eng) | ((.dataStoreIds // []) - [$ds]) as $rem | {dataStoreIds: (if ($rem | length) == 1 then [] else $rem end)}' "$body")
        patch_status=$(curl -sS -X PATCH \
          -H "Authorization: Bearer $token" \
          -H "Content-Type: application/json" \
          -H "X-Goog-User-Project: ${self.project}" \
          -d "$payload" \
          -o "$resp" -w '%%{http_code}' \
          "$endpoint/$engine?updateMask=dataStoreIds")
        if [[ "$patch_status" != 2* && "$patch_status" != "404" ]]; then
          echo "Failed to detach $ds_id from $engine (HTTP $patch_status)" >&2
          cat "$resp" >&2
          exit 1
        fi
      done
    EOT
  }
}

resource "google_discovery_engine_schema" "default" {
  for_each        = local.data_stores_with_schema
  project         = local.project_id
  location        = google_discovery_engine_data_store.default[each.key].location
  data_store_id   = google_discovery_engine_data_store.default[each.key].data_store_id
  schema_id       = each.value.schema_id
  json_schema     = each.value.json_schema_normalized
  deletion_policy = local.deletion_policy
}
