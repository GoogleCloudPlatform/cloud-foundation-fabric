# Gemini Enterprise Project Template

> **Disclaimer:** Always treat the official [HashiCorp Google Terraform Provider (`hashicorp/google`)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/discovery_engine_search_engine) documentation and official [Google Cloud Gemini Enterprise documentation](https://cloud.google.com/gemini/enterprise/docs/create-app) as the authoritative reference. Conduct a thorough security and architecture review before deploying to production.

This FAST project template deploys an opinionated [Gemini Enterprise](https://cloud.google.com/gemini/enterprise/docs) environment inside a single regional Google Cloud project. It composes the [`ai-applications`](../../../modules/ai-applications/) module with project-level organization policies, Model Armor floor settings, and optional Cloud KMS Customer-Managed Encryption Keys (CMEK).

<!-- BEGIN TOC -->
- [Architecture and design choices](#architecture-and-design-choices)
  - [Two-app validation topology in a shared project](#two-app-validation-topology-in-a-shared-project)
  - [4-control-point governance and HITL enforcement](#4-control-point-governance-and-hitl-enforcement)
- [Prerequisites and project factory setup](#prerequisites-and-project-factory-setup)
- [Operational notes and provider gotchas](#operational-notes-and-provider-gotchas)
- [Example](#example)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Architecture and design choices

### Two-app validation topology in a shared project

Rather than duplicating document ingestion and seat pools across separate projects, this template deploys two Gemini Enterprise (`APP_TYPE_INTRANET`) applications inside the same regional project:

- **Primary Production Workforce App (`gemini-enterprise-prod`):** Exposes only vetted, promoted foundational data stores (`enterprise-knowledge-store` and `enterprise-reserved-store`) to workforce users via `roles/discoveryengine.agentspaceUser`, with unapproved agent sharing blocked (`agent-sharing-without-admin-approval = "FEATURE_STATE_OFF"`).
- **Restricted Connector Validation App (`gemini-enterprise-validation`):** Attaches both the foundational stores and newly provisioned 1P/3P data connectors (such as the periodic Cloud Storage connector and Jira Cloud Federated/Actions connector), disables agent sharing (`disable-agent-sharing = "FEATURE_STATE_ON"`), and restricts `roles/discoveryengine.agentspaceUser` to platform administrators for Human-in-the-Loop (HITL) and ACL verification before promoting a connector to the production app's `data_store_ids`.

### 4-control-point governance and HITL enforcement

1. **Control Point 1 (Project Perimeter Guardrails & Audit Logging):** Enforces 3 project-level `discoveryengine.managed.*` organization policies (`disableCustomMcpServerConnector`, `allowedDataSources`, and `allowedEgressFqdns`), project-wide Data Access Audit Logs (`ADMIN_READ`, `DATA_READ`, and `DATA_WRITE` on `discoveryengine.googleapis.com` and `aiplatform.googleapis.com`), and a global `google_model_armor_floorsetting` (`enable_cloud_logging = true`) across `AI_PLATFORM` and `GOOGLE_MCP_SERVER`.
2. **Control Point 2 (Explicit Action Allowlisting):** Declares an explicit `bap_config.enabled_actions` allowlist on action-capable connectors (`google_discovery_engine_data_connector`) so newly introduced catalog actions remain disabled until added in Terraform, while enabled write actions still require end-user HITL confirmation at runtime.
3. **Control Point 3 (App-Scoped Promotion & IAM):** Uses `google_discovery_engine_search_engine_iam_binding` (`roles/discoveryengine.agentspaceUser`) and `google_discovery_engine_widget_config` to isolate workforce users from unvalidated connectors.
4. **Control Point 4 (Zero-Drift Lifecycle & Seat Provisioning):** Automatically provisions `google_discovery_engine_user_store` (`enable_license_auto_register = true`) with either an existing billing subscription or a 30-day `free_trial_gemini` `google_discovery_engine_license_config` so users do not encounter `400: You are not assigned an active license` on first login.

## Prerequisites and project factory setup

The [`project.yaml`](./project.yaml) file defines the project-level APIs, Data Access Audit Logs, IAM bindings, and organization policies in [FAST Project Factory](../../stages/2-project-factory/) format. When deploying through the project factory, set `enforce_org_policies = false` and `enable_audit_logs = false` on this template so the project factory owns the 3 `discoveryengine.managed.*` policies and `data_access_logs`.

Official Google Cloud Terraform references for Gemini Enterprise:

- [Create an app using Terraform](https://cloud.google.com/gemini/enterprise/docs/create-app)
- [Create a data store using Terraform](https://cloud.google.com/gemini/enterprise/docs/connectors/connect-terraform)
- [Configure CMEK for Gemini Enterprise](https://cloud.google.com/gemini/enterprise/docs/cmek)

## Operational notes and provider gotchas

- **Default-on agent observability and audit log enforcement (`enable_audit_logs`):** Newly created Gemini Enterprise apps and newly created end-user agents (low-code, workflow, Deep Research, and custom chat agents) automatically initialize baseline observability on by default (`observability_enabled = true`, `sensitive_logging_enabled = false`), and workforce users in the Gemini Enterprise web app cannot disable it. To enforce immutable platform-level logging via Terraform, this template configures `google_project_iam_audit_config` (`ADMIN_READ`, `DATA_READ`, and `DATA_WRITE`) across `discoveryengine.googleapis.com` and `aiplatform.googleapis.com` alongside `enable_cloud_logging = true` on `google_model_armor_floorsetting`. Platform teams can also block Cloud Console administrators from turning off app-level observability by attaching an organization-level `google_org_policy_custom_constraint` targeting `discoveryengine.googleapis.com/Engine` (`action_type = "DENY"`, `method_types = ["CREATE", "UPDATE"]`, `condition = "resource.observabilityConfig.observabilityEnabled == false"`). Note that `observability_config` is not yet exposed on `google_discovery_engine_search_engine` in `hashicorp/google` (so opting in to `sensitive_logging_enabled = true` for raw prompt/response capture requires the Cloud Console or REST API), and Custom Organization Policy support for individual `discoveryengine.googleapis.com/Agent` resources is not yet available in production.
- **Cloud Console Location picker default (`global` vs `us` / `eu`):** The Gemini Enterprise Apps page in the Google Cloud Console defaults its Location dropdown to `global`. When deploying in `location = "us"` or `"eu"`, switch the Console Location dropdown from `global` to `us` or `eu` to view the provisioned applications.
- **Google Workspace federated & actions connectors (`enable_workspace_connectors`):** Setting `enable_workspace_connectors = true` provisions the four first-party Google Workspace connectors (`google_drive`, `google_mail`, `google_calendar`, and `google_chat`) with `refresh_interval = "0s"` and `auto_run_disabled = true`. Federated search (`["FEDERATED"]`) and `google_chat` actions (`["FEDERATED", "ACTIONS"]`) work without a customer OAuth client; passing `workspace_oauth_config = { client_id = "...", client_secret_id = "..." }` (configured with redirect URI `https://vertexaisearch.cloud.google.com/oauth-redirect`) also enables `ACTIONS` on Drive, Gmail, and Calendar.
- **Unstructured Cloud Storage connector (`auto_generate_ids = false`):** When configuring `google_discovery_engine_data_connector` with `data_source = "gcs"` and `data_schema = "content"`, always set `auto_generate_ids = false` inside `entities[*].params` so scheduled `RunOnce` imports hash document IDs from the GCS URI without failing connector validation.
- **Parameterized organization policy concurrency:** Applying multiple `google_org_policy_policy` resources on the same project in parallel returns `409 CONCURRENT_POLICY_CHANGES`. This template chains them sequentially via `depends_on` and formats `enforcedProjects` entries with the required trailing slash (`projects/<project_id>/`).

## Example

```hcl
module "gemini-enterprise" {
  source     = "./fabric/fast/project-templates/gemini-enterprise"
  project_id = "$project_ids:ai-prod"
  location   = "$locations:primary"
  context = {
    iam_principals = {
      ai-admins = "group:ai-platform-admins@example.com"
      workforce = "domain:example.com"
    }
    locations = {
      primary = "us"
    }
    project_ids = {
      ai-prod = "prod-ai-gemini-enterprise-0"
    }
  }
  validation_app_principals = ["$iam_principals:ai-admins"]
  workforce_app_principals  = ["$iam_principals:workforce"]
}
# tftest modules=3 resources=22
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L192) | Target Google Cloud project ID for Gemini Enterprise. | <code>string</code> | ✓ |  |
| [validation_app_principals](variables.tf#L198) | IAM principals granted roles/discoveryengine.agentspaceUser on the restricted Connector Validation app. | <code>list&#40;string&#41;</code> | ✓ |  |
| [workforce_app_principals](variables.tf#L204) | IAM principals granted roles/discoveryengine.agentspaceUser on the primary Production Workforce app. | <code>list&#40;string&#41;</code> | ✓ |  |
| [allowed_data_sources](variables.tf#L17) | Approved connector data_source types enforced by constraints/discoveryengine.managed.allowedDataSources. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#8230;&#93;</code> |
| [allowed_egress_fqdns](variables.tf#L37) | Approved outbound FQDNs (including OAuth token hosts and MCP endpoints) enforced by constraints/discoveryengine.managed.allowedEgressFqdns. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#8230;&#93;</code> |
| [company_name](variables.tf#L49) | Organization display name shown in Gemini Enterprise. | <code>string</code> |  | <code>&#34;Example Enterprise&#34;</code> |
| [context](variables.tf#L56) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [enable_audit_logs](variables.tf#L68) | Whether to configure project-level Data Access Audit Logs (ADMIN_READ, DATA_READ, DATA_WRITE) on discoveryengine.googleapis.com and aiplatform.googleapis.com in this template (set false when managed via data_access_logs in project.yaml). | <code>bool</code> |  | <code>true</code> |
| [enable_cmek](variables.tf#L75) | Whether to provision and bind a regional Cloud KMS CMEK configuration (initial CMEK Spanner provisioning takes 20 to 45 minutes). | <code>bool</code> |  | <code>false</code> |
| [enable_free_trial_license](variables.tf#L82) | Whether to provision a 30-day Gemini Enterprise free_trial_gemini LicenseConfig and auto-assign seats via default_user_store when license_config_name is null. | <code>bool</code> |  | <code>true</code> |
| [enable_gcs_connector](variables.tf#L89) | Whether to provision a Cloud Storage knowledge bucket and periodic GCS DataConnector with auto_generate_ids = false for unstructured documents. | <code>bool</code> |  | <code>true</code> |
| [enable_jira_connector](variables.tf#L96) | Whether to provision the 3P Jira Cloud Federated and Actions DataConnector with an explicit bap_config.enabled_actions HITL allowlist. | <code>bool</code> |  | <code>false</code> |
| [enable_model_armor](variables.tf#L103) | Whether to configure project-wide Model Armor floor settings across Vertex AI and MCP server calls. | <code>bool</code> |  | <code>true</code> |
| [enable_workspace_connectors](variables.tf#L110) | Whether to provision the 1P Google Workspace federated connectors (Google Drive, Gmail, Google Calendar, and Google Chat). | <code>bool</code> |  | <code>false</code> |
| [enforce_org_policies](variables.tf#L117) | Whether to manage the 3 discoveryengine.managed.* project-level organization policies in this template (set false when managed in project.yaml). | <code>bool</code> |  | <code>true</code> |
| [idp_config](variables.tf#L124) | Identity provider configuration for Gemini Enterprise ACLs and Web App SSO (GSUITE or THIRD_PARTY Workforce Identity Federation). | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [jira_config](variables.tf#L148) | Jira Cloud Federated and Actions connector configuration when enable_jira_connector is true. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [license_config_name](variables.tf#L162) | Optional existing LicenseConfig resource name (projects/.../locations/.../licenseConfigs/...) for automatic seat assignment. | <code>string</code> |  | <code>null</code> |
| [location](variables.tf#L168) | Gemini Enterprise multi-region location (us, eu, or global). | <code>string</code> |  | <code>&#34;us&#34;</code> |
| [name](variables.tf#L175) | Base name for the Gemini Enterprise engines and supporting resources. | <code>string</code> |  | <code>&#34;gemini-enterprise&#34;</code> |
| [prefix](variables.tf#L182) | Optional prefix for resource names. | <code>string</code> |  | <code>null</code> |
| [workspace_oauth_config](variables.tf#L210) | Optional Web Application OAuth 2.0 client configuration (redirect URI https://vertexaisearch.cloud.google.com/oauth-redirect) to enable write ACTIONS on Google Drive, Gmail, and Google Calendar connectors when enable_workspace_connectors is true. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cmek_key_id](outputs.tf#L17) | Cloud KMS crypto key ID used for Discovery Engine CMEK encryption. |  |
| [data_store_ids](outputs.tf#L22) | Foundational Discovery Engine data store IDs created in the project. |  |
| [gcs_corpus_bucket](outputs.tf#L27) | Cloud Storage bucket backing the periodic GCS knowledge connector. |  |
| [production_app_id](outputs.tf#L32) | Primary Production Workforce Gemini Enterprise engine resource ID. |  |
| [production_web_app_url](outputs.tf#L37) | Web App URL for the Primary Production Workforce Gemini Enterprise app. |  |
| [validation_app_id](outputs.tf#L42) | Restricted Connector Validation Gemini Enterprise engine resource ID. |  |
| [validation_web_app_url](outputs.tf#L47) | Web App URL for the Restricted Connector Validation Gemini Enterprise app. |  |
<!-- END TFDOC -->
