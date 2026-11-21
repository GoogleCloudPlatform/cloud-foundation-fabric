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

# tfdoc:file:description SaaS and Custom MCP Discovery Engine data connectors.

locals {
  _mcp_expanded = flatten([
    for k, v in var.mcp_connectors : [
      for item in(
        # When routing through an Egress Agent Gateway across multiple apps,
        # actionParams.agent_gateway_engine binds a single engine per connector,
        # so expand one connector instance per distinct target app.
        coalesce(
          v.use_agent_gateway_egress,
          anytrue([
            for app_id in distinct(v.app_ids) :
            try(local.apps[app_id].has_egress_gateway, var.egress_agent_gateway != null)
          ])
        ) && length(distinct(v.app_ids)) > 1
        ? [
          for app_id in distinct(v.app_ids) : {
            key           = "${k}/${app_id}"
            connector_key = k
            app_ids       = [app_id]
            primary_app   = app_id
            config        = v
            use_gateway = coalesce(
              v.use_agent_gateway_egress,
              try(local.apps[app_id].has_egress_gateway, var.egress_agent_gateway != null)
            )
            raw_collection_id = replace(
              "${coalesce(v.collection_id, "${local.prefix}${k}")}-${app_id}",
              "_",
              "-"
            )
          }
        ]
        : [
          {
            key           = k
            connector_key = k
            app_ids       = distinct(v.app_ids)
            primary_app   = try(distinct(v.app_ids)[0], null)
            config        = v
            use_gateway = coalesce(
              v.use_agent_gateway_egress,
              length(distinct(v.app_ids)) == 1 && try(
                local.apps[distinct(v.app_ids)[0]].has_egress_gateway,
                var.egress_agent_gateway != null
              )
            )
            raw_collection_id = replace(
              coalesce(v.collection_id, "${local.prefix}${k}"),
              "_",
              "-"
            )
          }
        ]
        ) : merge(item, {
          collection_id = (
            length(item.raw_collection_id) <= 54
            ? item.raw_collection_id
            : "${trimsuffix(substr(item.raw_collection_id, 0, 45), "-")}-${substr(md5(item.raw_collection_id), 0, 8)}"
          )
      })
    ]
  ])
  _mcp_oauth = {
    for item in local._mcp_expanded : item.key => (
      try(coalesce(item.config.oauth_config, var.oauth_config), null) == null
      ? null
      : merge(coalesce(item.config.oauth_config, var.oauth_config), {
        client_id = lookup(
          local.ctx.secrets,
          coalesce(item.config.oauth_config, var.oauth_config).client_id,
          coalesce(item.config.oauth_config, var.oauth_config).client_id
        )
        client_secret = (
          coalesce(item.config.oauth_config, var.oauth_config).client_secret == null
          ? null
          : lookup(
            local.ctx.secrets,
            coalesce(item.config.oauth_config, var.oauth_config).client_secret,
            coalesce(item.config.oauth_config, var.oauth_config).client_secret
          )
        )
      })
    )
  }
  data_connectors = {
    for k, v in var.data_connectors : k => merge(v, {
      collection_id = coalesce(v.collection_id, "${local.prefix}${k}")
      destination_configs_normalized = [
        for dc in v.destination_configs : merge(dc, {
          params_normalized = (
            dc.params == null
            ? null
            : jsonencode(jsondecode(
              !startswith(trimspace(dc.params), "{")
              && !startswith(trimspace(dc.params), "[")
              && try(fileexists(pathexpand(dc.params)), false)
              ? file(pathexpand(dc.params))
              : dc.params
            ))
          )
        })
      ]
      # TODO(b/576646188): remove once provider >= 8.13.0.
      entities_normalized = [
        for e in concat(
          v.entities,
          v.data_source == "outlook"
          && !contains([for x in v.entities : x.entity_name], "root")
          ? [{
            entity_name           = "root"
            key_property_mappings = tomap(null)
            params                = jsonencode({})
          }]
          : [],
          v.data_source == "sharepoint"
          && !contains([for x in v.entities : x.entity_name], "site")
          ? [{
            entity_name           = "site"
            key_property_mappings = tomap(null)
            params                = jsonencode({})
          }]
          : []
          ) : merge(e, {
            params_normalized = (
              e.params == null
              ? jsonencode({})
              : jsonencode(jsondecode(
                !startswith(trimspace(e.params), "{")
                && !startswith(trimspace(e.params), "[")
                && try(fileexists(pathexpand(e.params)), false)
                ? file(pathexpand(e.params))
                : e.params
              ))
            )
        })
      ]
      json_params_normalized = (
        v.json_params == null
        ? null
        : jsonencode(jsondecode(
          !startswith(trimspace(v.json_params), "{")
          && !startswith(trimspace(v.json_params), "[")
          && try(fileexists(pathexpand(v.json_params)), false)
          ? file(pathexpand(v.json_params))
          : v.json_params
        ))
      )
      kms_key_name = (
        v.kms_key == null
        ? null
        : lookup(local.ctx.kms_keys, v.kms_key, v.kms_key)
      )
    })
  }
  mcp_connectors = {
    for item in local._mcp_expanded : item.key => merge(item, {
      oauth_resolved = local._mcp_oauth[item.key]
      patch_body = jsonencode({
        actionConfig = {
          createBapConnection = true
          actionParams = merge(
            {
              auth_type         = local._mcp_oauth[item.key] != null ? "OAUTH" : "NO_AUTH"
              instance_uri      = item.config.url
              mcp_server_source = "BYO_MCP"
            },
            {
              use_agent_gateway_egress = item.use_gateway
            },
            !item.use_gateway ? {} : {
              agent_gateway_engine = (
                "projects/${coalesce(var.project_number, "-")}/locations/${local.location}/collections/${try(local.apps[item.primary_app].collection_id, "default_collection")}/engines/${try(local.apps[item.primary_app].engine_id, item.primary_app)}"
              )
            },
            local._mcp_oauth[item.key] == null ? {} : {
              client_secret_basic_override = local._mcp_oauth[item.key].client_secret_basic_override
              pkce_support_enabled         = local._mcp_oauth[item.key].pkce_support_enabled
            },
            local._mcp_oauth[item.key] == null ? {} : {
              for ok, ov in {
                auth_uri        = local._mcp_oauth[item.key].auth_uri
                auth_uri_params = local._mcp_oauth[item.key].auth_uri_params
                client_id       = local._mcp_oauth[item.key].client_id
                client_secret   = local._mcp_oauth[item.key].client_secret
                scopes = (
                  length(local._mcp_oauth[item.key].scopes) > 0
                  ? join(" ", local._mcp_oauth[item.key].scopes)
                  : null
                )
                token_uri = local._mcp_oauth[item.key].token_uri
              } : ok => ov if ov != null
            }
          )
        }
      })
    })
  }
}

