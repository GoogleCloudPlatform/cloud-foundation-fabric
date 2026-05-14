# Fabric FAST: YAML Configuration Reference

This reference guide provides a comprehensive, tabular breakdown of all configurable properties across the Fabric FAST `2-project-factory` stage, derived from the JSON schemas present in the schemas/ folder.

---

## 1. Project Configuration (`projects/*.yaml`)

| Property | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `name` | String | The actual project name. | `name: "My App"` |
| `descriptive_name` | String | Optional longer descriptive name for the project. | `descriptive_name: "Team A Production App"` |
| `parent` | String | The parent folder or organization ID (supports context). | `parent: $folder_ids:team-a` |
| `prefix` | String | Optional prefix to prepend to the project ID. | `prefix: "cmp"` |
| `billing_account` | String | The billing account ID to attach. | `billing_account: 012345-678901-ABCDEF` |
| `billing_budgets` | Array | List of budget template IDs to link to this project. | `billing_budgets: ["app-prod-budget"]` |
| `project_template` | String | Path to a template YAML file to inherit baseline config. | `project_template: "templates/web-app.yaml"` |
| `project_reuse` | Object | Rules for adopting an existing project instead of creating. | `project_reuse:`<br>`  use_data_source: true`<br>`  attributes: {name: "...", number: 123}` |
| `labels` | Object | Key-value pairs for GCP labels. | `labels:`<br>`  env: "prod"` |
| `tags` / `tag_bindings` | Object | Defines tag keys/values or binds existing tags. | `tag_bindings:`<br>`  environment: $tag_values:env/prod` |
| `iam` | Object | Authoritative IAM bindings grouped by role. | `iam:`<br>`  roles/viewer: ["group:abc@def.com"]` |
| `iam_bindings` | Object | Additive IAM bindings with optional conditions. | `iam_bindings:`<br>`  my_binding:`<br>`    role: "roles/viewer"`<br>`    members: ["user:a@b.com"]` |
| `iam_bindings_additive`| Object | Individual additive IAM bindings without removing others. | `iam_bindings_additive:`<br>`  my_binding:`<br>`    role: "roles/viewer"`<br>`    member: "user:a@b.com"` |
| `iam_by_principals` | Object | Authoritative IAM bindings grouped by principal (user/SA). | `iam_by_principals:`<br>`  "group:abc@def.com": ["roles/viewer"]` |
| `automation` | Object | Configures CI/CD project, SAs, and state buckets. | `automation:`<br>`  project: $project_ids:iac-core-0` |
| `service_accounts` | Object | Creates custom service accounts local to the project. | `service_accounts:`<br>`  my-sa:`<br>`    display_name: "App SA"` |
| `buckets` | Object | Creates GCS buckets local to the project. | `buckets:`<br>`  my-bucket:`<br>`    location: "EU"` |
| `datasets` | Object | Creates BigQuery datasets local to the project. | `datasets:`<br>`  my_dataset:`<br>`    location: "EU"` |
| `pubsub_topics` | Object | Creates Pub/Sub topics and subscriptions local to project. | `pubsub_topics:`<br>`  my-topic:`<br>`    message_retention_duration: "86400s"` |
| `kms` | Object | Configures CMEK keyrings and crypto keys. | `kms:`<br>`  keyrings:`<br>`    my-ring: {location: "global"}` |
| `vpc_sc` | Object | Adds the project to a VPC Service Controls perimeter. | `vpc_sc:`<br>`  perimeter_name: "my_perimeter"`<br>`  is_dry_run: false` |
| `shared_vpc_service_config` | Object | Attaches project to a Shared VPC host. | `shared_vpc_service_config:`<br>`  host_project: $vpc_host_projects:core` |
| `workload_identity_pools` | Object | Configures WIF pools and AWS/OIDC/SAML providers. | `workload_identity_pools:`<br>`  my-pool: {display_name: "Pool"}` |
| `log_buckets` | Object | Creates localized Logging buckets and analytics. | `log_buckets:`<br>`  my-log:`<br>`    location: "global"` |
| `metric_scopes` | Array | Scoping projects to include in Cloud Monitoring. | `metric_scopes: ["$project_ids:other"]` |
| `org_policies` | Object | Project-level organization policy overrides. | `org_policies:`<br>`  "compute.disableNestedVirtualization":`<br>`    rules: [{enforce: true}]` |
| `pam_entitlements` | Object | Privileged Access Management (PAM) just-in-time access. | `pam_entitlements:`<br>`  entitlement-a:`<br>`    max_request_duration: "3600s"` |
| `dns_threat_detector` | Object | Configures Cloud DNS threat detection (e.g., Infoblox). | `dns_threat_detector:`<br>`  enabled: true` |
| `quotas` | Object | Manages consumer quota overrides. | `quotas:`<br>`  my-quota:`<br>`    service: "compute.googleapis.com"`<br>`    quota_id: "CPUS-per-project"`<br>`    preferred_value: 50` |
| `data_access_logs` | Object | Configures detailed audit logging (Admin Read, Data Write). | `data_access_logs:`<br>`  "allServices": { DATA_READ: {} }` |
| `asset_feeds` | Object | Cloud Asset Inventory feed configurations to Pub/Sub. | `asset_feeds:`<br>`  my-feed:`<br>`    feed_output_config: ...` |
| `factories_config` | Object | Base paths for nested factory files specific to project. | `factories_config:`<br>`  org_policies: "policies/"` |
| `universe` | Object | Specifies the GCP universe (for air-gapped/sovereign clouds). | `universe:`<br>`  prefix: "my-universe"` |
| `deletion_policy` | String | Protection policy: PREVENT, DELETE, or ABANDON. | `deletion_policy: "PREVENT"` |

