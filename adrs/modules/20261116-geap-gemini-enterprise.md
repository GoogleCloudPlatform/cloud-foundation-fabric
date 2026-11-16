# Dedicated `geap-gemini-enterprise` Module and `ai-applications` Decomposition

**authors:** [Luca Prete](https://github.com/LucaPrete) \
**date:** Nov 16, 2026

## Status

Proposed. Triggered by [#4335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4335) and [#4345](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/discussions/4345), which propose adding Gemini Enterprise resources to [`modules/ai-applications`](../../modules/ai-applications).

## Context

Google exposes three distinct logical products under the `discoveryengine.googleapis.com` API and the `google_discovery_engine_*` Terraform provider namespace:

1. **Vertex AI Search**: standalone search and recommendation engines backed by public websites, GCS documents, BigQuery tables, or structured schemas (`app_type` unset, `SOLUTION_TYPE_SEARCH` / `SOLUTION_TYPE_RECOMMENDATION`).
2. **Conversational Agents (Dialogflow CX)**: chat engines (`SOLUTION_TYPE_CHAT`) paired with `google_dialogflow_cx_agent` and Cloud DLP inspection/de-identification templates.
3. **Gemini Enterprise**: intranet employee applications (`app_type = "APP_TYPE_INTRANET"`) combining search and `default_assistant`, hosted web app and Workforce Identity login (`default_search_widget_config`), location-level identity provider (`aclConfig`) and seat licensing (`default_user_store`), first-party and third-party SaaS and Custom MCP `data_connector`s, app-level `agentspaceUser` IAM, and Egress Agent Gateway governance.

[`modules/ai-applications`](../../modules/ai-applications) currently combines (1) and (2) around a single `count`-based engine (`var.name`), native data stores, and location CMEK configurations. Extending `modules/ai-applications` to also cover Gemini Enterprise, as proposed in [#4335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4335), conflicts with Fabric's core module design principles:

- **API namespace vs. logical entity**: over half of `modules/ai-applications/variables.tf` configures Dialogflow CX agents and Cloud DLP templates (`chat_agent_security_configs`) that never apply to Gemini Enterprise, while website crawling (`sitemap`, `target_site`) and classic search validations (`length(data_store_ids) > 0`) conflict with intranet apps that routinely start with zero data stores or attach SaaS connectors dynamically.
- **Location-tenant vs. single-engine cardinality mismatch**: in Discovery Engine, a multi-region/location (`global`, `us`, `eu`) is the actual Gemini Enterprise tenant boundary. `aclConfig`, `default_user_store`, `cmekConfig`, and `dataConnector` collections are location-scoped singletons or shared resources, while multiple intranet apps (`engines`) coexist in that location and share the same IdP, license pool, CMEK config, and SaaS connectors. Putting location singletons inside a module that manages at most one engine (`count = 0 | 1`) breaks self-contained composition as soon as two or more Gemini Enterprise apps are deployed in the same location.
- **Alignment with `geap-*` modules and `genai-factory`**: Fabric already encapsulates Gemini Enterprise Agent Platform components in dedicated `geap-*` modules ([`modules/geap-agent-gateway`](../../modules/geap-agent-gateway), [`modules/geap-agent-runtime`](../../modules/geap-agent-runtime), [`modules/geap-workbench`](../../modules/geap-workbench)), and [`genai-factory/ge-agent-platform`](https://github.com/GoogleCloudPlatform/genai-factory/tree/main/ge-agent-platform) already validates a location-scoped, multi-app Gemini Enterprise design in end-to-end deployments.

## Decision

### 1. Module Boundaries and Decomposition Roadmap

1. **Immediate — Introduce `modules/geap-gemini-enterprise` and freeze `modules/ai-applications`**:
   - Create a dedicated `modules/geap-gemini-enterprise` module modeling a Gemini Enterprise tenant in a single Discovery Engine location (`global`, `us`, or `eu`) within a project.
   - Leave [`modules/ai-applications`](../../modules/ai-applications) unchanged for now so existing Search and Dialogflow CX callers experience no churn or regressions, and redirect the Gemini Enterprise resources proposed in [#4335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4335) (`acl_config`, `user_store`, intranet `search_engine` attributes, `assistant`, and `widget_config`) into `modules/geap-gemini-enterprise`.
2. **Future phase — Split and retire `modules/ai-applications`**:
   - Decompose `modules/ai-applications` along logical product boundaries into:
     - `modules/geap-search`: standalone Discovery Engine search and recommendation engines, native data stores, schemas, sitemaps, and target sites.
     - `modules/conversational-dialogflow` (or `modules/dialogflow`): Dialogflow CX agents, Discovery Engine chat engines, and DLP security configurations.

### 2. Scope and Resource Ownership of `modules/geap-gemini-enterprise`

One invocation of `modules/geap-gemini-enterprise` manages one `(project_id, location)` Gemini Enterprise tenant:

| Scope | Managed inside `modules/geap-gemini-enterprise` |
|---|---|
| **Location singletons** (auto-ordered via `depends_on` before stores, connectors, and apps) | `google_discovery_engine_acl_config` (`idp_config`: `GSUITE` or `THIRD_PARTY` Workforce Pool), `google_discovery_engine_user_store` (`user_store_config`: `default_user_store` license pool and auto-register/auto-update flags), `google_discovery_engine_cmek_config` (`encryption_config`: `kms_key` and `single_region_keys`). |
| **Shared data sources in location** | Native `google_discovery_engine_data_store` + `google_discovery_engine_schema` (`data_stores`), first-party/third-party SaaS `google_discovery_engine_data_connector` (`data_connectors`), and Custom MCP `google_discovery_engine_data_connector` (`mcp_connectors` with OAuth 2.0 support), linked to one or more apps via `app_ids`. |
| **Applications (`apps` map, keyed by `engine_id`)** | Optional `google_discovery_engine_search_engine` (`app_type = "APP_TYPE_INTRANET"` when `engine != null`; skipped when adopting a Console-created app), `google_discovery_engine_assistant` (`default_assistant`), `google_discovery_engine_widget_config` (`default_search_widget_config`), Egress Agent Gateway binding (`agentGatewaySetting`), and app-level IAM (`google_discovery_engine_search_engine_iam_binding` / `_member`). |

**Explicitly out of scope:**

- **Project-level IAM bindings**: the module only sets IAM on Gemini Enterprise apps (`google_discovery_engine_search_engine_iam_*`). Project-level companion roles—such as `roles/discoveryengine.agentspaceRestrictedUser` (required for app users to reach apps and connectors) or custom Antigravity (`businessaicode.*`) roles—are out of scope and belong in [`modules/project`](../../modules/project) or higher-level blueprints. To simplify caller wiring, the module exposes a deduplicated `app_iam_principals` output containing all project-eligible principals granted roles on any app.
- **Cross-service platform resources**: Model Armor templates, Egress Agent Gateways, Agent Registry services, and Secret Manager secrets stay in their respective modules and are referenced directly or via `var.context`.

### 3. Variable Interface (Adapted from `genai-factory` to Fabric Standards)

The interface adapts the proven `genai-factory/ge-agent-platform` model to standard Fabric conventions (`var.context` interpolation, `var.prefix`, `var.deletion_protection`, map-keyed collections, and standard per-app `iam*` attributes):

```hcl
variable "project_id" {
  description = "Project ID where Gemini Enterprise resources are managed."
  type        = string
  nullable    = false
}

variable "project_number" {
  description = "Optional project number, required when binding an Egress Agent Gateway or routing Custom MCP connectors through it."
  type        = string
  default     = null
}

variable "location" {
  description = "Discovery Engine multi-region location (global, us, or eu)."
  type        = string
  default     = "eu"
  nullable    = false
}

variable "prefix" {
  description = "Optional prefix prepended to created engine, data store, and connector IDs."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying created engines, data stores, and data connectors (sets deletion_policy to PREVENT instead of DELETE)."
  type        = bool
  default     = true
  nullable    = false
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    agent_gateways        = optional(map(string), {})
    condition_vars        = optional(map(any), {})
    custom_roles          = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    kms_keys              = optional(map(string), {})
    locations             = optional(map(string), {})
    model_armor_templates = optional(map(string), {})
    project_ids           = optional(map(string), {})
    secrets               = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "idp_config" {
  description = "Location-level Discovery Engine identity provider (ACL) configuration."
  type = object({
    idp_type            = string # "GSUITE" | "THIRD_PARTY"
    workforce_pool_name = optional(string)
  })
  default = null
}

variable "user_store_config" {
  description = "Location-level default_user_store license assignment configuration."
  type = object({
    default_license_config             = optional(string)
    enable_expired_license_auto_update = optional(bool)
    enable_license_auto_register       = optional(bool)
  })
  default = null
}

variable "encryption_config" {
  description = "Location-level CMEK configuration registered before stores and engines are created."
  type = object({
    kms_key            = string
    set_default        = optional(bool, true)
    single_region_keys = optional(list(string), [])
  })
  default = null
}

variable "egress_agent_gateway" {
  description = "Optional default Egress Agent Gateway resource ID bound to apps unless overridden per app."
  type        = string
  default     = null
}
```

`var.apps` is keyed by logical app key (defaulting `engine_id` to `"${local.prefix}${key}"` when creating an engine, or `key` when `engine = null` adopts an existing Console app):

```hcl
variable "apps" {
  description = "Gemini Enterprise applications, keyed by engine ID. Omit 'engine' to adopt an existing Console-created app while managing its assistant, widget, gateway binding, and IAM."
  type = map(object({
    collection_id        = optional(string, "default_collection")
    egress_agent_gateway = optional(string)
    engine = optional(object({
      display_name               = string
      company_name               = optional(string)
      data_store_ids             = optional(list(string), [])
      disable_analytics          = optional(bool)
      features                   = optional(map(string), {})
      industry_vertical          = optional(string, "GENERIC")
      kms_key                    = optional(string)
      model_configs              = optional(map(string))
      procurement_contact_emails = optional(list(string))
      required_subscription_tier = optional(string)
      search_add_ons             = optional(list(string), ["SEARCH_ADD_ON_LLM"])
      search_tier                = optional(string, "SEARCH_TIER_ENTERPRISE")
      knowledge_graph = optional(object({
        cloud_knowledge_graph_types    = optional(list(string), [])
        enable_cloud_knowledge_graph   = optional(bool, false)
        enable_private_knowledge_graph = optional(bool, false)
        feature_config = optional(object({
          disable_private_kg_auto_complete       = optional(bool)
          disable_private_kg_enrichment          = optional(bool)
          disable_private_kg_query_ui_chips      = optional(bool)
          disable_private_kg_query_understanding = optional(bool)
        }))
      }), {})
    }))
    assistant = optional(object({
      assistant_id                     = optional(string, "default_assistant")
      default_web_grounding_toggle_off = optional(bool)
      description                      = optional(string)
      display_name                     = optional(string, "Default Assistant")
      web_grounding_type               = optional(string)
      banned_phrases = optional(map(object({
        ignore_diacritics = optional(bool)
        match_type        = optional(string)
        phrase            = optional(string)
      })), {})
      generation_config = optional(object({
        default_language   = optional(string)
        system_instruction = optional(string)
      }))
      model_armor_config = optional(object({
        failure_mode         = optional(string, "FAIL_CLOSED")
        response_template    = optional(string, "")
        user_prompt_template = optional(string, "")
      }))
    }))
    widget_config = optional(object({
      widget_config_id = optional(string, "default_search_widget_config")
      access_settings  = optional(object({ ... }))
      homepage_setting = optional(object({ ... }))
      ui_branding      = optional(object({ ... }))
      ui_settings      = optional(object({ ... }))
    }))
    iam                   = optional(map(list(string)), {})
    iam_by_principals     = optional(map(list(string)), {})
    iam_bindings          = optional(map(object({ ... })), {})
    iam_bindings_additive = optional(map(object({ ... })), {})
  }))
  default  = {}
  nullable = false
}
```

`var.data_connectors`, `var.mcp_connectors` (paired with an optional module-level `var.oauth_config` default), and `var.data_stores` manage location-scoped data sources and attach their resulting data stores to every app listed in `app_ids`.

### 4. Discovery Engine API and Provider Lifecycle Workarounds

Verification against `hashicorp/google` (`v8.10.0`–`v8.11.0`) confirms that several Discovery Engine API and provider limitations encountered in `genai-factory/ge-agent-platform` remain unresolved upstream. `modules/geap-gemini-enterprise` adopts the `genai-factory` handling for each of them:

1. **Decoupled `data_store_ids`, companion `NO_CONTENT` store, and connector detach on destroy**:
   - *Upstream constraints*:
     1. Discovery Engine's `UpdateEngine` API rejects `PATCH` requests that set `dataStoreIds` to a list of length `1` (`Error 400: Number of DataStores must be 0 or >= 2`), even though `CreateEngine` accepts a single store.
     2. When a `for_each` entry is removed from `data_connectors` or `mcp_connectors`, Terraform destroys the orphaned `google_discovery_engine_data_connector` concurrently with (or prior to) updating `google_discovery_engine_search_engine` in place, failing with `400 FAILED_PRECONDITION: DataStore ... is still associated with Engines` and preventing targeted connector destruction.
   - *Module behavior*: `google_discovery_engine_search_engine` is created with `data_store_ids = []` and `lifecycle { ignore_changes = [data_store_ids] }`. Whenever an app resolves to exactly `1` attached store, the module creates an empty `NO_CONTENT` companion store (`<app_id>-companion`) and appends it so the list has length `2`. A `terraform_data` resource reconciles engine `dataStoreIds` via a lock-serialized REST `PATCH` (`?updateMask=dataStoreIds`), and each `data_connector` runs a `when = destroy` `PATCH` provisioner to detach its `<collection_id>_*` entity stores from any referencing engine before deletion.
2. **`default_assistant` adoption on `APP_TYPE_INTRANET`**:
   - *Upstream constraint*: unlike `acl_config`, `user_store`, and `widget_config` (which use `PATCH` on create and `exclude_delete: true` in Magic Modules), `google_discovery_engine_assistant` issues `POST .../assistants?assistantId=default_assistant`. Because `CreateEngine` with `APP_TYPE_INTRANET` auto-provisions `default_assistant`, creating both in one apply returns `409 AlreadyExists`.
   - *Module behavior*: `assistant` defaults to `null` (opt-in) so a single-step initial `terraform apply` creating new apps succeeds cleanly; when `assistant` is set, the module enforces `deletion_policy = "ABANDON"` so `default_assistant` is never deleted, and documents importing `default_assistant` (via root `import {}` blocks or `terraform import`) before enabling `assistant`.
3. **Data connector zero-diff import idempotency**:
   - `lifecycle { ignore_changes = [collection_display_name] }` avoids `ForceNew` replacement after `terraform import` (`GetDataConnector` omits `collectionDisplayName` on read).
   - Backend-appended `root` (`outlook`) and `site` (`sharepoint`) entities are automatically synthesized in HCL when omitted by the caller, and excluded from engine `dataStoreIds` attachment.
   - `json_params`, `destination_configs[*].params`, and `entities[*].params` accept either inline JSON or a root-relative file path (`pathexpand`) normalized via `jsonencode(jsondecode(...))`, and cross-resource lookups guard with `contains(keys(...))` so sequential `terraform import` runs succeed.
4. **Egress Agent Gateway engine binding and Custom MCP `actionConfig`**:
   - `google_discovery_engine_search_engine` (`v8.11.0`) does not yet expose `agentGatewaySetting`; when an Egress Agent Gateway is configured on an app, a `terraform_data` resource patches `agentGatewaySetting.defaultEgressAgentGateway.name` on the engine.
   - `google_discovery_engine_data_connector` in `v8.10.0`–`v8.11.0` types `action_config.action_params` as `map(string)`, serializing booleans such as `use_agent_gateway_egress`, `pkce_support_enabled`, and `client_secret_basic_override` as strings ignored by the API. *(Upstream `magic-modules` has added `action_config.json_action_params` post-`v8.11.0`; until Fabric's minimum provider version includes `v8.12.0+` and `setUpDataConnectorV2` behavior with `agent_gateway_engine` is verified, `mcp_connectors` retains the `terraform_data` `actionConfig` `PATCH` with `INITIALIZING` retry and retires the shim once `json_action_params` is available.)*

## Consequences

- **`modules/ai-applications` stays stable in the short term**, avoiding breaking changes or Dialogflow/Search coupling while `modules/geap-gemini-enterprise` is built. Contributors from [#4335](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4335) can port `acl_config`, `user_store`, `assistant`, and `widget_config` into the new module.
- **Clear long-term taxonomy**: once `modules/geap-search` and `modules/conversational-dialogflow` (or `modules/dialogflow`) are extracted, `modules/ai-applications` can be deprecated cleanly, leaving every Discovery Engine product mapped to a cohesive logical-entity module.
- **Direct reuse in `genai-factory`**: `ge-agent-platform/1-apps` can replace `gemini-enterprise-apps.tf` and `gemini-enterprise-ds.tf` with a single `modules/geap-gemini-enterprise` call, while keeping project-level IAM (`roles/discoveryengine.agentspaceRestrictedUser` driven by `module.gemini_enterprise.app_iam_principals`, plus Antigravity), Agent Registry, and Model Armor templates at the stage layer.
- **Scoped, temporary `local-exec` exception**: `modules/geap-gemini-enterprise` introduces a documented exception to Fabric's zero-`local-exec` convention (`curl`, `gcloud`, and `jq` required at apply/destroy time when attaching data stores/connectors or binding an Egress Agent Gateway). Each `terraform_data` shim is isolated and tagged for removal as `hashicorp/google` and Discovery Engine resolve the underlying API/schema gaps.
