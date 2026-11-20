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

# tfdoc:file:description Gemini Enterprise intranet engines, assistants, widgets, and gateway bindings.

locals {
  _app_raw_data_store_ids = {
    for k, v in local.apps : k => distinct(concat(
      [
        for ds in coalesce(try(v.engine.data_store_ids, null), []) : (
          contains(keys(local.data_stores), ds)
          ? local.data_stores[ds].data_store_id
          : ds
        )
      ],
      [
        for ds_k, ds_v in local.data_stores :
        ds_v.data_store_id
        if contains(ds_v.app_ids, k)
      ],
      flatten([
        for dc_k, dc_v in local.data_connectors : [
          for e in dc_v.entities :
          "${dc_v.collection_id}_${e.entity_name}"
          if e.entity_name != null && !contains(["root", "site"], e.entity_name)
        ]
        if contains(dc_v.app_ids, k)
      ]),
      [
        for mc_k, mc_v in local.mcp_connectors :
        "${mc_v.collection_id}_mcp_data"
        if contains(mc_v.app_ids, k)
      ]
    ))
  }
  # Dependency references guarded with contains(keys(...)) so sequential
  # terraform import runs succeed while still ordering app_data_stores after
  # created stores and connectors.
  _app_resolved_data_store_ids = {
    for k, ds_ids in local._app_raw_data_store_ids : k => (
      length(ds_ids) == 1
      && contains(keys(google_discovery_engine_data_store.companion), k)
      ? concat(
        ds_ids,
        [google_discovery_engine_data_store.companion[k].data_store_id]
      )
      : ds_ids
    )
  }
  apps = {
    for k, v in var.apps : k => merge(v, {
      egress_gateway_resolved = (
        v.egress_agent_gateway == ""
        ? null
        : v.egress_agent_gateway != null
        ? lookup(
          local.ctx.agent_gateways,
          v.egress_agent_gateway,
          v.egress_agent_gateway
        )
        : local.egress_agent_gateway
      )
      engine_id = coalesce(
        v.engine_id,
        v.engine == null ? k : "${local.prefix}${k}"
      )
      has_egress_gateway = (
        v.egress_agent_gateway == ""
        ? false
        : v.egress_agent_gateway != null || var.egress_agent_gateway != null
      )
      kms_key_name = (
        try(v.engine.kms_key, null) == null
        ? null
        : lookup(local.ctx.kms_keys, v.engine.kms_key, v.engine.kms_key)
      )
    })
  }
  apps_with_assistant = {
    for k, v in local.apps : k => merge(v, {
      has_customer_policy = (
        length(v.assistant.banned_phrases) > 0
        || v.assistant.model_armor_config != null
      )
      response_template = (
        try(v.assistant.model_armor_config.response_template, "") == ""
        ? ""
        : lookup(
          local.ctx.model_armor_templates,
          v.assistant.model_armor_config.response_template,
          v.assistant.model_armor_config.response_template
        )
      )
      user_prompt_template = (
        try(v.assistant.model_armor_config.user_prompt_template, "") == ""
        ? ""
        : lookup(
          local.ctx.model_armor_templates,
          v.assistant.model_armor_config.user_prompt_template,
          v.assistant.model_armor_config.user_prompt_template
        )
      )
    }) if v.assistant != null
  }
  apps_with_data_stores_reconcile = {
    for k, v in local.apps : k => v
    if v.engine != null || length(local._app_raw_data_store_ids[k]) > 0
  }
  apps_with_gateway = {
    for k, v in local.apps : k => v
    if v.has_egress_gateway
  }
  apps_with_single_store = {
    for k, v in local.apps : k => v
    if length(local._app_raw_data_store_ids[k]) == 1
  }
  apps_with_widget = {
    for k, v in local.apps : k => merge(v, {
      data_store_ui_configs = {
        for ds_k, ds_v in coalesce(
          try(v.widget_config.ui_settings.data_store_ui_configs, null), {}
          ) : ds_k => merge(ds_v, {
            name = (
              contains(keys(google_discovery_engine_data_store.default), ds_k)
              ? google_discovery_engine_data_store.default[ds_k].name
              : ds_k
            )
        })
      }
      workforce_provider_resolved = (
        try(
          v.widget_config.access_settings.workforce_identity_pool_provider,
          null
        ) == null
        ? null
        : lookup(
          local.ctx.workforce_pools,
          v.widget_config.access_settings.workforce_identity_pool_provider,
          v.widget_config.access_settings.workforce_identity_pool_provider
        )
      )
    }) if v.widget_config != null
  }
  engines = {
    for k, v in local.apps : k => v if v.engine != null
  }
}