---

## 2. Folder Configuration (`folders/**/*.yaml`)

| Property | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `name` | String | The actual display name of the folder. | `name: "Teams"` |
| `id` | String | Explicit ID mapping (if importing an existing folder). | `id: "folders/123456789"` |
| `parent` | String | Overrides filesystem tree to explicitly set parent folder. | `parent: $folder_ids:teams` |
| `billing_budgets` | Array | Links budget definitions to the folder scope. | `billing_budgets: ["folder-budget"]` |
| `automation` | Object | Sets up IaC controlling project config at the folder level. | `automation:`<br>`  project: $project_ids:iac-0` |
| `autokey_config` | Object | Configures KMS Autokey project destination. | `autokey_config:`<br>`  project: $project_ids:kms-0` |
| `deletion_protection` | Boolean | Prevents accidental deletion of the folder via Terraform. | `deletion_protection: true` |
| `firewall_policy` | Object | Attaches a hierarchical firewall policy to the folder. | `firewall_policy:`<br>`  name: "my-policy"`<br>`  policy: "12345"` |
| `logging` | Object | Centralized folder-level log sinks to GCS/BQ/PubSub. | `logging:`<br>`  sinks:`<br>`    audit-logs: {destination: "..."}` |
| `assured_workload_config` | Object | Sets up compliance regimes (e.g., FedRAMP, HIPAA). | `assured_workload_config:`<br>`  compliance_regime: "HIPAA"` |
| `org_policies` | Object | Folder-level organization policies. | `org_policies:`<br>`  "compute.requireOsLogin": ...` |
| `tag_bindings` | Object | Binds resource manager tags to the folder. | `tag_bindings:`<br>`  environment: $tag_values:env/prod` |
| `pam_entitlements` | Object | PAM access configurations at the folder scope. | `pam_entitlements:`<br>`  admin-access: {max_request_duration: ...}`|
| `asset_search` | Object | Cloud Asset Inventory search configurations. | `asset_search:`<br>`  my-search: {query: "..."}` |
| `asset_feeds` | Object | Cloud Asset Inventory feed configurations to Pub/Sub. | `asset_feeds:`<br>`  my-feed: {billing_project: "..."}` |
| `data_access_logs` | Object | Configures audit logging for folder resources. | `data_access_logs:`<br>`  "allServices": { DATA_READ: {} }` |
| `iam`, `iam_*` | Object | All IAM mapping structures (authoritative, additive, etc.) | `iam:`<br>`  roles/viewer: ["group:a@b.com"]` |
| `contacts` | Object | Essential contacts for the folder (e.g., Security, Billing). | `contacts:`<br>`  "sec@my.com": ["SECURITY"]` |
| `factories_config` | Object | Paths to external config files (policies, PAM). | `factories_config:`<br>`  org_policies: "..."` |

