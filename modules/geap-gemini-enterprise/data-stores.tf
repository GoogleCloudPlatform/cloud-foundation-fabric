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
          !startswith(trimspace(v.json_schema), "{")
          && !startswith(trimspace(v.json_schema), "[")
          && try(fileexists(pathexpand(v.json_schema)), false)
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
    for k, v in local.data_stores : k => v if v.json_schema != null
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
    each.value.json_schema != null
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
    environment = {
      DATA_STORE_IDS  = jsonencode([self.data_store_id])
      DELETION_POLICY = coalesce(self.deletion_policy, "DELETE")
      LOCATION        = self.location
      PROJECT         = self.project
    }
    command = <<-EOT
      set -euo pipefail

      if [[ "$DELETION_POLICY" != "DELETE" ]]; then
        exit 0
      fi

      host_prefix=""
      [[ "$LOCATION" != "global" ]] && host_prefix="$${LOCATION}-"
      v1_ep="https://$${host_prefix}discoveryengine.googleapis.com/v1"
      v1alpha_ep="https://$${host_prefix}discoveryengine.googleapis.com/v1alpha"

      if [[ -n "$${GOOGLE_OAUTH_ACCESS_TOKEN:-}" ]]; then
        token="$GOOGLE_OAUTH_ACCESS_TOKEN"
      elif [[ -n "$${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT:-}" ]]; then
        token="$(gcloud auth print-access-token --impersonate-service-account="$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT")"
      else
        token="$(gcloud auth print-access-token 2>/dev/null || gcloud auth application-default print-access-token)"
      fi
      quota_project="$${GOOGLE_BILLING_PROJECT:-$${CLOUDSDK_BILLING_QUOTA_PROJECT:-$PROJECT}}"

      hdr=$(mktemp)
      body=$(mktemp)
      resp=$(mktemp)
      chmod 600 "$hdr"
      printf 'header = "Authorization: Bearer %s"\nheader = "X-Goog-User-Project: %s"\n' "$token" "$quota_project" > "$hdr"

      lockbase="/tmp/ge-ds-sync-$${PROJECT}-$${LOCATION}"
      if command -v flock >/dev/null 2>&1; then
        exec 9>"$${lockbase}.lock"
        flock -w 300 9
        cleanup() { rm -f "$hdr" "$body" "$resp"; }
      else
        lockdir="$${lockbase}.lockdir"
        waited=0
        while ! mkdir "$lockdir" 2>/dev/null; do
          if [[ -f "$lockdir/pid" ]]; then
            holder=$(cat "$lockdir/pid" 2>/dev/null || true)
            if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then
              rm -rf "$lockdir"
              continue
            fi
          fi
          if (( waited >= 300 )); then
            echo "Timed out waiting for lock $lockdir" >&2
            exit 1
          fi
          sleep 1
          waited=$((waited + 1))
        done
        echo "$$" > "$lockdir/pid"
        cleanup() { rm -rf "$lockdir" "$hdr" "$body" "$resp"; }
      fi
      trap cleanup EXIT

      collections=("projects/$${PROJECT}/locations/$${LOCATION}/collections/default_collection")
      page_token=""
      while :; do
        col_url="$${v1alpha_ep}/projects/$${PROJECT}/locations/$${LOCATION}/collections"
        if [[ -n "$page_token" ]]; then
          col_url="$${col_url}?pageToken=$(jq -rn --arg t "$page_token" '$t | @uri')"
        fi
        status=$(curl -sS -K "$hdr" -o "$body" -w '%%{http_code}' "$col_url")
        [[ "$status" != 2* ]] && break
        while IFS= read -r col; do
          [[ -n "$col" && "$${col##*/}" != "default_collection" ]] && collections+=("$col")
        done < <(jq -r '.collections[]? | select(.dataConnector == null) | .name' "$body")
        page_token=$(jq -r '.nextPageToken // empty' "$body")
        [[ -z "$page_token" ]] && break
      done

      for col in "$${collections[@]}"; do
        page_token=""
        while :; do
          eng_url="$${v1_ep}/$${col}/engines"
          if [[ -n "$page_token" ]]; then
            eng_url="$${eng_url}?pageToken=$(jq -rn --arg t "$page_token" '$t | @uri')"
          fi
          status=$(curl -sS -K "$hdr" -o "$body" -w '%%{http_code}' "$eng_url")
          [[ "$status" == "404" ]] && break
          if [[ "$status" != 2* ]]; then
            echo "Failed to list Discovery Engine apps in $col (HTTP $status)" >&2
            cat "$body" >&2
            exit 1
          fi
          while IFS= read -r engine; do
            [[ -z "$engine" ]] && continue
            payload=$(jq -c --arg eng "$engine" --argjson targets "$DATA_STORE_IDS" \
              '.engines[] | select(.name == $eng) | ((.dataStoreIds // []) - $targets) as $rem | {dataStoreIds: (if ($rem | length) == 1 then [] else $rem end)}' "$body")
            patch_status=""
            for attempt in {1..5}; do
              patch_status=$(printf '%s' "$payload" | curl -sS -X PATCH -K "$hdr" \
                -H "Content-Type: application/json" \
                --data-binary @- \
                -o "$resp" -w '%%{http_code}' \
                "$${v1_ep}/$${engine}?updateMask=dataStoreIds")
              if [[ "$patch_status" == 2* || "$patch_status" == "404" ]]; then
                break
              fi
              if [[ "$patch_status" == 5* || "$patch_status" == "429" ]]; then
                sleep 2
                continue
              fi
              break
            done
            if [[ "$patch_status" != 2* && "$patch_status" != "404" ]]; then
              echo "Failed to detach stores from $engine (HTTP $patch_status)" >&2
              cat "$resp" >&2
              exit 1
            fi
          done < <(jq -r --argjson targets "$DATA_STORE_IDS" \
            '.engines[]? | select(any((.dataStoreIds // [])[]; . as $id | $targets | index($id))) | .name' "$body")
          page_token=$(jq -r '.nextPageToken // empty' "$body")
          [[ -z "$page_token" ]] && break
        done
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