# Discovery Engine's UpdateEngine API rejects dataStoreIds of length 1 (only 0
# or >= 2 are allowed). Create an empty NO_CONTENT companion store whenever an
# app resolves to exactly 1 attached store.
resource "google_discovery_engine_data_store" "companion" {
  for_each      = local.apps_with_single_store
  project       = local.project_id
  location      = local.location
  data_store_id = "${replace(each.value.engine_id, "_", "-")}-companion"
  display_name = (
    "${coalesce(try(each.value.engine.display_name, null), each.value.engine_id)}-companion"
  )
  industry_vertical            = coalesce(try(each.value.engine.industry_vertical, null), "GENERIC")
  content_config               = "NO_CONTENT"
  solution_types               = ["SOLUTION_TYPE_SEARCH"]
  create_advanced_site_search  = false
  deletion_policy              = local.deletion_policy
  skip_default_schema_creation = false

  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
    google_discovery_engine_user_store.default,
  ]

  # Detach the companion store before deletion when an app transitions from 1
  # attached store to 0 or >= 2 stores.
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

resource "google_discovery_engine_search_engine" "default" {
  for_each                   = local.engines
  project                    = local.project_id
  location                   = local.location
  collection_id              = each.value.collection_id
  engine_id                  = each.value.engine_id
  display_name               = each.value.engine.display_name
  app_type                   = "APP_TYPE_INTRANET"
  data_store_ids             = []
  deletion_policy            = local.deletion_policy
  disable_analytics          = each.value.engine.disable_analytics
  features                   = each.value.engine.features
  industry_vertical          = each.value.engine.industry_vertical
  kms_key_name               = each.value.kms_key_name
  model_configs              = each.value.engine.model_configs
  procurement_contact_emails = each.value.engine.procurement_contact_emails

  search_engine_config {
    required_subscription_tier = each.value.engine.required_subscription_tier
    search_add_ons             = each.value.engine.search_add_ons
    search_tier                = each.value.engine.search_tier
  }

  dynamic "knowledge_graph_config" {
    for_each = each.value.engine.knowledge_graph == null ? [] : [""]

    content {
      cloud_knowledge_graph_types    = each.value.engine.knowledge_graph.cloud_knowledge_graph_types
      enable_cloud_knowledge_graph   = each.value.engine.knowledge_graph.enable_cloud_knowledge_graph
      enable_private_knowledge_graph = each.value.engine.knowledge_graph.enable_private_knowledge_graph

      dynamic "feature_config" {
        for_each = (
          each.value.engine.knowledge_graph.feature_config == null ? [] : [""]
        )

        content {
          disable_private_kg_auto_complete       = each.value.engine.knowledge_graph.feature_config.disable_private_kg_auto_complete
          disable_private_kg_enrichment          = each.value.engine.knowledge_graph.feature_config.disable_private_kg_enrichment
          disable_private_kg_query_ui_chips      = each.value.engine.knowledge_graph.feature_config.disable_private_kg_query_ui_chips
          disable_private_kg_query_understanding = each.value.engine.knowledge_graph.feature_config.disable_private_kg_query_understanding
        }
      }
    }
  }

  dynamic "common_config" {
    for_each = each.value.engine.company_name == null ? [] : [""]

    content {
      company_name = each.value.engine.company_name
    }
  }

  depends_on = [
    google_discovery_engine_acl_config.default,
    google_discovery_engine_cmek_config.default,
    google_discovery_engine_user_store.default,
  ]

  lifecycle {
    ignore_changes = [
      data_store_ids,
    ]
  }
}

