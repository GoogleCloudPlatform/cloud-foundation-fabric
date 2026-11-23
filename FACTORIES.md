# Factories Overview

- [Modules](#modules)
- [FAST Stages](#fast-stages)
- [FAST Addons & Project Templates](#fast-addons--project-templates)
- [Maintenance Guide](#maintenance-guide)

## Modules

The following table provides a granular overview of modules that implement factory patterns. Each row represents a specific **factory configuration key** found within the `factories_config` variable.

*   **Primary Module Resource**: The main resource the module is designed to manage (e.g., a Project for the `project` module, or an Access Policy for `vpc-sc`). "N/A" indicates the module is a "Pure Factory" designed primarily to create multiple top-level resources.
*   **Factory Key**: The key in `factories_config` used to load external data, noting whether it loads a directory (folder) or a single file.
*   **Factory-Managed Resources**: The specific resources created or configured by iterating over the loaded factory data.
*   **Dependencies**: Module-level variables used by the factory resources (e.g., `project_id` or `context` injected into factory resources).
*   **Schema**: The repo-relative JSON schema(s) validating the YAML data files (`—` where no schema exists).

| Module | Primary Module Resource | Factory Key | Factory-Managed Resources | Dependencies (Module Variables) | Schema |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **analytics-hub** | Analytics Hub Exchange | `listings` (folder, `*.yaml`) | Analytics Hub Listings | `project_id`, `region` | — |
| **billing-account** | Billing Account (Config) | `budgets_data_path` (folder, `**/*.yaml`) | Billing Budgets | `id` (Billing Account ID), `context` | [budget.schema.json](modules/billing-account/schemas/budget.schema.json) |
| **data-catalog-policy-tag** | Data Catalog Taxonomy | `taxonomy` (file) | Data Catalog Policy Tags | `project_id`, `location`, `context` | [policy-tag.schema.json](modules/data-catalog-policy-tag/schemas/policy-tag.schema.json) |
| **data-catalog-tag** | N/A | `tags` (folder, `*.yaml`) | Data Catalog Tags | `tags` (merged with factory data) | — |
| **data-catalog-tag-template** | N/A | `tag_templates` (folder, `**/*.yaml`) | Tag Templates | `project_id`, `region`, `tag_templates` | [tag-template.schema.json](modules/data-catalog-tag-template/schemas/tag-template.schema.json) |
| **dataplex-aspect-types** | N/A | `aspect_types` (folder, `**/*.yaml`) | Dataplex Aspect Types | `project_id`, `location`, `context` | [aspect-type.schema.json](modules/dataplex-aspect-types/schemas/aspect-type.schema.json) |
| **dataplex-datascan** | DataScan | `data_quality_spec` (file) | Data Quality Spec (Rules) | `project_id`, `region` | — |
| **dns-response-policy** | DNS Response Policy | `rules` (file) | Response Policy Rules | `project_id`, `name`, `context` | — |
| **folder** | Folder | `org_policies` (folder, `*.yaml`) | Organization Policies | `id` (Folder ID), `context` | [org-policies.schema.json](modules/folder/schemas/org-policies.schema.json) |
| **folder** | Folder | `pam_entitlements` (folder, `*.yaml`) | PAM Entitlements | `id` (Folder ID), `context` | [pam-entitlements.schema.json](modules/folder/schemas/pam-entitlements.schema.json) |
| **folder** | Folder | `scc_mute_configs` (folder, `*.yaml`) | SCC Mute Configs | `id` (Folder ID) | [scc-mute-config.schema.json](modules/folder/schemas/scc-mute-config.schema.json) |
| **folder** | Folder | `scc_sha_custom_modules` (folder, `*.yaml`) | SCC SHA Custom Modules | `id` (Folder ID) | [scc-sha-custom-modules.schema.json](modules/folder/schemas/scc-sha-custom-modules.schema.json) |
| **net-cloud-armor** | Cloud Armor Security Policy | `rules_file_path` (file) | Security Policy Rules | `name`, `parent_id`, `region`, `context` | [rules.schema.json](modules/net-cloud-armor/schemas/rules.schema.json) |
| **net-firewall-policy** | Firewall Policy | `cidr_file_path` (file) | Named CIDR Ranges (interpolated into factory rules) | — | — |
| **net-firewall-policy** | Firewall Policy | `egress_mirroring_rules_file_path` (file) | Egress Packet Mirroring Rules | `name`, `parent_id`, `region`, `context` | [firewall-policy-mirroring-rules.schema.json](modules/net-firewall-policy/schemas/firewall-policy-mirroring-rules.schema.json) |
| **net-firewall-policy** | Firewall Policy | `egress_rules_file_path` (file) | Egress Firewall Rules | `name`, `parent_id`, `region`, `context` | [firewall-policy-rules.schema.json](modules/net-firewall-policy/schemas/firewall-policy-rules.schema.json) |
| **net-firewall-policy** | Firewall Policy | `ingress_mirroring_rules_file_path` (file) | Ingress Packet Mirroring Rules | `name`, `parent_id`, `region`, `context` | [firewall-policy-mirroring-rules.schema.json](modules/net-firewall-policy/schemas/firewall-policy-mirroring-rules.schema.json) |
| **net-firewall-policy** | Firewall Policy | `ingress_rules_file_path` (file) | Ingress Firewall Rules | `name`, `parent_id`, `region`, `context` | [firewall-policy-rules.schema.json](modules/net-firewall-policy/schemas/firewall-policy-rules.schema.json) |
| **net-swp** | Secure Web Proxy | `policy_rules` (folder, `**/*.yaml`) | Proxy Policy Rules | `project_id`, `region`, `name`, `policy_rules_contexts` | [policy-rule.schema.json](modules/net-swp/schemas/policy-rule.schema.json) |
| **net-swp** | Secure Web Proxy | `url_lists` (folder, `**/*.yaml`) | Proxy URL Lists | `project_id`, `region` | [url-list.schema.json](modules/net-swp/schemas/url-list.schema.json) |
| **net-vpc** | VPC Network | `internal_ranges_folder` (folder, `**/*.yaml`) | Internal Ranges | `project_id`, `name`, `context` | [internal-range.schema.json](modules/net-vpc/schemas/internal-range.schema.json) |
| **net-vpc** | VPC Network | `subnets_folder` (folder, `**/*.yaml`) | Subnets (and Subnet IAM) | `project_id`, `name`, `context` | [subnet.schema.json](modules/net-vpc/schemas/subnet.schema.json) |
| **net-vpc-factory** | N/A | `paths.vpcs` (folder under `basepath`, `**/.config.yaml` + `subnets/`, `firewall-rules/`) | VPCs, Subnets, VPC Firewall Rules | `context`, `data_defaults`, `data_overrides` | [vpc-factory.schema.json](modules/net-vpc-factory/schemas/vpc-factory.schema.json), [subnet.schema.json](modules/net-vpc-factory/schemas/subnet.schema.json), [firewall-rules.schema.json](modules/net-vpc-factory/schemas/firewall-rules.schema.json) (auxiliary: [defaults.schema.json](modules/net-vpc-factory/schemas/defaults.schema.json)) |
| **net-vpc-firewall** | N/A | `cidr_tpl_file` (file) | Named CIDR Ranges (merged with `named_ranges`) | `named_ranges` | — |
| **net-vpc-firewall** | N/A | `rules_folder` (folder, `**/*.yaml`) | VPC Firewall Rules | `project_id`, `network`, `context` | [firewall-rules.schema.json](modules/net-vpc-firewall/schemas/firewall-rules.schema.json) |
| **organization** | Organization (Existing) | `access_levels` (folder, `*.yaml`) | Context-Aware Access Levels | `access_policy`, `context` | [access-level.schema.json](modules/organization/schemas/access-level.schema.json) |
| **organization** | Organization (Existing) | `custom_roles` (folder, `*.yaml`) | Custom IAM Roles | `organization_id` | [custom-role.schema.json](modules/organization/schemas/custom-role.schema.json) |
| **organization** | Organization (Existing) | `org_policies` (folder, `*.yaml`) | Organization Policies | `organization_id`, `context` | [org-policies.schema.json](modules/organization/schemas/org-policies.schema.json) |
| **organization** | Organization (Existing) | `org_policy_custom_constraints` (folder, `*.yaml`) | Org Policy Custom Constraints | `organization_id`, `context` | [org-policy-custom-constraint.schema.json](modules/organization/schemas/org-policy-custom-constraint.schema.json) |
| **organization** | Organization (Existing) | `pam_entitlements` (folder, `*.yaml`) | PAM Entitlements | `organization_id`, `context` | [pam-entitlements.schema.json](modules/organization/schemas/pam-entitlements.schema.json) |
| **organization** | Organization (Existing) | `scc_mute_configs` (folder, `*.yaml`) | SCC Mute Configs | `organization_id` | [scc-mute-config.schema.json](modules/organization/schemas/scc-mute-config.schema.json) |
| **organization** | Organization (Existing) | `scc_sha_custom_modules` (folder, `*.yaml`) | SCC SHA Custom Modules | `organization_id` | [scc-sha-custom-modules.schema.json](modules/organization/schemas/scc-sha-custom-modules.schema.json) |
| **organization** | Organization (Existing) | `tags` (folder, `*.yaml`) | Resource Manager Tags (Keys, Values, IAM) | `organization_id`, `tags_config`, `context` | [tags.schema.json](modules/organization/schemas/tags.schema.json) |
| **project** | Project | `custom_roles` (folder, `*.yaml`) | Custom IAM Roles | `name` / `project_id` | [custom-role.schema.json](modules/project/schemas/custom-role.schema.json) |
| **project** | Project | `observability` (folder, `*.yaml`) | Observability (Alert Policies, Logging Metrics, Notification Channels) | `name` / `project_id`, `context` | [observability.schema.json](modules/project/schemas/observability.schema.json) |
| **project** | Project | `org_policies` (folder, `*.yaml`) | Organization Policies | `name` / `project_id`, `context` | [org-policies.schema.json](modules/project/schemas/org-policies.schema.json) |
| **project** | Project | `pam_entitlements` (folder, `*.yaml`) | PAM Entitlements | `name` / `project_id`, `context` | [pam-entitlements.schema.json](modules/project/schemas/pam-entitlements.schema.json) |
| **project** | Project | `quotas` (folder, `*.yaml`) | Cloud Quotas Preferences | `name` / `project_id`, `context` | [quotas.schema.json](modules/project/schemas/quotas.schema.json) |
| **project** | Project | `scc_mute_configs` (folder, `*.yaml`) | SCC Mute Configs | `name` / `project_id` | [scc-mute-config.schema.json](modules/project/schemas/scc-mute-config.schema.json) |
| **project** | Project | `scc_sha_custom_modules` (folder, `*.yaml`) | SCC SHA Custom Modules | `name` / `project_id` | [scc-sha-custom-modules.schema.json](modules/project/schemas/scc-sha-custom-modules.schema.json) |
| **project** | Project | `tags` (folder, `*.yaml`) | Resource Manager Tags (Keys, Values, IAM) | `name` / `project_id`, `tags_config`, `context` | [tags.schema.json](modules/project/schemas/tags.schema.json) |
| **project-factory** | N/A | `paths.budgets` (folder under `basepath`, `**/*.yaml`) | Billing Budgets (via `billing-account`) | `factories_config.budgets.billing_account`, `context` | [budget.schema.json](modules/project-factory/schemas/budget.schema.json) |
| **project-factory** | N/A | `paths.folders` (folder under `basepath`, `**/**/.config.yaml`) | Folders (up to 4 levels; delegates per-folder `factories_config` to `folder`) | `folders`, `context` | [folder.schema.json](modules/project-factory/schemas/folder.schema.json) |
| **project-factory** | N/A | `paths.project_templates` (folder under `basepath`, `**/*.yaml`) | Project Templates (merged into project definitions) | — | [project.schema.json](modules/project-factory/schemas/project.schema.json) |
| **project-factory** | N/A | `paths.projects` (folder under `basepath`, `**/*.yaml`) | Projects, Service Accounts, Buckets, KMS, Pub/Sub, Aspect Types, Taxonomies (delegates per-project `factories_config`) | `projects`, `context`, `data_defaults`, `data_merges`, `data_overrides`, `notification_channels` | [project.schema.json](modules/project-factory/schemas/project.schema.json) (per-project sub-factories: [aspect-type.schema.json](modules/project-factory/schemas/aspect-type.schema.json), [taxonomy.schema.json](modules/project-factory/schemas/taxonomy.schema.json)) |
| **secops-rules** | N/A | `reference_lists` (file) | SecOps Reference Lists metadata | `project_id`, `tenant_config`, `reference_lists_config` | — |
| **secops-rules** | N/A | `reference_lists_defs` (folder, `<key>.txt`) | SecOps Reference List content files | `project_id`, `tenant_config` | — |
| **secops-rules** | N/A | `rules` (file) | SecOps Detection Rule deployments | `project_id`, `tenant_config`, `rules_config` | — |
| **secops-rules** | N/A | `rules_defs` (folder, `*.yaral`) | SecOps Detection Rule YARA-L definitions | `project_id`, `tenant_config` | — |
| **vpc-sc** | Access Policy | `access_levels` (folder, `**/*.yaml`) | Access Levels | `access_policy`, `context` | [access-level.schema.json](modules/vpc-sc/schemas/access-level.schema.json) |
| **vpc-sc** | Access Policy | `egress_policies` (folder, `**/*.yaml`) | Egress Policies | `access_policy`, `context` | [egress-policy.schema.json](modules/vpc-sc/schemas/egress-policy.schema.json) |
| **vpc-sc** | Access Policy | `ingress_policies` (folder, `**/*.yaml`) | Ingress Policies | `access_policy`, `context` | [ingress-policy.schema.json](modules/vpc-sc/schemas/ingress-policy.schema.json) |
| **vpc-sc** | Access Policy | `perimeters` (folder, `**/*.yaml`) | Service Perimeters | `access_policy`, `context` | [perimeter.schema.json](modules/vpc-sc/schemas/perimeter.schema.json) |
| **workstation-cluster** | Workstation Cluster | `workstation_configs` (folder, `*.yaml`) | Workstation Configurations | `id`, `project_id`, `location`, `context` | [workstation-config.schema.json](modules/workstation-cluster/schemas/workstation-config.schema.json) |

> **Note on auxiliary & deprecated modules:** `modules/net-vpc-factory/schemas/defaults.schema.json` documents the `defaults.yaml` shape used by callers (such as FAST stages), though `net-vpc-factory` itself accepts defaults via `var.data_defaults` / `var.data_overrides` rather than reading `defaults.yaml`. Two deprecated modules under `modules/__experimental_deprecated/` (`bigquery-factory` with `views_path` / `tables_path`, and `cloud-identity-group-factory` with `data_dir`) use legacy path variables instead of `factories_config` and are omitted from the main table.

## FAST Stages

The following table details how FAST stages implement factory patterns and stage-level YAML configuration loaders.

*   **Implementation Type**:
    *   `Module-Backed (Factory)`: The stage passes the `factories_config` path to a module which has internal logic to load and iterate over the data (e.g., `project-factory`).
    *   `Stage-Implemented (Module)`: The stage explicitly loads the YAML data (usually in `locals`) and iterates over a standard module (e.g., `dns` module).
    *   `Stage-Implemented (Resource)`: The stage explicitly loads the YAML data and iterates over raw Terraform resources.
    *   `Native (Complex)`: The stage implements complex factory logic combining multiple modules and resources.
    *   `Stage-Implemented (Config)`: The stage loads a YAML configuration or defaults file (e.g., `defaults.yaml`, `restricted-services.yaml`) into stage `locals` to drive defaults, overrides, and context interpolation.

| Stage | Factory (Key/Feature) | Implementation Type | Underlying Module/Resource | Schema |
| :--- | :--- | :--- | :--- | :--- |
| **0-org-setup** | `defaults` (`defaults.yaml`) | Stage-Implemented (Config) | Stage defaults, overrides, context & output files | [defaults.schema.json](fast/stages/0-org-setup/schemas/defaults.schema.json) |
| **0-org-setup** | `billing_accounts` (`billing.tf`) | Stage-Implemented (Module) | `billing-account` | [billing-account.schema.json](fast/stages/0-org-setup/schemas/billing-account.schema.json) |
| **0-org-setup** | `cicd_workflows` (`cicd-workflows.tf`) | Native (Complex) | `iam-service-account`, `local_file`, `google_storage_bucket_object` | [cicd-workflows.schema.json](fast/stages/0-org-setup/schemas/cicd-workflows.schema.json) |
| **0-org-setup** | `observability` (`observability.tf`) | Module-Backed (Factory) | `project` (`factories_config.observability`) | [observability.schema.json](fast/stages/0-org-setup/schemas/observability.schema.json) |
| **0-org-setup** | `organization` (`.config.yaml`, `organization.tf`) | Stage-Implemented (Module) | `organization` | [organization.schema.json](fast/stages/0-org-setup/schemas/organization.schema.json) |
| **0-org-setup** | `organization/*` (`access-levels`, `custom-constraints`, `custom-roles`, `org-policies`, `scc-sha-custom-modules`, `tags`) | Module-Backed (Factory) | `organization` | [access-level.schema.json](fast/stages/0-org-setup/schemas/access-level.schema.json), [custom-constraint.schema.json](fast/stages/0-org-setup/schemas/custom-constraint.schema.json), [custom-role.schema.json](fast/stages/0-org-setup/schemas/custom-role.schema.json), [org-policies.schema.json](fast/stages/0-org-setup/schemas/org-policies.schema.json), [scc-sha-custom-modules.schema.json](fast/stages/0-org-setup/schemas/scc-sha-custom-modules.schema.json), [tags.schema.json](fast/stages/0-org-setup/schemas/tags.schema.json) |
| **0-org-setup** | `projects`, `folders`, `project_templates`, `budgets` (`factory.tf`) | Module-Backed (Factory) | `project-factory` | [project.schema.json](fast/stages/0-org-setup/schemas/project.schema.json), [folder.schema.json](fast/stages/0-org-setup/schemas/folder.schema.json), [budget.schema.json](fast/stages/0-org-setup/schemas/budget.schema.json) |
| **0-org-setup** | `vpcs` (`factory.tf`) | Module-Backed (Factory) | `net-vpc-factory` | [vpc-factory.schema.json](fast/stages/0-org-setup/schemas/vpc-factory.schema.json), [subnet.schema.json](fast/stages/0-org-setup/schemas/subnet.schema.json), [firewall-rules.schema.json](fast/stages/0-org-setup/schemas/firewall-rules.schema.json) |
| **1-vpcsc** | `defaults` (`defaults.yaml`) | Stage-Implemented (Config) | Stage context & output files | [defaults.schema.json](fast/stages/1-vpcsc/schemas/defaults.schema.json) |
| **1-vpcsc** | `restricted_services` (`restricted-services.yaml`) | Stage-Implemented (Config) | `vpc-sc` (`context.restricted_services`) | — |
| **1-vpcsc** | `access_levels`, `egress_policies`, `ingress_policies`, `perimeters` | Module-Backed (Factory) | `vpc-sc` | [access-level.schema.json](fast/stages/1-vpcsc/schemas/access-level.schema.json), [egress-policy.schema.json](fast/stages/1-vpcsc/schemas/egress-policy.schema.json), [ingress-policy.schema.json](fast/stages/1-vpcsc/schemas/ingress-policy.schema.json), [perimeter.schema.json](fast/stages/1-vpcsc/schemas/perimeter.schema.json) |
| **2-networking** | `defaults` (`defaults.yaml`) | Stage-Implemented (Config) | Stage defaults, overrides, context & output files | [defaults.schema.json](fast/stages/2-networking/schemas/defaults.schema.json) |
| **2-networking** | `projects`, `folders` (`factory-projects.tf`) | Module-Backed (Factory) | `project-factory` | [project.schema.json](fast/stages/2-networking/schemas/project.schema.json), [folder.schema.json](fast/stages/2-networking/schemas/folder.schema.json) |
| **2-networking** | `vpcs` (`factory-vpcs.tf`: VPCs, subnets, firewall rules, second-pass routes/PBRs) | Module-Backed (Factory) | `net-vpc-factory`, `net-vpc` | [vpc.schema.json](fast/stages/2-networking/schemas/vpc.schema.json), [subnet.schema.json](fast/stages/2-networking/schemas/subnet.schema.json), [firewall-rules.schema.json](fast/stages/2-networking/schemas/firewall-rules.schema.json) |
| **2-networking** | `addresses` (per-VPC `addresses.yaml`, `factory-addresses.tf`) | Stage-Implemented (Module) | `net-address` | [addresses.schema.json](fast/stages/2-networking/schemas/addresses.schema.json) |
| **2-networking** | `attachment_groups` (per-VPC `attachment-groups/*.yaml`, `factory-vlan-attachments.tf`) | Stage-Implemented (Resource) | `google_compute_interconnect_attachment_group` | [attachment-groups.schema.json](fast/stages/2-networking/schemas/attachment-groups.schema.json) |
| **2-networking** | `cloud_nats` (per-VPC `nat_config`, `factory-cloudnat.tf`) | Stage-Implemented (Module) | `net-cloudnat`, `net-address` | [vpc.schema.json](fast/stages/2-networking/schemas/vpc.schema.json) |
| **2-networking** | `dns` (`factory-dns.tf`: zones & delegations) | Stage-Implemented (Module) | `dns` | [dns.schema.json](fast/stages/2-networking/schemas/dns.schema.json) |
| **2-networking** | `dns_response_policies` (`factory-dns.tf`) | Stage-Implemented (Module) | `dns-response-policy` | [dns-response-policy-rules.schema.json](fast/stages/2-networking/schemas/dns-response-policy-rules.schema.json) |
| **2-networking** | `firewall_policies` (`factory-firewall-policies.tf`) | Stage-Implemented (Module) | `net-firewall-policy` | [firewall-policy.schema.json](fast/stages/2-networking/schemas/firewall-policy.schema.json) |
| **2-networking** | `ncc_hubs` (`factory-ncc.tf`: hubs, groups, VPC/tunnel/VLAN spokes) | Stage-Implemented (Resource) | `google_network_connectivity_hub`, `google_network_connectivity_group`, `google_network_connectivity_spoke` | [ncc-hub.schema.json](fast/stages/2-networking/schemas/ncc-hub.schema.json) |
| **2-networking** | `nvas` (`factory-nva.tf`) | Native (Complex) | `compute-vm`, `net-lb-int`, `google_compute_instance_group`, `google_compute_health_check`, `google_network_connectivity_spoke` | [nva.schema.json](fast/stages/2-networking/schemas/nva.schema.json) |
| **2-networking** | `peerings` (per-VPC `peering_config`, `factory-peering.tf`) | Stage-Implemented (Resource) | `google_compute_network_peering` | [vpc.schema.json](fast/stages/2-networking/schemas/vpc.schema.json) |
| **2-networking** | `psc-endpoints` (per-VPC `psc-endpoints.yaml`, `factory-psc.tf`) | Stage-Implemented (Module) | `net-psc-endpoint` | [psc-endpoints.schema.json](fast/stages/2-networking/schemas/psc-endpoints.schema.json) |
| **2-networking** | `routers` (per-VPC `routers`, `factory-routers.tf`) | Stage-Implemented (Resource) | `google_compute_router`, `google_compute_router_route_policy`, `google_compute_router_interface`, `google_compute_router_peer` | [vpc.schema.json](fast/stages/2-networking/schemas/vpc.schema.json) |
| **2-networking** | `security_policies` (`factory-security-policies.tf`) | Stage-Implemented (Module) | `net-cloud-armor` | [security-policy.schema.json](fast/stages/2-networking/schemas/security-policy.schema.json) |
| **2-networking** | `vlan_attachments` (per-VPC `vlan-attachments/*.yaml`, `factory-vlan-attachments.tf`) | Stage-Implemented (Module) | `net-vlan-attachment` | [vlan-attachments.schema.json](fast/stages/2-networking/schemas/vlan-attachments.schema.json) |
| **2-networking** | `vpns` (per-VPC `vpns/*.yaml`, `factory-vpns.tf`) | Native (Complex) | `net-vpn-ha`, `google_compute_ha_vpn_gateway` | [vpn.schema.json](fast/stages/2-networking/schemas/vpn.schema.json) |
| **2-project-factory** | `defaults` (`defaults.yaml`) | Stage-Implemented (Config) | Stage defaults, merges, overrides & context | [defaults.schema.json](fast/stages/2-project-factory/schemas/defaults.schema.json) |
| **2-project-factory** | `projects`, `folders`, `project_templates`, `budgets` (`main.tf`) | Module-Backed (Factory) | `project-factory` (plus per-project sub-factories: `aspect_types`, `tags`, `data_catalog_taxonomy`, etc.) | [project.schema.json](fast/stages/2-project-factory/schemas/project.schema.json), [folder.schema.json](fast/stages/2-project-factory/schemas/folder.schema.json), [budget.schema.json](fast/stages/2-project-factory/schemas/budget.schema.json), [aspect-type.schema.json](fast/stages/2-project-factory/schemas/aspect-type.schema.json), [tags.schema.json](fast/stages/2-project-factory/schemas/tags.schema.json) |
| **2-project-factory** | `vpcs` (`vpcs.tf`) | Module-Backed (Factory) | `net-vpc-factory` | Uses `net-vpc-factory` schemas ([vpc-factory.schema.json](modules/net-vpc-factory/schemas/vpc-factory.schema.json), [subnet.schema.json](modules/net-vpc-factory/schemas/subnet.schema.json), [firewall-rules.schema.json](modules/net-vpc-factory/schemas/firewall-rules.schema.json)) |
| **2-security** | `defaults` (`defaults.yaml`) | Stage-Implemented (Config) | Stage defaults, overrides, context & output files | [defaults.schema.json](fast/stages/2-security/schemas/defaults.schema.json) |
| **2-security** | `projects`, `folders` (`factory-projects.tf`) | Module-Backed (Factory) | `project-factory` | [project.schema.json](fast/stages/2-security/schemas/project.schema.json), [folder.schema.json](fast/stages/2-security/schemas/folder.schema.json) |
| **2-security** | `certificate_authorities` (`factory-cas.tf`) | Stage-Implemented (Module) | `certificate-authority-service` | [certificate-authority.schema.json](fast/stages/2-security/schemas/certificate-authority.schema.json) |
| **2-security** | `keyrings` (`factory-keyrings.tf`) | Stage-Implemented (Module) | `kms` | [keyring.schema.json](fast/stages/2-security/schemas/keyring.schema.json) |
| **2-security** | `security_policies` (`factory-security-policies.tf`) | Stage-Implemented (Module) | `net-cloud-armor` | [security-policy.schema.json](fast/stages/2-security/schemas/security-policy.schema.json) |
| **3-secops-dev** | `rules`, `rules_defs`, `reference_lists`, `reference_lists_defs` | Module-Backed (Factory) | `secops-rules` | — |

## FAST Addons & Project Templates

The following table covers factory implementations in `fast/addons/` and `fast/project-templates/`.

| Component | Factory (Key/Feature) | Implementation Type | Underlying Module/Resource | Schema |
| :--- | :--- | :--- | :--- | :--- |
| **addons/2-networking-swp** | `policy_rules`, `url_lists` (per `swp_configs` key) | Module-Backed (Factory) | `net-swp` | Uses `net-swp` schemas ([policy-rule.schema.json](modules/net-swp/schemas/policy-rule.schema.json), [url-list.schema.json](modules/net-swp/schemas/url-list.schema.json)) |
| **addons/2-networking-test** | `instances` (`factory.tf`) | Stage-Implemented (Module) | `compute-vm` | [instance.schema.json](fast/addons/2-networking-test/schemas/instance.schema.json) |
| **addons/2-networking-test** | `service_accounts` (`factory.tf`) | Stage-Implemented (Module) | `iam-service-account` | [service-account.schema.json](fast/addons/2-networking-test/schemas/service-account.schema.json) |
| **project-templates/gce-workstation-cluster** | `workstation_configs` (`main.tf`) | Module-Backed (Factory) | `workstation-cluster` | Uses `workstation-cluster` schema ([workstation-config.schema.json](modules/workstation-cluster/schemas/workstation-config.schema.json)) |

## Maintenance Guide

This documentation is maintained to track factory patterns and their JSON schemas across `modules/`, `fast/stages/`, `fast/addons/`, and `fast/project-templates/`.

### Discovery & Maintenance Guide

To ensure this document never drifts from the actual codebase and to prevent missing any newly introduced factory patterns or schemas, use these systematic search commands to discover and audit all factories in the repository:

#### 1. Discovering Module Factories

To locate all modules supporting `factories_config` (or YAML factory loaders), run:

```bash
grep -rn 'variable "factories_config"' modules/
grep -rnE '\b(yamldecode|fileset)\b' modules/
```

For each discovered module, verify that every key defined in `variables.tf` under the `factories_config` type block (and any nested sub-factories) is documented in the [Modules](#modules) table.

#### 2. Discovering FAST Stage, Addon & Project Template Factories

To locate all FAST-level `factories_config` definitions, factory helper files, and YAML loaders across stages, addons, and project templates, run:

```bash
grep -rn 'variable "factories_config"' fast/stages/ fast/addons/ fast/project-templates/
find fast/stages/ fast/addons/ fast/project-templates/ -name "factory*.tf"
grep -rnE '\b(yamldecode|fileset)\b' fast/stages/ fast/addons/ fast/project-templates/
```

Match each `factories_config` key and `factory*.tf` file against the [FAST Stages](#fast-stages) and [FAST Addons & Project Templates](#fast-addons--project-templates) tables to ensure every implemented feature, `Implementation Type`, and `Underlying Module/Resource` is accurately documented.

#### 3. Auditing Schemas

To verify that every JSON schema in the repository is mapped in this document and that no link is broken, run:

```bash
find modules/ fast/ -name "*.schema.json" | sort
```

Compare the output against the links in `FACTORIES.md` and run `python3 tools/duplicate-diff.py` whenever a shared schema changes.

#### 4. Updating the Tables

When updating the tables manually:

- **Modules Table:** Insert any new module-backed factory in strict **alphabetical order** by module name and by factory key within each module. Document the `Primary Module Resource`, the exact `Factory Key` (including folder vs. file), the `Factory-Managed Resources`, module-level `Dependencies`, and repo-relative `Schema` links.
- **FAST Stages & Addons/Templates Tables:** Group entries by stage or component name. List all factory keys, sub-features, and YAML configuration loaders, classifying their `Implementation Type`, `Underlying Module/Resource`, and `Schema` accurately.
