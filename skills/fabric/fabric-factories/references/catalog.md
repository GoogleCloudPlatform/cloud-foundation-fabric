# Fabric Factories Catalog

Self-contained consumer reference of Cloud Foundation Fabric modules and FAST stages that load YAML factory data. Fetch the exact schema for your pinned Fabric release via `python3 scripts/factory_tools.py fetch <name> [--stage] --ref <tag>`.

## Module Factories (`modules/<module>/schemas/`)

Each row maps one `factories_config` key. **Primary Resource = Pure factory** indicates a module built specifically to provision multiple top-level resources from YAML datasets; all other rows are **in-module factories** managing child resources under a single primary entity.

| Module | Primary Resource | `factories_config` Key | Managed Resources | Key Module Inputs | Schema (`schemas/<file>`) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `analytics-hub` | Analytics Hub Exchange | `listings` (folder, `*.yaml`) | Analytics Hub Listings | `project_id`, `region` | — |
| `billing-account` | Billing Account | `budgets_data_path` (folder, `**/*.yaml`) | Billing Budgets | `id`, `context` | `budget.schema.json` |
| `data-catalog-policy-tag` | Data Catalog Taxonomy | `taxonomy` (file) | Data Catalog Policy Tags | `project_id`, `location`, `context` | `policy-tag.schema.json` |
| `data-catalog-tag` | Pure factory | `tags` (folder, `*.yaml`) | Data Catalog Tags | `tags` (merged) | — |
| `data-catalog-tag-template` | Pure factory | `tag_templates` (folder, `**/*.yaml`) | Tag Templates | `project_id`, `region`, `tag_templates` | `tag-template.schema.json` |
| `dataplex-aspect-types` | Pure factory | `aspect_types` (folder, `**/*.yaml`) | Dataplex Aspect Types | `project_id`, `location`, `context` | `aspect-type.schema.json` |
| `dataplex-datascan` | DataScan | `data_quality_spec` (file) | Data Quality Spec (Rules) | `project_id`, `region` | — |
| `dns-response-policy` | DNS Response Policy | `rules` (file) | Response Policy Rules | `project_id`, `name`, `context` | — |
| `folder` | Folder | `org_policies` (folder, `*.yaml`) | Organization Policies | `id`, `context` | `org-policies.schema.json` |
| `folder` | Folder | `pam_entitlements` (folder, `*.yaml`) | PAM Entitlements | `id`, `context` | `pam-entitlements.schema.json` |
| `folder` | Folder | `scc_mute_configs` (folder, `*.yaml`) | SCC Mute Configs | `id` | `scc-mute-config.schema.json` |
| `folder` | Folder | `scc_sha_custom_modules` (folder, `*.yaml`) | SCC SHA Custom Modules | `id` | `scc-sha-custom-modules.schema.json` |
| `net-cloud-armor` | Cloud Armor Security Policy | `rules_file_path` (file) | Security Policy Rules | `name`, `parent_id`, `region`, `context` | `rules.schema.json` |
| `net-firewall-policy` | Firewall Policy | `cidr_file_path` (file) | Named CIDR Ranges (interpolated into rules) | — | — |
| `net-firewall-policy` | Firewall Policy | `egress_mirroring_rules_file_path` (file) | Egress Packet Mirroring Rules | `name`, `parent_id`, `region`, `context` | `firewall-policy-mirroring-rules.schema.json` |
| `net-firewall-policy` | Firewall Policy | `egress_rules_file_path` (file) | Egress Firewall Rules | `name`, `parent_id`, `region`, `context` | `firewall-policy-rules.schema.json` |
| `net-firewall-policy` | Firewall Policy | `ingress_mirroring_rules_file_path` (file) | Ingress Packet Mirroring Rules | `name`, `parent_id`, `region`, `context` | `firewall-policy-mirroring-rules.schema.json` |
| `net-firewall-policy` | Firewall Policy | `ingress_rules_file_path` (file) | Ingress Firewall Rules | `name`, `parent_id`, `region`, `context` | `firewall-policy-rules.schema.json` |
| `net-swp` | Secure Web Proxy | `policy_rules` (folder, `**/*.yaml`) | Proxy Policy Rules | `project_id`, `region`, `name`, `policy_rules_contexts` | `policy-rule.schema.json` |
| `net-swp` | Secure Web Proxy | `url_lists` (folder, `**/*.yaml`) | Proxy URL Lists | `project_id`, `region` | `url-list.schema.json` |
| `net-vpc` | VPC Network | `internal_ranges_folder` (folder, `**/*.yaml`) | Internal Ranges | `project_id`, `name`, `context` | `internal-range.schema.json` |
| `net-vpc` | VPC Network | `subnets_folder` (folder, `**/*.yaml`) | Subnets (and Subnet IAM) | `project_id`, `name`, `context` | `subnet.schema.json` |
| `net-vpc-factory` | Pure factory | `paths.vpcs` (under `basepath`, `**/.config.yaml` + `subnets/`, `firewall-rules/`) | VPCs, Subnets, VPC Firewall Rules | `context`, `data_defaults`, `data_overrides` | `vpc-factory.schema.json`, `subnet.schema.json`, `firewall-rules.schema.json` |
| `net-vpc-firewall` | Pure factory | `cidr_tpl_file` (file) | Named CIDR Ranges (merged with `named_ranges`) | `named_ranges` | — |
| `net-vpc-firewall` | Pure factory | `rules_folder` (folder, `**/*.yaml`) | VPC Firewall Rules | `project_id`, `network`, `context` | `firewall-rules.schema.json` |
| `organization` | Organization | `access_levels` (folder, `*.yaml`) | Context-Aware Access Levels | `access_policy`, `context` | `access-level.schema.json` |
| `organization` | Organization | `custom_roles` (folder, `*.yaml`) | Custom IAM Roles | `organization_id` | `custom-role.schema.json` |
| `organization` | Organization | `org_policies` (folder, `*.yaml`) | Organization Policies | `organization_id`, `context` | `org-policies.schema.json` |
| `organization` | Organization | `org_policy_custom_constraints` (folder, `*.yaml`) | Org Policy Custom Constraints | `organization_id`, `context` | `org-policy-custom-constraint.schema.json` |
| `organization` | Organization | `pam_entitlements` (folder, `*.yaml`) | PAM Entitlements | `organization_id`, `context` | `pam-entitlements.schema.json` |
| `organization` | Organization | `scc_mute_configs` (folder, `*.yaml`) | SCC Mute Configs | `organization_id` | `scc-mute-config.schema.json` |
| `organization` | Organization | `scc_sha_custom_modules` (folder, `*.yaml`) | SCC SHA Custom Modules | `organization_id` | `scc-sha-custom-modules.schema.json` |
| `organization` | Organization | `tags` (folder, `*.yaml`) | Resource Manager Tags (Keys, Values, IAM) | `organization_id`, `tags_config`, `context` | `tags.schema.json` |
| `project` | Project | `custom_roles` (folder, `*.yaml`) | Custom IAM Roles | `name` / `project_id` | `custom-role.schema.json` |
| `project` | Project | `observability` (folder, `*.yaml`) | Alert Policies, Logging Metrics, Notification Channels | `name` / `project_id`, `context` | `observability.schema.json` |
| `project` | Project | `org_policies` (folder, `*.yaml`) | Organization Policies | `name` / `project_id`, `context` | `org-policies.schema.json` |
| `project` | Project | `pam_entitlements` (folder, `*.yaml`) | PAM Entitlements | `name` / `project_id`, `context` | `pam-entitlements.schema.json` |
| `project` | Project | `quotas` (folder, `*.yaml`) | Cloud Quotas Preferences | `name` / `project_id`, `context` | `quotas.schema.json` |
| `project` | Project | `scc_mute_configs` (folder, `*.yaml`) | SCC Mute Configs | `name` / `project_id` | `scc-mute-config.schema.json` |
| `project` | Project | `scc_sha_custom_modules` (folder, `*.yaml`) | SCC SHA Custom Modules | `name` / `project_id` | `scc-sha-custom-modules.schema.json` |
| `project` | Project | `tags` (folder, `*.yaml`) | Resource Manager Tags (Keys, Values, IAM) | `name` / `project_id`, `tags_config`, `context` | `tags.schema.json` |
| `project-factory` | Pure factory | `paths.budgets` (under `basepath`, `**/*.yaml`) | Billing Budgets (via `billing-account`) | `factories_config.budgets.billing_account`, `context` | `budget.schema.json` |
| `project-factory` | Pure factory | `paths.folders` (under `basepath`, `**/**/.config.yaml`) | Folders (up to 4 levels; delegates per-folder `factories_config`) | `folders`, `context` | `folder.schema.json` |
| `project-factory` | Pure factory | `paths.project_templates` (under `basepath`, `**/*.yaml`) | Project Templates (inherited by project YAML files) | — | `project.schema.json` |
| `project-factory` | Pure factory | `paths.projects` (under `basepath`, `**/*.yaml`) | Projects, SAs, Buckets, KMS, Pub/Sub, BigQuery, Aspect Types, Taxonomies | `projects`, `context`, `data_defaults`, `data_merges`, `data_overrides`, `notification_channels` | `project.schema.json` (sub-factories: `aspect-type.schema.json`, `taxonomy.schema.json`) |
| `secops-rules` | Pure factory | `reference_lists` (file) + `reference_lists_defs` (`<key>.txt`) | SecOps Reference Lists | `project_id`, `tenant_config`, `reference_lists_config` | — |
| `secops-rules` | Pure factory | `rules` (file) + `rules_defs` (`*.yaral`) | SecOps Detection Rules | `project_id`, `tenant_config`, `rules_config` | — |
| `vpc-sc` | Access Policy | `access_levels` (folder, `**/*.yaml`) | Access Levels | `access_policy`, `context` | `access-level.schema.json` |
| `vpc-sc` | Access Policy | `egress_policies` (folder, `**/*.yaml`) | Egress Policies | `access_policy`, `context` | `egress-policy.schema.json` |
| `vpc-sc` | Access Policy | `ingress_policies` (folder, `**/*.yaml`) | Ingress Policies | `access_policy`, `context` | `ingress-policy.schema.json` |
| `vpc-sc` | Access Policy | `perimeters` (folder, `**/*.yaml`) | Service Perimeters | `access_policy`, `context` | `perimeter.schema.json` |
| `workstation-cluster` | Workstation Cluster | `workstation_configs` (folder, `*.yaml`) | Workstation Configurations | `id`, `project_id`, `location`, `context` | `workstation-config.schema.json` |