# Reconcile engine dataStoreIds outside google_discovery_engine_search_engine so
# targeted connector destruction can detach stores before deleting collections.
resource "terraform_data" "app_data_stores" {
  for_each = local.apps_with_data_stores_reconcile

  triggers_replace = {
    collection_id = each.value.collection_id
    connectors = jsonencode([
      for dc_k, dc_v in local.data_connectors :
      google_discovery_engine_data_connector.default[dc_k].id
      if contains(dc_v.app_ids, each.key)
      && contains(keys(google_discovery_engine_data_connector.default), dc_k)
    ])
    data_store_ids = jsonencode(sort(local._app_resolved_data_store_ids[each.key]))
    engine_id = (
      contains(keys(google_discovery_engine_search_engine.default), each.key)
      ? google_discovery_engine_search_engine.default[each.key].engine_id
      : each.value.engine_id
    )
    mcp_connectors = jsonencode([
      for mc_k, mc_v in local.mcp_connectors :
      google_discovery_engine_data_connector.mcp[mc_k].id
      if contains(mc_v.app_ids, each.key)
      && contains(keys(google_discovery_engine_data_connector.mcp), mc_k)
    ])
    native_stores = jsonencode([
      for ds_k, ds_v in local.data_stores :
      google_discovery_engine_data_store.default[ds_k].id
      if(
        contains(ds_v.app_ids, each.key)
        || contains(
          coalesce(try(each.value.engine.data_store_ids, null), []),
          ds_k
        )
      ) && contains(keys(google_discovery_engine_data_store.default), ds_k)
    ])
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      endpoint="https://${local.location == "global" ? "" : "${local.location}-"}discoveryengine.googleapis.com/v1"
      url="$endpoint/projects/${local.project_id}/locations/${local.location}/collections/${each.value.collection_id}/engines/${each.value.engine_id}"
      lockdir="/tmp/ge-mcp-detach-${local.project_id}-${local.location}.lock"
      body=$(mktemp)

      while ! mkdir "$lockdir" 2>/dev/null; do
        sleep 1
      done
      trap 'rmdir "$lockdir" 2>/dev/null || true; rm -f "$body"' EXIT

      status=$(curl -sS -X PATCH \
        -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application/json" \
        -H "X-Goog-User-Project: ${local.project_id}" \
        -d '${jsonencode({ dataStoreIds = local._app_resolved_data_store_ids[each.key] })}' \
        -o "$body" -w '%%{http_code}' \
        "$url?updateMask=dataStoreIds")

      if [[ "$status" != 2* ]]; then
        echo "Failed to update dataStoreIds on ${each.value.engine_id} (HTTP $status)" >&2
        cat "$body" >&2
        exit 1
      fi
    EOT
  }
}

# Temporary shim until google_discovery_engine_search_engine exposes
# agentGatewaySetting natively.
resource "terraform_data" "app_agent_gateway_patch" {
  for_each = local.apps_with_gateway

  triggers_replace = {
    agent_gateway = each.value.egress_gateway_resolved
    collection_id = each.value.collection_id
    engine_config = sha256(jsonencode(each.value.engine))
    engine_id = (
      contains(keys(google_discovery_engine_search_engine.default), each.key)
      ? google_discovery_engine_search_engine.default[each.key].engine_id
      : each.value.engine_id
    )
  }

  lifecycle {
    precondition {
      condition     = var.project_number != null
      error_message = "var.project_number is required when binding an Egress Agent Gateway to app '${each.key}'."
    }
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail

      endpoint="https://${local.location == "global" ? "" : "${local.location}-"}discoveryengine.googleapis.com/v1"
      url="$endpoint/projects/${var.project_number}/locations/${local.location}/collections/${each.value.collection_id}/engines/${each.value.engine_id}"
      mask="agentGatewaySetting.defaultEgressAgentGateway.name"
      body=$(mktemp)
      trap 'rm -f "$body"' EXIT

      status=$(curl -sS -X PATCH \
        -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application/json" \
        -H "X-Goog-User-Project: ${local.project_id}" \
        -d '${jsonencode({
    agentGatewaySetting = {
      defaultEgressAgentGateway = {
        name = each.value.egress_gateway_resolved
      }
    }
})}' \
        -o "$body" -w '%%{http_code}' \
        "$url?updateMask=$mask")

      if [[ "$status" != 2* ]]; then
        echo "Agent Gateway engine patch failed for ${each.value.engine_id} (HTTP $status)" >&2
        cat "$body" >&2
        exit 1
      fi
    EOT
}

