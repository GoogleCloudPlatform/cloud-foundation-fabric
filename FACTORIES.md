# Factories Overview

- [Modules](#modules)
- [FAST Stages](#fast-stages)
- [Maintenance Guide](#maintenance-guide)

## Modules

The following table provides a granular overview of modules that implement factory patterns. Each row represents a specific **factory configuration key** found within the `factories_config` variable.

*   **Primary Module Resource**: The main resource the module is designed to manage (e.g., a Project for the `project` module, or an Access Policy for `vpc-sc`). "N/A" indicates the module is a "Pure Factory" designed primarily to create multiple top-level resources.
*   **Factory Key**: The key in `factories_config` used to load external data.
*   **Factory-Managed Resources**: The specific resources created by iterating over the loaded factory data.
*   **Dependencies**: Module-level variables used by the factory resources (e.g., `project_id` injected into factory resources).

| Module | Primary Module Resource | Factory Key | Factory-Managed Resources | Dependencies (Module Variables) |
| :--- | :--- | :--- | :--- | :--- |
| **analytics-hub** | Analytics Hub Exchange | `listings` | Analytics Hub Listings | `project_id`, `region` |
| **billing-account** | Billing Account (Config) | `budgets_data_path` | Billing Budgets | `id` (Billing Account ID) |
| **data-catalog-policy-tag** | Data Catalog Taxonomy | `taxonomy` | Policy Tags | `project_id`, `location`, `name` (Taxonomy Name) |
| **data-catalog-tag** | N/A | `tags` | Data Catalog Tags | `tags` (Merged with factory data) |
| **data-catalog-tag-template** | N/A | `tag_templates` | Tag Templates | `project_id`, `region` |
| **dataplex-aspect-types** | N/A | `aspect_types` | Aspect Types | `project_id`, `location` |
| **dataplex-datascan** | DataScan | `data_quality_spec` | Data Quality Rules | `project_id`, `location` |
| **dns-response-policy** | DNS Response Policy | `rules` | Response Policy Rules | `project_id` |
| **folder** | Folder | `org_policies` | Organization Policies | `folder` (ID/Name) |
| **folder** | Folder | `pam_entitlements` | PAM Entitlements | `folder` (ID/Name) |
| **folder** | Folder | `scc_mute_configs` | SCC Mute Configs | `folder` (ID/Name) |
| **folder** | Folder | `scc_sha_custom_modules` | SCC SHA Custom Modules | `folder` (ID/Name) |
| **net-firewall-policy** | Firewall Policy | `egress_mirroring_rules_file_path` | Egress Packet Mirroring Rules | `name` (Policy Name) |
| **net-firewall-policy** | Firewall Policy | `egress_rules_file_path` | Egress Firewall Rules | `name` (Policy Name) |
| **net-firewall-policy** | Firewall Policy | `ingress_mirroring_rules_file_path` | Ingress Packet Mirroring Rules | `name` (Policy Name) |
| **net-firewall-policy** | Firewall Policy | `ingress_rules_file_path` | Ingress Firewall Rules | `name` (Policy Name) |
| **net-swp** | Secure Web Proxy | `policy_rules` | Proxy Policy Rules | `project_id`, `region` |
| **net-swp** | Secure Web Proxy | `url_lists` | Proxy URL Lists | `project_id`, `region` |
| **net-vpc** | VPC Network | `internal_ranges_folder` | Internal Ranges | `project_id`, `name` (Network Name) |
| **net-vpc** | VPC Network | `subnets_folder` | Subnets | `project_id`, `region` (Default), `name` (Network Name) |
| **net-vpc-factory** | N/A | `vpcs` | VPCs (and associated resources) | `context`, `data_defaults`, `data_overrides` |
| **net-vpc-firewall** | N/A | `rules_folder` | Firewall Rules | `project_id`, `network` |
| **organization** | Organization (Existing) | `custom_roles` | Custom IAM Roles | `organization_id` |
| **organization** | Organization (Existing) | `org_policies` | Organization Policies | `organization_id` |
| **organization** | Organization (Existing) | `org_policy_custom_constraints` | Org Policy Custom Constraints | `organization_id` |
| **organization** | Organization (Existing) | `pam_entitlements` | PAM Entitlements | `organization_id` |
| **organization** | Organization (Existing) | `scc_mute_configs` | SCC Mute Configs | `organization_id` |
| **organization** | Organization (Existing) | `scc_sha_custom_modules` | SCC SHA Custom Modules | `organization_id` |
| **organization** | Organization (Existing) | `tags` | ResourceManager Tags | `organization_id` |
| **project** | Project | `custom_roles` | Custom IAM Roles | `project.project_id` |
| **project** | Project | `observability` | Observability (Alerts, Metrics) | `project.project_id` |
| **project** | Project | `org_policies` | Organization Policies | `project.project_id` |
| **project** | Project | `pam_entitlements` | PAM Entitlements | `project.project_id` |
| **project** | Project | `quotas` | Service Quotas | `project.project_id` |
| **project** | Project | `scc_mute_configs` | SCC Mute Configs | `project.project_id` |
| **project** | Project | `scc_sha_custom_modules` | SCC SHA Custom Modules | `project.project_id` |
| **project** | Project | `tags` | ResourceManager Tags | `project.project_id` |
| **project-factory** | N/A | `budgets` | Budgets | `billing_account` (from defaults) |
| **project-factory** | N/A | `folders` | Folders | `context` (Folder IDs) |
| **project-factory** | N/A | `projects` | Projects | `context`, `data_defaults`, `data_overrides` |
| **secops-rules** | N/A | `reference_lists` | SecOps Reference Lists | `project_id`, `tenant_config` |
| **secops-rules** | N/A | `rules` | SecOps Detection Rules | `project_id`, `tenant_config` |
| **vpc-sc** | Access Policy | `access_levels` | Access Levels | `access_policy`, `context` (for Project Numbers) |
| **vpc-sc** | Access Policy | `egress_policies` | Egress Policies | `access_policy`, `context` |
| **vpc-sc** | Access Policy | `ingress_policies` | Ingress Policies | `access_policy`, `context` |
| **vpc-sc** | Access Policy | `perimeters` | Service Perimeters | `access_policy`, `context` |
| **workstation-cluster** | Workstation Cluster | `workstation_configs` | Workstation Configurations | `project_id`, `location`, `network_config` |

## FAST Stages

The following table details how FAST stages implement factory patterns.

*   **Implementation Type**:
    *   `Module-Backed (Factory)`: The stage passes the `factories_config` path to a module which has internal logic to load and iterate over the data (e.g., `project-factory`).
    *   `Stage-Implemented (Module)`: The stage explicitly loads the YAML data (usually in `locals`) and iterates over a standard module (e.g., `dns` module).
    *   `Stage-Implemented (Resource)`: The stage explicitly loads the YAML data and iterates over raw Terraform resources.
    *   `Native (Complex)`: The stage implements complex factory logic combining multiple modules and resources.

| Stage | Factory (Key/Feature) | Implementation Type | Underlying Module/Resource |
| :--- | :--- | :--- | :--- |
| **0-org-setup** | `projects`, `folders`, `budgets` | Module-Backed (Factory) | `project-factory` |
| **1-vpcsc** | `access_levels`, `perimeters`, `policies` | Module-Backed (Factory) | `vpc-sc` |
| **2-networking** | `vpcs` | Module-Backed (Factory) | `net-vpc-factory` |
| **2-networking** | `projects` | Module-Backed (Factory) | `project-factory` |
| **2-networking** | `dns` (Zones) | Stage-Implemented (Module) | `dns` |
| **2-networking** | `dns_response_policies` | Stage-Implemented (Module) | `dns-response-policy` |
| **2-networking** | `firewall_policies` | Stage-Implemented (Module) | `net-firewall-policy` |
| **2-networking** | `vpns` | Stage-Implemented (Module) | `net-vpn-ha` |
| **2-networking** | `ncc_hubs` | Stage-Implemented (Resource) | `google_network_connectivity_hub` |
| **2-networking** | `ncc_groups` | Stage-Implemented (Resource) | `google_network_connectivity_group` |
| **2-networking** | `nvas` | Native (Complex) | `compute-vm`, `net-lb-int` |
| **2-project-factory** | `projects`, `folders`, `budgets` | Module-Backed (Factory) | `project-factory` |
| **2-project-factory** | `vpcs` | Module-Backed (Factory) | `net-vpc-factory` |
| **2-security** | `projects` | Module-Backed (Factory) | `project-factory` |
| **2-security** | `certificate_authorities` | Stage-Implemented (Module) | `certificate-authority-service` |
| **2-security** | `keyrings` (KMS) | Stage-Implemented (Module) | `kms` |
| **3-secops-dev** | `rules`, `reference_lists` | Module-Backed (Factory) | `secops-rules` |

## Maintenance Guide

This documentation is maintained to track factory patterns across the `modules` and `fast/stages` directories.

### To Update

#### 1. Modules Analysis

1.  **Identify Configuration:** Search for `variable "factories_config"` in typically `modules/your-module/variables.tf`.
2.  **Determine Keys:** Inspect the `factories_config` type (e.g., `object({ ... })`) to identify the keys like `rules`, `vpcs`, `projects`.
3.  **Find Usage:** Search for `var.factories_config.KEY` in the module's `main.tf` or `factory.tf` to see how the data is used.
4.  **Classify Resources:** Determine whether the factory logic creates module resources (e.g., `google_project`) or iterates a sub-module.
5.  **List Dependencies:** Note any module-level variables (e.g., `project_id`, `name`) that are injected into the factory-created resources.

#### 2. FAST Stages Analysis

1.  **Identify Configuration:** Search for `variable "factories_config"` in `fast/stages/your-stage/variables.tf`.
2.  **Find Usage:** Search for `var.factories_config.KEY` in the stage's implementation (often in `factory*.tf`).
3.  **Classify Implementation**:
    *   **Module-Backed (Factory)**: The `factories_config` path is passed directly to an underlying module (e.g., `project-factory`).
    *   **Stage-Implemented (Module)**: The stage explicitly loads the YAML/files and iterates over a standard module (e.g., `dns` module).
    *   **Stage-Implemented (Resource)**: The stage explicitly loads the YAML/files and iterates over raw Terraform resources (e.g., `google_network_connectivity_hub`).
    *   **Native (Complex)**: The stage implements complex logic combining multiple modules/resources (e.g., combining `compute-vm` and `net-lb-int` for NVAs).
