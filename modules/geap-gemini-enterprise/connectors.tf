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
    for k, v in var.mcp_connectors : (
      # When routing through an Egress Agent Gateway across multiple apps,
      # actionParams.agent_gateway_engine binds a single engine per connector,
      # so expand one connector instance per target app.
      coalesce(
        v.use_agent_gateway_egress,
        anytrue([
          for app_id in v.app_ids :
          try(local.apps[app_id].has_egress_gateway, var.egress_agent_gateway != null)
        ])
      ) && length(v.app_ids) > 1
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
          collection_id = trimsuffix(
            substr(
              "${coalesce(v.collection_id, "${local.prefix}${k}")}-${replace(try(local.apps[app_id].engine_id, app_id), "_", "-")}",
              0,
              54
            ),
            "-"
          )
        }
      ]
      : [
        {
          key           = k
          connector_key = k
          app_ids       = distinct(v.app_ids)
          primary_app   = try(v.app_ids[0], null)
          config        = v
          use_gateway = coalesce(
            v.use_agent_gateway_egress,
            length(v.app_ids) == 1 && try(
              local.apps[v.app_ids[0]].has_egress_gateway,
              var.egress_agent_gateway != null
            )
          )
          collection_id = coalesce(
            v.collection_id,
            trimsuffix(substr("${local.prefix}${k}", 0, 54), "-")
          )
        }
      ]
    )
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
              fileexists(pathexpand(dc.params))
              ? file(pathexpand(dc.params))
              : dc.params
            ))
          )
        })
      ]
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
                fileexists(pathexpand(e.params))
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
          fileexists(pathexpand(v.json_params))
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
      needs_action_patch = (
        item.use_gateway || local._mcp_oauth[item.key] != null
      )
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
            !item.use_gateway ? {} : {
              agent_gateway_engine = (
                "projects/${var.project_number}/locations/${local.location}/collections/${try(local.apps[item.primary_app].collection_id, "default_collection")}/engines/${try(local.apps[item.primary_app].engine_id, item.primary_app)}"
              )
            },
            !item.use_gateway ? {} : {
              use_agent_gateway_egress = true
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

resource "google_discovery_engine_data_connector" "default" {
  for_each                     = local.data_connectors
  project                      = local.project_id
  location                     = local.location
  collection_id                = each.value.collection_id
  collection_display_name      = coalesce(each.value.collection_display_name, each.value.collection_id)
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
    command     = <<-EOT
      set -euo pipefail

      endpoint="https://${self.location == "global" ? "" : "${self.location}-"}discoveryengine.googleapis.com/v1"
      prefix="${self.collection_id}_"
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
        echo "Failed to list Discovery Engine apps while detaching $${prefix}* (HTTP $status)" >&2
        cat "$body" >&2
        exit 1
      fi

      engines=$(jq -r --arg pfx "$prefix" '.engines[]? | select(any((.dataStoreIds // [])[]; startswith($pfx))) | .name' "$body")
      for engine in $engines; do
        payload=$(jq -c --arg eng "$engine" --arg pfx "$prefix" \
          '.engines[] | select(.name == $eng) | ([(.dataStoreIds // [])[] | select(startswith($pfx) | not)]) as $rem | {dataStoreIds: (if ($rem | length) == 1 then [] else $rem end)}' "$body")
        patch_status=$(curl -sS -X PATCH \
          -H "Authorization: Bearer $token" \
          -H "Content-Type: application/json" \
          -H "X-Goog-User-Project: ${self.project}" \
          -d "$payload" \
          -o "$resp" -w '%%{http_code}' \
          "$endpoint/$engine?updateMask=dataStoreIds")
        if [[ "$patch_status" != 2* && "$patch_status" != "404" ]]; then
          echo "Failed to detach $${prefix}* from $engine (HTTP $patch_status)" >&2
          cat "$resp" >&2
          exit 1
        fi
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
    command     = <<-EOT
      set -euo pipefail

      endpoint="https://${self.location == "global" ? "" : "${self.location}-"}discoveryengine.googleapis.com/v1"
      ds_id="${self.collection_id}_mcp_data"
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

# Temporary shim until hashicorp/google exposes action_config.json_action_params
# on google_discovery_engine_data_connector (action_params is map(string) in
# 8.12.0, which serializes boolean flags as strings ignored by the API).
resource "terraform_data" "mcp_action_config" {
  for_each = {
    for k, v in local.mcp_connectors : k => v if v.needs_action_patch
  }

  triggers_replace = {
    connector  = google_discovery_engine_data_connector.mcp[each.key].name
    patch_body = sha256(each.value.patch_body)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      endpoint="https://${local.location == "global" ? "" : "${local.location}-"}discoveryengine.googleapis.com/v1"
      url="$endpoint/${google_discovery_engine_data_connector.mcp[each.key].name}"
      mask="actionConfig"
      body=$(mktemp)
      trap 'rm -f "$body"' EXIT

      for attempt in {1..12}; do
        status=$(curl -sS -X PATCH \
          -H "Authorization: Bearer $(gcloud auth print-access-token)" \
          -H "Content-Type: application/json" \
          -H "X-Goog-User-Project: ${local.project_id}" \
          -d '${each.value.patch_body}' \
          -o "$body" -w '%%{http_code}' \
          "$url?updateMask=$mask")

        if [[ "$status" == 2* ]]; then
          exit 0
        fi
        if [[ "$status" == "400" ]] && grep -q "INITIALIZING" "$body"; then
          sleep 5
          continue
        fi
        break
      done

      echo "MCP data connector actionConfig patch failed for ${each.key} (HTTP $status)" >&2
      cat "$body" >&2
      exit 1
    EOT
  }

  depends_on = [
    terraform_data.app_agent_gateway_patch,
  ]
}