depends_on = [
  google_discovery_engine_search_engine.default,
]
}

# CreateEngine with APP_TYPE_INTRANET auto-provisions default_assistant, while
# google_discovery_engine_assistant issues POST on create (409 AlreadyExists).
# Import default_assistant before enabling assistant on an app; ABANDON ensures
# it is never deleted on destroy.
resource "google_discovery_engine_assistant" "default" {
  for_each                         = local.apps_with_assistant
  project                          = local.project_id
  location                         = local.location
  collection_id                    = each.value.collection_id
  engine_id                        = each.value.engine_id
  assistant_id                     = each.value.assistant.assistant_id
  display_name                     = each.value.assistant.display_name
  default_web_grounding_toggle_off = each.value.assistant.default_web_grounding_toggle_off
  deletion_policy                  = "ABANDON"
  description                      = each.value.assistant.description
  web_grounding_type               = each.value.assistant.web_grounding_type

  dynamic "customer_policy" {
    for_each = each.value.has_customer_policy ? [""] : []

    content {
      dynamic "banned_phrases" {
        for_each = each.value.assistant.banned_phrases

        content {
          ignore_diacritics = banned_phrases.value.ignore_diacritics
          match_type        = banned_phrases.value.match_type
          phrase = coalesce(
            banned_phrases.value.phrase, banned_phrases.key
          )
        }
      }

      dynamic "model_armor_config" {
        for_each = each.value.assistant.model_armor_config == null ? [] : [""]

        content {
          failure_mode         = each.value.assistant.model_armor_config.failure_mode
          response_template    = each.value.response_template
          user_prompt_template = each.value.user_prompt_template
        }
      }
    }
  }

  dynamic "generation_config" {
    for_each = each.value.assistant.generation_config == null ? [] : [""]

    content {
      default_language = each.value.assistant.generation_config.default_language

      dynamic "system_instruction" {
        for_each = (
          each.value.assistant.generation_config.system_instruction == null
          ? [] : [""]
        )

        content {
          additional_system_instruction = (
            each.value.assistant.generation_config.system_instruction
          )
        }
      }
    }
  }

  depends_on = [
    google_discovery_engine_search_engine.default,
  ]
}