## Graduating to FAST Stage Datasets (`fast/stages/<stage>/schemas/`)

FAST stages wrap the module factories above with a stage-level `factories_config = { dataset = "datasets/classic", paths = { ... } }` interface and a `defaults.yaml` file (which supplies stage `context`, `defaults`, `overrides`, and `output_files`). Upstream stage outputs (`0-globals.auto.tfvars.json`, `0-org-setup.auto.tfvars.json`, etc.) automatically feed downstream stage `context` maps.

| FAST Stage | Dataset Surfaces | Backing Implementation | Stage Schemas (`fast/stages/<stage>/schemas/`) |
| :--- | :--- | :--- | :--- |
| `0-org-setup` | `defaults.yaml`, `billing-accounts/`, `cicd-workflows`, `observability/`, `organization/.config.yaml` + sub-factories, `folders/`, `projects/`, `templates/`, `budgets/`, `vpcs/` | `project-factory`, `net-vpc-factory`, `organization`, `billing-account`, `project` + stage CI/CD loader | `defaults`, `billing-account`, `cicd-workflows`, `observability`, `organization`, `access-level`, `custom-constraint`, `custom-role`, `org-policies`, `scc-sha-custom-modules`, `tags`, `project`, `folder`, `budget`, `vpc-factory`, `subnet`, `firewall-rules` |
| `1-vpcsc` | `defaults.yaml`, `restricted-services.yaml`, `access-levels/`, `egress-policies/`, `ingress-policies/`, `perimeters/` | `vpc-sc` module factories + stage `restricted_services` config | `defaults`, `access-level`, `egress-policy`, `ingress-policy`, `perimeter` |
| `2-networking` | `defaults.yaml`, `folders/`, `projects/`, `vpcs/<vpc>/.config.yaml` + `subnets/`, `firewall-rules/`, `addresses.yaml`, `psc-endpoints.yaml`, `vpns/`, `vlan-attachments/`, `attachment-groups/`, plus `dns/`, `firewall-policies/`, `ncc-hubs/`, `nvas/`, `security-policies/` | `project-factory`, `net-vpc-factory`, `net-vpc` (second-pass routes/PBRs), plus stage-level factories (`net-address`, `net-cloudnat`, `dns`, `dns-response-policy`, `net-firewall-policy`, `net-cloud-armor`, `net-psc-endpoint`, `net-vlan-attachment`, `net-vpn-ha`, NCC, NVA). Use `fast-networking` for full topology design. | `defaults`, `project`, `folder`, `vpc`, `subnet`, `firewall-rules`, `addresses`, `attachment-groups`, `dns`, `dns-response-policy-rules`, `firewall-policy`, `ncc-hub`, `nva`, `psc-endpoints`, `security-policy`, `vlan-attachments`, `vpn` |
| `2-project-factory` | `defaults.yaml`, `folders/`, `projects/`, `project-templates/`, `budgets/`, `vpcs/` | Thin stage wrapper over `project-factory` + `net-vpc-factory` consuming outputs from Stages 0/1/2 | `defaults`, `project`, `folder`, `budget`, `aspect-type`, `tags` (VPCs use `net-vpc-factory` schemas) |
| `2-security` | `defaults.yaml`, `folders/`, `projects/`, `certificate-authorities/`, `keyrings/`, `security-policies/` | `project-factory` + stage-level `certificate-authority-service`, `kms`, `net-cloud-armor` | `defaults`, `project`, `folder`, `certificate-authority`, `keyring`, `security-policy` |
| `3-secops-dev` | `rules`, `rules_defs`, `reference_lists`, `reference_lists_defs` | `secops-rules` | — |

FAST addons and project templates follow the same model: `fast/addons/2-networking-swp` delegates to `net-swp` (`policy-rule.schema.json`, `url-list.schema.json`), `fast/addons/2-networking-test` uses `instance.schema.json` and `service-account.schema.json`, and `fast/project-templates/gce-workstation-cluster` delegates to `workstation-cluster` (`workstation-config.schema.json`).