---

## 3. Budget Configuration (`budgets/*.yaml`)

| Property | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `amount` | Object | The budget limit (currency, nanos, units) or last period. | `amount:`<br>`  units: 1000`<br>`  currency_code: "USD"` |
| `display_name` | String | The name of the budget alert. | `display_name: "Prod Budget"` |
| `filter` | Object | Filters for specific projects, services, or credit types. | `filter:`<br>`  projects: ["$project_ids:my-app"]` |
| `threshold_rules` | Array | Percentage thresholds that trigger alerts. | `threshold_rules:`<br>`  - percent: 0.5`<br>`  - percent: 0.9`<br>`    forecasted_spend: true` |
| `update_rules` | Object | Pub/Sub topics and monitoring notification channels. | `update_rules:`<br>`  my-rule:`<br>`    pubsub_topic: "projects/x/topics/y"` |

---

## 4. Tags Configuration (`tags/*.yaml`)

| Property | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `name` | String | The tag key name. | `name: "environment"` |
| `description` | String | Tag description. | `description: "Deployment environment"` |
| `id` | String | Explicit ID for importing existing tags. | `id: "tagKeys/123"` |
| `network` | String | Network scoping for the tag (if firewall-related). | `network: "my-vpc"` |
| `allowed_values_regex`| String | Validation regex for values (mutually exclusive with values). | `allowed_values_regex: "^(prod\|dev)$"` |
| `values` | Object | Static tag values mapped under this key. | `values:`<br>`  prod: {description: "Production"}` |
| `iam`, `iam_*` | Object | IAM roles applied directly to the tag key or tag value. | `iam:`<br>`  roles/resourcemanager.tagUser: [...]` |

---

## 5. Aspect Type Configuration (`aspect-types/*.yaml`)

| Property | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `display_name` | String | The name of the Dataplex Aspect Type. | `display_name: "Data Quality"` |
| `description` | String | Aspect description. | `description: "Tracks DQ scores"` |
| `labels` | Object | Key-value pairs. | `labels: {team: "data"}` |
| `metadata_template` | String | JSON/YAML string defining the aspect schema. | `metadata_template: "{\\"type\\":\\"record\\"..."` |
| `iam`, `iam_*` | Object | IAM binding configurations. | `iam: ...` |

---

## 6. Stage Defaults (`defaults.yaml`)

| Property | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `projects.defaults` | Object | Fallback values applied if missing in `projects/*.yaml`. | `projects:`<br>`  defaults:`<br>`    billing_account: "123"` |
| `projects.merges` | Object | Additive arrays/objects merged with `projects/*.yaml` data. | `projects:`<br>`  merges:`<br>`    services: ["compute.googleapis.com"]` |
| `projects.overrides`| Object | Hard overrides that ignore what is in `projects/*.yaml`. | `projects:`<br>`  overrides:`<br>`    prefix: "cmp"` |
| `vpcs.defaults` | Object | Fallback configurations for Shared VPCs. | `vpcs:`<br>`  defaults:`<br>`    routing_mode: "GLOBAL"` |
| `vpcs.overrides` | Object | Hard overrides for VPC properties. | `vpcs:`<br>`  overrides:`<br>`    mtu: 1460` |
| `context` | Object | Hardcoded mapping of context interpolations (e.g., `$folder_ids:`).| `context:`<br>`  folder_ids: {team-a: "folders/12"}` |
| `output_files` | Object | Configures automated generation of `.tf` and `.tfvars` files. | `output_files:`<br>`  local_path: "~/fast-config"` |