resource "google_discovery_engine_widget_config" "default" {
  for_each         = local.apps_with_widget
  project          = local.project_id
  location         = local.location
  collection_id    = each.value.collection_id
  engine_id        = each.value.engine_id
  widget_config_id = each.value.widget_config.widget_config_id

  dynamic "access_settings" {
    for_each = each.value.widget_config.access_settings == null ? [] : [""]

    content {
      allow_public_access              = each.value.widget_config.access_settings.allow_public_access
      allowlisted_domains              = each.value.widget_config.access_settings.allowlisted_domains
      enable_web_app                   = each.value.widget_config.access_settings.enable_web_app
      language_code                    = each.value.widget_config.access_settings.language_code
      workforce_identity_pool_provider = each.value.workforce_provider_resolved
    }
  }

  dynamic "homepage_setting" {
    for_each = each.value.widget_config.homepage_setting == null ? [] : [""]

    content {
      dynamic "shortcuts" {
        for_each = each.value.widget_config.homepage_setting.shortcuts

        content {
          destination_uri = shortcuts.value.destination_uri
          title           = shortcuts.value.title

          dynamic "icon" {
            for_each = shortcuts.value.icon_url == null ? [] : [""]

            content {
              url = shortcuts.value.icon_url
            }
          }
        }
      }
    }
  }

  dynamic "ui_branding" {
    for_each = each.value.widget_config.ui_branding == null ? [] : [""]

    content {
      dynamic "logo" {
        for_each = each.value.widget_config.ui_branding.logo == null ? [] : [""]

        content {
          url = each.value.widget_config.ui_branding.logo.url
        }
      }
    }
  }

  dynamic "ui_settings" {
    for_each = each.value.widget_config.ui_settings == null ? [] : [""]

    content {
      default_search_request_order_by   = each.value.widget_config.ui_settings.default_search_request_order_by
      disable_user_events_collection    = each.value.widget_config.ui_settings.disable_user_events_collection
      enable_autocomplete               = each.value.widget_config.ui_settings.enable_autocomplete
      enable_create_agent_button        = each.value.widget_config.ui_settings.enable_create_agent_button
      enable_people_search              = each.value.widget_config.ui_settings.enable_people_search
      enable_quality_feedback           = each.value.widget_config.ui_settings.enable_quality_feedback
      enable_safe_search                = each.value.widget_config.ui_settings.enable_safe_search
      enable_search_as_you_type         = each.value.widget_config.ui_settings.enable_search_as_you_type
      enable_visual_content_summary     = each.value.widget_config.ui_settings.enable_visual_content_summary
      interaction_type                  = each.value.widget_config.ui_settings.interaction_type
      result_description_type           = each.value.widget_config.ui_settings.result_description_type
      source_admin_display_name_enabled = each.value.widget_config.ui_settings.source_admin_display_name_enabled

      dynamic "data_store_ui_configs" {
        for_each = each.value.data_store_ui_configs

        content {
          name = data_store_ui_configs.value.name

          dynamic "facet_field" {
            for_each = data_store_ui_configs.value.facet_fields

            content {
              display_name = facet_field.value
              field        = facet_field.key
            }
          }

          dynamic "fields_ui_components_map" {
            for_each = data_store_ui_configs.value.fields_ui_components
            iterator = ui_component

            content {
              device_visibility = ui_component.value.device_visibility
              display_template  = ui_component.value.display_template
              field             = ui_component.value.field
              ui_component      = ui_component.key
            }
          }
        }
      }

      dynamic "generative_answer_config" {
        for_each = (
          each.value.widget_config.ui_settings.generative_answer_config == null
          ? [] : [""]
        )

        content {
          disable_related_questions       = each.value.widget_config.ui_settings.generative_answer_config.disable_related_questions
          ignore_adversarial_query        = each.value.widget_config.ui_settings.generative_answer_config.ignore_adversarial_query
          ignore_low_relevant_content     = each.value.widget_config.ui_settings.generative_answer_config.ignore_low_relevant_content
          ignore_non_answer_seeking_query = each.value.widget_config.ui_settings.generative_answer_config.ignore_non_answer_seeking_query
          image_source                    = each.value.widget_config.ui_settings.generative_answer_config.image_source
          language_code                   = each.value.widget_config.ui_settings.generative_answer_config.language_code
          max_rephrase_steps              = each.value.widget_config.ui_settings.generative_answer_config.max_rephrase_steps
          model_prompt_preamble           = each.value.widget_config.ui_settings.generative_answer_config.model_prompt_preamble
          model_version                   = each.value.widget_config.ui_settings.generative_answer_config.model_version
          result_count                    = each.value.widget_config.ui_settings.generative_answer_config.result_count
        }
      }

      dynamic "search_addon_spec" {
        for_each = (
          each.value.widget_config.ui_settings.search_addon_spec == null
          ? [] : [""]
        )

        content {
          generative_answer_add_on_disabled   = each.value.widget_config.ui_settings.search_addon_spec.generative_answer_add_on_disabled
          kpi_personalization_add_on_disabled = each.value.widget_config.ui_settings.search_addon_spec.kpi_personalization_add_on_disabled
          semantic_add_on_disabled            = each.value.widget_config.ui_settings.search_addon_spec.semantic_add_on_disabled
        }
      }
    }
  }

  depends_on = [
    google_discovery_engine_search_engine.default,
  ]
}