# Note: sync flags and params/action_config are ignored on Read (b/576646758,
# b/576646839).
resource "google_discovery_engine_data_connector" "default" {
  for_each      = local.data_connectors
  project       = local.project_id
  location      = local.location
  collection_id = each.value.collection_id
  collection_display_name = urlencode(
    coalesce(each.value.collection_display_name, each.value.collection_id)
  )
  data_source                  = each.value.data_source
  refresh_interval             = each.value.refresh_interval
  auto_run_disabled            = each.value.auto_run_disabled
  connector_modes              = each.value.connector_modes
  data_source_version          = each.value.data_source_version
  deletion_policy              = local.deletion_policy
  incremental_refresh_interval = each.value.incremental_refresh_interval
  incremental_sync_disabled    = each.value.incremental_sync_disabled
  json_params                  = each.value.json_params_normalized
  kms_key_name                 = each.value.kms_key_name
  params = (
    each.value.json_params_normalized == null
    ? coalesce(each.value.params, {})
    : null
  )
  static_ip_enabled = each.value.static_ip_enabled
  sync_mode         = each.value.sync_mode
  tag               = coalesce(each.value.tag, replace(each.value.collection_id, "_", "-"))

  dynamic "action_config" {
    for_each = each.value.action_config == null ? [] : [each.value.action_config]

    content {
      action_params         = action_config.value.action_params
      create_bap_connection = action_config.value.create_bap_connection
    }
  }

  dynamic "bap_config" {
    for_each = each.value.bap_config == null ? [] : [each.value.bap_config]

    content {
      enabled_actions           = bap_config.value.enabled_actions
      supported_connector_modes = bap_config.value.supported_connector_modes
    }
  }

  dynamic "destination_configs" {
    for_each = each.value.destination_configs_normalized

    content {
      key    = destination_configs.value.key
      params = destination_configs.value.params_normalized

      dynamic "destinations" {
        for_each = coalesce(destination_configs.value.destinations, [])

        content {
          host = destinations.value.host
          port = destinations.value.port
        }
      }
    }
  }

  dynamic "entities" {
    for_each = each.value.entities_normalized

    content {
      entity_name           = entities.value.entity_name
      key_property_mappings = entities.value.key_property_mappings
      params                = entities.value.params_normalized
    }
  }

  dynamic "metadata" {
    for_each = each.value.metadata == null ? [] : [each.value.metadata]

    content {
      author            = metadata.value.author
      description       = metadata.value.description
      note              = metadata.value.note
      short_description = metadata.value.short_description
      title             = metadata.value.title
    }
  }

  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
    google_discovery_engine_user_store.default,
  ]

  lifecycle {
    # Avoid forced replacement after import (b/576646876).
    ignore_changes = [
      collection_display_name,
    ]

    precondition {
      condition = alltrue([
        for app_id in each.value.app_ids : contains(keys(var.apps), app_id)
      ])
      error_message = "Data connector '${each.key}' references an app_id in app_ids that is not in var.apps."
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      DATA_STORE_IDS = jsonencode([
        for e in self.entities :
        try(e.data_store, null) != null && try(e.data_store, "") != ""
        ? basename(e.data_store)
        : "${self.collection_id}_${e.entity_name}"
      ])
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

resource "google_discovery_engine_data_connector" "mcp" {
  for_each = local.mcp_connectors
  project  = local.project_id
  location = local.location
  collection_display_name = urlencode(
    coalesce(each.value.config.display_name, each.value.connector_key)
  )
  collection_id     = each.value.collection_id
  connector_modes   = ["FEDERATED"]
  data_source       = "custom_mcp"
  deletion_policy   = local.deletion_policy
  refresh_interval  = each.value.config.refresh_interval
  static_ip_enabled = false
  tag               = replace(each.value.collection_id, "_", "-")

  # Initial POST requires dummy oauth_access_token and NO_AUTH (b/569798395).
  params = {
    oauth_access_token = "none"
  }

  entities {
    entity_name = "mcp_data"
  }

  action_config {
    create_bap_connection = true
    action_params = {
      auth_type         = "NO_AUTH"
      instance_uri      = each.value.config.url
      mcp_server_source = "BYO_MCP"
    }
  }

  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
    google_discovery_engine_user_store.default,
  ]

  lifecycle {
    # See b/569798395, b/576646839, and b/576646876.
    ignore_changes = [
      action_config,
      collection_display_name,
      params,
    ]

    precondition {
      condition = alltrue([
        for app_id in each.value.app_ids : contains(keys(var.apps), app_id)
      ])
      error_message = "MCP connector '${each.key}' references an app_id in app_ids that is not in var.apps."
    }

    precondition {
      condition     = !each.value.use_gateway || var.project_number != null
      error_message = "var.project_number is required when routing MCP connector '${each.key}' through an Egress Agent Gateway."
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      DATA_STORE_IDS  = jsonencode(["${self.collection_id}_mcp_data"])
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

# Temporary shim for b/569798395 and b/576646839 (and json_action_params in
# b/576646874, pending provider >= 8.13.0). Runs unconditionally for all MCP
# connectors so URL edits and OAuth / gateway opt-outs are always reconciled.
resource "terraform_data" "mcp_action_config" {
  for_each = local.mcp_connectors

  triggers_replace = {
    connector  = google_discovery_engine_data_connector.mcp[each.key].name
    patch_body = nonsensitive(sha256(each.value.patch_body))
  }

  provisioner "local-exec" {
    quiet       = true
    interpreter = ["/bin/bash", "-c"]
    environment = {
      CONNECTOR_KEY  = each.key
      CONNECTOR_NAME = google_discovery_engine_data_connector.mcp[each.key].name
      LOCATION       = local.location
      PATCH_BODY     = each.value.patch_body
      PROJECT        = local.project_id
    }
    command = <<-EOT
      set -euo pipefail

      host_prefix=""
      [[ "$LOCATION" != "global" ]] && host_prefix="$${LOCATION}-"
      endpoint="https://$${host_prefix}discoveryengine.googleapis.com/v1"
      url="$${endpoint}/$${CONNECTOR_NAME}"

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
      chmod 600 "$hdr"
      printf 'header = "Authorization: Bearer %s"\nheader = "X-Goog-User-Project: %s"\n' "$token" "$quota_project" > "$hdr"
      trap 'rm -f "$hdr" "$body"' EXIT

      for attempt in {1..12}; do
        status=$(printf '%s' "$PATCH_BODY" | curl -sS -X PATCH -K "$hdr" \
          -H "Content-Type: application/json" \
          --data-binary @- \
          -o "$body" -w '%%{http_code}' \
          "$${url}?updateMask=actionConfig")

        if [[ "$status" == 2* ]]; then
          exit 0
        fi
        if [[ "$status" == "400" ]] && grep -q "INITIALIZING" "$body"; then
          sleep 5
          continue
        fi
        break
      done

      echo "MCP data connector actionConfig patch failed for $CONNECTOR_KEY (HTTP $status)" >&2
      cat "$body" >&2
      exit 1
    EOT
  }

  depends_on = [
    terraform_data.app_agent_gateway_patch,
  ]
}
