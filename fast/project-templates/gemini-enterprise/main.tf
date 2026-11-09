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

locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p             = "$"
  effective_kms_key = var.enable_cmek ? google_kms_crypto_key.gemini_key[0].id : null
  location          = lookup(local.ctx.locations, var.location, var.location)
  prefix            = var.prefix == null ? "" : "${var.prefix}-"
  project_id        = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  validation_principals = [
    for m in var.validation_app_principals :
    lookup(local.ctx.iam_principals, m, m)
  ]
  workforce_pool_name = (
    var.idp_config.idp_type == "THIRD_PARTY"
    ? "locations/global/workforcePools/${var.idp_config.workforce_pool_id}"
    : null
  )
  workforce_pool_provider = (
    var.idp_config.idp_type == "THIRD_PARTY"
    ? "locations/global/workforcePools/${var.idp_config.workforce_pool_id}/providers/${var.idp_config.workforce_provider_id}"
    : null
  )
  workforce_principals = [
    for m in var.workforce_app_principals :
    lookup(local.ctx.iam_principals, m, m)
  ]
  workspace_actions_enabled = (
    var.enable_workspace_connectors &&
    var.workspace_oauth_config.client_id != null &&
    var.workspace_oauth_config.client_secret_id != null
  )
  workspace_connectors = var.enable_workspace_connectors ? {
    google-drive = {
      collection_display_name = "Google Drive"
      collection_id           = "google-drive-collection"
      connector_modes = (
        local.workspace_actions_enabled ? ["FEDERATED", "ACTIONS"] : ["FEDERATED"]
      )
      data_source       = "google_drive"
      kms_key           = local.effective_kms_key
      refresh_interval  = "0s"
      auto_run_disabled = true
      action_config = local.workspace_actions_enabled ? {
        create_bap_connection = true
        action_params = {
          auth_type     = "OAUTH"
          client_id     = var.workspace_oauth_config.client_id
          client_secret = data.google_secret_manager_secret_version.workspace_oauth_secret[0].secret_data
        }
      } : null
      entities = [
        { entity_name = "google_drive" }
      ]
    }
    google-mail = {
      collection_display_name = "Gmail"
      collection_id           = "google-mail-collection"
      connector_modes = (
        local.workspace_actions_enabled ? ["FEDERATED", "ACTIONS"] : ["FEDERATED"]
      )
      data_source       = "google_mail"
      kms_key           = local.effective_kms_key
      refresh_interval  = "0s"
      auto_run_disabled = true
      action_config = local.workspace_actions_enabled ? {
        create_bap_connection = true
        action_params = {
          auth_type     = "OAUTH"
          client_id     = var.workspace_oauth_config.client_id
          client_secret = data.google_secret_manager_secret_version.workspace_oauth_secret[0].secret_data
        }
      } : null
      entities = [
        { entity_name = "google_mail" }
      ]
    }
    google-calendar = {
      collection_display_name = "Google Calendar"
      collection_id           = "google-calendar-collection"
      connector_modes = (
        local.workspace_actions_enabled ? ["FEDERATED", "ACTIONS"] : ["FEDERATED"]
      )
      data_source       = "google_calendar"
      kms_key           = local.effective_kms_key
      refresh_interval  = "0s"
      auto_run_disabled = true
      action_config = local.workspace_actions_enabled ? {
        create_bap_connection = true
        action_params = {
          auth_type     = "OAUTH"
          client_id     = var.workspace_oauth_config.client_id
          client_secret = data.google_secret_manager_secret_version.workspace_oauth_secret[0].secret_data
        }
      } : null
      entities = [
        { entity_name = "google_calendar" }
      ]
    }
    google-chat = {
      collection_display_name = "Google Chat"
      collection_id           = "google-chat-collection"
      connector_modes         = ["FEDERATED", "ACTIONS"]
      data_source             = "google_chat"
      kms_key                 = local.effective_kms_key
      refresh_interval        = "0s"
      auto_run_disabled       = true
      action_config = {
        create_bap_connection = true
        action_params = {
          auth_type = "OAUTH"
          auth_key  = "OAuth"
        }
      }
      entities = [
        { entity_name = "google_chat" }
      ]
    }
  } : {}
}

resource "google_project_service_identity" "discoveryengine_sa" {
  provider = google-beta
  project  = local.project_id
  service  = "discoveryengine.googleapis.com"
}

# ------------------------------------------------------------------------------
# Control Point 1: Org Policy Connector/MCP Guardrails & Model Armor Floors
# ------------------------------------------------------------------------------

