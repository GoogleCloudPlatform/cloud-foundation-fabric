# FAST release upgrading notes

This file only mentions changes that require changes to Terraform variables, or replace existing resources. "Soft" additions like new features or optional attributes are non-breaking and not considered here.

If the address of a resource has changed between FAST versions, we usually created a file in `fast/stages/n-STAGENAME/moved/` which contains a number of [moved blocks](https://developer.hashicorp.com/terraform/language/moved) which can be copied to the n-stagename directory before executing `terraform plan` or `terraform apply`.

We do an effort at covering most stages, but don't typically cover multitenant and stage 3s as there's too much variance in use cases and potential configurations.

As usual, consider this a guideline with no guarantees. Migrations between FAST releases are actively discouraged for production, and mostly make sense only when developing or testing new features.

<!-- markdownlint-disable MD024 -->

<!-- BEGIN TOC -->
- [v35.1.0 to v36.0.0](#v3510-to-v3600)
  - [Bootstrap stage](#bootstrap-stage)
  - [Resource Management stage](#resource-management-stage)
  - [Networking stages](#networking-stages)
  - [Security stage](#security-stage)
- [v34.0.0 to v35.1.0](#v3400-to-v3510)
  - [Bootstrap stage](#bootstrap-stage)
  - [Resource management stage](#resource-management-stage)
  - [Networking](#networking)
<!-- END TOC -->

## v35.1.0 to v36.0.0

### Bootstrap stage

**Breaking changes:**

- the `factories_config.org_policy` variable attribute has been renamed to `factories_config.org_policies`

**Non-breaking changes:**

- two new custom roles have been added: `gcveNetworkViewer` and `projectIAMViewer`
- organization policies for the IaC project have been moved to a factory, default policies are in `data/org-policies-iac`
- new `compute.setNewProjectDefaultToZonalDNSOnly` organization policy constraint has been added to mirror default configuration on new organizations

### Resource Management stage

The Resource Management stage has been largely refactored, adopting factories to simplify the creation of multiple environments and the creation and deployment of new "Stage 3" stages. Before upgrading it's highly recommended to familiarize yourself with the documentation, to assess whether your specific configurations need to be migrated to the new variables.

The [file containing moved blocks](./1-resman/moved/v35.1.0-v36.0.0.tf) for this release can be used to preserve most of the important resources which changed from the previous release. Just link it in the stage and plan/apply to see the remaining changes.

The moved blocks are not exhaustive and do not include resources that can be dropped and recreated with limited impact like IAM and tag bindings. As usual, proceed with care as we provide no guarantee, just a starting point.

Given the amount of resource changes at the IAM level, we suggest applying twice in a row to make sure there are no inconsistencies left in IAM policies.

**Breaking changes:**

- variables controlling stage 2s and 3s have changed and are now explicit, check their configuration to make sure it matches your current layout
  - the `fast_features` variable has been removed
  - the `fast_stage_2` and `fast_stage_2` variables control now control stage activation and configuration
- a new factory has been added for stage 3s, with an initial default configuration that matches enabling everything in the old fast features variable
- the "Data Platform" stage 3 has been removed in preparation of a completely revised state, any associated resource (service accounts, folders, buckets, etc.) will be destroyed
- billing IAM bindings will be destroyed and recreated as they are now driven by a loop and their names have changed
- GCVE network IAM bindings will be destroyed and recreated as they are now segregated by environment

**Non-breaking changes:**

- GCS and local output files will be recreated

### Networking stages

IAM bindings for stage 3 service accounts change and will be dropped and recreated.

### Security stage

IAM bindings for stage 3 service accounts change and will be dropped and recreated.

## v34.0.0 to v35.1.0

### Bootstrap stage

**Non-breaking changes:**

- new `essentialcontacts.allowedContactDomains` organization policy constraint and `org-policies/allowed-essential-contacts-domains-all` tag; if the policy already exists in your organization, import it via state or delete it using `gcloud org-policy delete essentialcontacts.allowedContactDomains --organization ORGANIZATION_ID`

### Resource management stage

**Non-breaking changes:**

- output files update
- resource attribute updates following provider version change

### Networking

- additional DNS response policy for the `gke.goog` domain