resource "google_org_policy_policy" "allow_custom_mcp_connector" {
  count  = var.enforce_org_policies ? 1 : 0
  name   = "projects/${local.project_id}/policies/discoveryengine.managed.disableCustomMcpServerConnector"
  parent = "projects/${local.project_id}"

  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

# Note: enforcedProjects entries must match '^projects/[a-z0-9-]+/$'.
# Chained via depends_on to prevent 409 CONCURRENT_POLICY_CHANGES on the same parent.
resource "google_org_policy_policy" "restrict_allowed_data_sources" {
  count  = var.enforce_org_policies ? 1 : 0
  name   = "projects/${local.project_id}/policies/discoveryengine.managed.allowedDataSources"
  parent = "projects/${local.project_id}"

  spec {
    rules {
      enforce = "TRUE"
      parameters = jsonencode({
        allowedDataSources = var.allowed_data_sources
        enforcedProjects = [
          "projects/${local.project_id}/"
        ]
      })
    }
  }

  depends_on = [google_org_policy_policy.allow_custom_mcp_connector]
}

resource "google_org_policy_policy" "restrict_connector_egress_fqdns" {
  count  = var.enforce_org_policies ? 1 : 0
  name   = "projects/${local.project_id}/policies/discoveryengine.managed.allowedEgressFqdns"
  parent = "projects/${local.project_id}"

  spec {
    rules {
      enforce = "TRUE"
      parameters = jsonencode({
        allowedEgressFqdns = var.allowed_egress_fqdns
        enforcedProjects = [
          "projects/${local.project_id}/"
        ]
      })
    }
  }

  depends_on = [google_org_policy_policy.restrict_allowed_data_sources]
}

resource "google_model_armor_floorsetting" "project_guardrails" {
  count                            = var.enable_model_armor ? 1 : 0
  parent                           = "projects/${local.project_id}"
  location                         = "global"
  enable_floor_setting_enforcement = true
  integrated_services              = ["AI_PLATFORM", "GOOGLE_MCP_SERVER"]

  filter_config {
    pi_and_jailbreak_filter_settings {
      filter_enforcement = "ENABLED"
      confidence_level   = "MEDIUM_AND_ABOVE"
    }
    malicious_uri_filter_settings {
      filter_enforcement = "ENABLED"
    }
    sdp_settings {
      basic_config {
        filter_enforcement = "ENABLED"
      }
    }
    rai_settings {
      rai_filters {
        filter_type      = "DANGEROUS"
        confidence_level = "MEDIUM_AND_ABOVE"
      }
    }
  }

  ai_platform_floor_setting {
    inspect_and_block    = true
    enable_cloud_logging = true
  }

  google_mcp_server_floor_setting {
    inspect_and_block    = true
    enable_cloud_logging = true
  }
}

# ------------------------------------------------------------------------------
# Regional Cloud KMS Key & Optional Discovery Engine CMEK Configuration
# ------------------------------------------------------------------------------

resource "google_kms_key_ring" "gemini_ring" {
  count    = var.enable_cmek ? 1 : 0
  project  = local.project_id
  name     = "${local.prefix}${var.name}-${local.location}-ring"
  location = local.location
}

resource "google_kms_crypto_key" "gemini_key" {
  count           = var.enable_cmek ? 1 : 0
  name            = "${local.prefix}${var.name}-${local.location}-key"
  key_ring        = google_kms_key_ring.gemini_ring[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"
}

resource "google_kms_crypto_key_iam_member" "discoveryengine_cmek" {
  count         = var.enable_cmek ? 1 : 0
  crypto_key_id = google_kms_crypto_key.gemini_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.discoveryengine_sa.email}"
}

# ------------------------------------------------------------------------------
# Cloud Storage Knowledge Corpus & Secret Manager Lookups for Connectors
# ------------------------------------------------------------------------------

resource "google_storage_bucket" "knowledge_corpus" {
  count                       = var.enable_gcs_connector ? 1 : 0
  project                     = local.project_id
  name                        = "${local.prefix}${local.project_id}-ge-corpus"
  location                    = upper(local.location)
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "discoveryengine_gcs_reader" {
  count  = var.enable_gcs_connector ? 1 : 0
  bucket = google_storage_bucket.knowledge_corpus[0].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_project_service_identity.discoveryengine_sa.email}"
}

resource "google_storage_bucket_object" "sample_policy_doc" {
  count        = var.enable_gcs_connector ? 1 : 0
  name         = "docs/enterprise-ai-governance-policy.txt"
  bucket       = google_storage_bucket.knowledge_corpus[0].name
  content_type = "text/plain"
  content      = <<-EOT
    Enterprise AI Governance & Human-in-the-Loop (HITL) Standard:
    1. Every mutative action across Native connectors and commercial MCP servers requires explicit human confirmation prior to execution.
    2. All newly released Native connector actions and vendor MCP tools default to Disabled until explicitly added to bap_config.enabled_actions via Terraform.
    3. Org Policy constraints discoveryengine.managed.allowedDataSources and discoveryengine.managed.allowedEgressFqdns enforce strict project-level allowlists.
  EOT
}

data "google_secret_manager_secret_version" "jira_oauth_secret" {
  count   = var.enable_jira_connector ? 1 : 0
  project = local.project_id
  secret  = var.jira_config.client_secret_id
}

data "google_secret_manager_secret_version" "jira_refresh_token" {
  count   = var.enable_jira_connector ? 1 : 0
  project = local.project_id
  secret  = var.jira_config.refresh_token_secret_id
}

data "google_secret_manager_secret_version" "workspace_oauth_secret" {
  count   = local.workspace_actions_enabled ? 1 : 0
  project = local.project_id
  secret  = var.workspace_oauth_config.client_secret_id
}

# ------------------------------------------------------------------------------
# App 1: Primary Production Workforce App (Promoted Foundational Stores Only)
# ------------------------------------------------------------------------------

module "gemini-enterprise-prod" {
  source     = "../../../modules/ai-applications"
  project_id = local.project_id
  name       = "${local.prefix}${var.name}-prod"
  location   = local.location

  acl_config = {
    idp_type            = var.idp_config.idp_type
    workforce_pool_name = local.workforce_pool_name
  }

  license_config = (
    var.license_config_name != null || var.enable_free_trial_license
    ? {
      create_free_trial            = var.license_config_name == null && var.enable_free_trial_license
      enable_license_auto_register = true
      license_config_name          = var.license_config_name
    }
    : null
  )

  encryption_configs = (
    var.enable_cmek
    ? {
      (local.location) = {
        kms_key     = local.effective_kms_key
        set_default = true
      }
    }
    : {}
  )

  data_stores_configs = {
    knowledge-store = {
      content_config              = "CONTENT_REQUIRED"
      create_advanced_site_search = false
      display_name                = "Enterprise Knowledge Store"
      kms_key                     = local.effective_kms_key
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
      document_processing_config = {
        chunking_config = {
          layout_based_chunking_config = {
            chunk_size                = 500
            include_ancestor_headings = true
          }
        }
        default_parsing_config = {
          digital_parsing_config = true
        }
      }
    }
    reserved-store = {
      content_config              = "NO_CONTENT"
      create_advanced_site_search = false
      display_name                = "Reserved Secondary Store"
      kms_key                     = local.effective_kms_key
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
    }
  }

  data_connectors_configs = merge(
    var.enable_gcs_connector ? {
      gcs-knowledge = {
        collection_display_name = "Cloud Storage Knowledge Connector"
        collection_id           = "gcs-knowledge-collection"
        connector_modes         = ["DATA_INGESTION"]
        data_source             = "gcs"
        kms_key                 = local.effective_kms_key
        json_params = jsonencode({
          instance_uris = ["gs://${google_storage_bucket.knowledge_corpus[0].name}/docs/*"]
        })
        entities = [
          {
            entity_name = "gcs_store"
            params = jsonencode({
              data_schema       = "content"
              auto_generate_ids = false
            })
          }
        ]
      }
    } : {},
    var.enable_jira_connector ? {
      jira-enterprise = {
        collection_display_name = "Jira Cloud Federated"
        collection_id           = "jira-enterprise-collection"
        connector_modes         = ["FEDERATED", "ACTIONS"]
        data_source             = "jira"
        kms_key                 = local.effective_kms_key
        params = {
          auth_type     = "OAUTH"
          instance_uri  = var.jira_config.instance_uri
          instance_id   = var.jira_config.cloud_id
          client_id     = var.jira_config.client_id
          client_secret = data.google_secret_manager_secret_version.jira_oauth_secret[0].secret_data
          refresh_token = data.google_secret_manager_secret_version.jira_refresh_token[0].secret_data
        }
        destination_configs = [
          {
            key = "url"
            destinations = [
              {
                host = split("/", replace(var.jira_config.instance_uri, "https://", ""))[0]
                port = 443
              }
            ]
            params = jsonencode({
              destination_type = "public"
            })
          }
        ]
        action_config = {
          create_bap_connection = true
          action_params = {
            auth_type     = "OAUTH"
            instance_uri  = var.jira_config.instance_uri
            instance_id   = var.jira_config.cloud_id
            client_id     = var.jira_config.client_id
            client_secret = data.google_secret_manager_secret_version.jira_oauth_secret[0].secret_data
          }
        }
        # Control Point 2: Explicit Admin Action Allowlist (HITL still enforced at runtime)
        bap_config = {
          supported_connector_modes = ["ACTIONS"]
          enabled_actions           = var.jira_config.enabled_actions
        }
        entities = [
          { entity_name = "project" },
          { entity_name = "issue" },
          { entity_name = "comment" },
        ]
      }
    } : {},
    local.workspace_connectors
  )

  engines_configs = {
    data_store_ids = ["knowledge-store", "reserved-store"]
    search_engine_config = {
      app_type                       = "APP_TYPE_INTRANET"
      company_name                   = var.company_name
      display_name                   = "Gemini Enterprise (Production Workforce)"
      enable_private_knowledge_graph = true
      kms_key                        = local.effective_kms_key
      search_add_ons                 = ["SEARCH_ADD_ON_LLM"]
      search_tier                    = "SEARCH_TIER_ENTERPRISE"
      features = {
        "agent-sharing-without-admin-approval" = "FEATURE_STATE_OFF"
        "disable-agent-sharing"                = "FEATURE_STATE_OFF"
        "enable-end-user-sharing-with-groups"  = "FEATURE_STATE_OFF"
        "model-selector"                       = "FEATURE_STATE_ON"
        "no-code-agent-builder"                = "FEATURE_STATE_ON"
        "notebook-lm"                          = "FEATURE_STATE_ON"
        "personalization-suggested-highlights" = "FEATURE_STATE_ON"
        "prompt-gallery"                       = "FEATURE_STATE_ON"
        "workflow-agents"                      = "FEATURE_STATE_ON"
      }
      iam = {
        "roles/discoveryengine.agentspaceUser" = local.workforce_principals
      }
      widget_config = {
        enable_web_app                   = true
        workforce_identity_pool_provider = local.workforce_pool_provider
      }
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.discoveryengine_cmek,
    google_org_policy_policy.restrict_allowed_data_sources,
    google_org_policy_policy.restrict_connector_egress_fqdns,
    google_storage_bucket_iam_member.discoveryengine_gcs_reader,
    google_storage_bucket_object.sample_policy_doc,
  ]
}

# ------------------------------------------------------------------------------
# App 2: Restricted Connector Validation & Governance Sandbox App
#        (Shares project seat pool & foundational stores without re-indexing,
#         while isolating unpromoted connectors and disabling agent sharing)
# ------------------------------------------------------------------------------

module "gemini-enterprise-validation" {
  source     = "../../../modules/ai-applications"
  project_id = local.project_id
  name       = "${local.prefix}${var.name}-validation"
  location   = local.location

  engines_configs = {
    data_store_ids = concat(
      [
        module.gemini-enterprise-prod.data_stores["knowledge-store"].data_store_id,
        module.gemini-enterprise-prod.data_stores["reserved-store"].data_store_id,
      ],
      var.enable_gcs_connector ? [
        for entity in module.gemini-enterprise-prod.data_connectors["gcs-knowledge"].entities :
        basename(entity.data_store)
      ] : [],
      var.enable_jira_connector ? [
        for entity in module.gemini-enterprise-prod.data_connectors["jira-enterprise"].entities :
        basename(entity.data_store)
      ] : [],
      var.enable_workspace_connectors ? flatten([
        for k in ["google-drive", "google-mail", "google-calendar", "google-chat"] : [
          for entity in module.gemini-enterprise-prod.data_connectors[k].entities :
          basename(entity.data_store)
        ]
      ]) : []
    )
    search_engine_config = {
      app_type                       = "APP_TYPE_INTRANET"
      company_name                   = var.company_name
      display_name                   = "Gemini Enterprise (Connector Validation)"
      enable_private_knowledge_graph = true
      kms_key                        = local.effective_kms_key
      search_add_ons                 = ["SEARCH_ADD_ON_LLM"]
      search_tier                    = "SEARCH_TIER_ENTERPRISE"
      features = {
        "agent-sharing-without-admin-approval" = "FEATURE_STATE_OFF"
        "disable-agent-sharing"                = "FEATURE_STATE_ON"
        "enable-end-user-sharing-with-groups"  = "FEATURE_STATE_OFF"
        "model-selector"                       = "FEATURE_STATE_ON"
        "no-code-agent-builder"                = "FEATURE_STATE_ON"
        "notebook-lm"                          = "FEATURE_STATE_ON"
        "personalization-suggested-highlights" = "FEATURE_STATE_ON"
        "prompt-gallery"                       = "FEATURE_STATE_ON"
        "workflow-agents"                      = "FEATURE_STATE_ON"
      }
      iam = {
        "roles/discoveryengine.agentspaceUser" = local.validation_principals
      }
      widget_config = {
        enable_web_app                   = true
        workforce_identity_pool_provider = local.workforce_pool_provider
      }
    }
  }
}
