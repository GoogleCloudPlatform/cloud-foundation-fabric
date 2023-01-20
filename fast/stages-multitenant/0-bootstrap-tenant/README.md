# Tenant bootstrap

The primary purpose of this stage is to decouple a single tenant from centrally managed resources in the organization, so that subsequent management of the tenant's own hierarchy and resources can be implemented with a high degree of autonomy.

It is logically equivalent to organization-level bootstrap as it's concerned with setting up IAM bindings on a root node and creating supporting projects attached to it, but it depends on the organization-level resource management stage and uses the same service account and permissions since it operates at the hierarchy level (folders, tags, organization policies).

The resources and policies managed here are:

- the tag value in the `tenant` key used in IAM conditions
- the billing IAM bindings for the tenant-specific automation service accounts
- the organization-level IAM binding that allows conditional managing of org policies on the tenant folder
- the top-level tenant folder which acts as the root of the tenant's hierarchy
- any organization policy that needs to be set for the tenant on its root folder
- the tenant automation and logging projects
- service accounts for all tenant stages
- GCS buckets for bootstrap and resource management state
- optional CI/CD setup for this and the resource management tenant stages
- tenant-specific Workload Identity Federation pool and providers (planned)

<!-- https://mdigi.tools/darken-color/#f1f8e9 -->

One notable difference compared to organization-level bootstrap is the creation of service accounts for all tenant stages: this is handled here so that billing and Organization Policy Admin bindings can be set. These bindings require broad permissions which the org-level resman service account used to run this stage already has, avoiding the need to grant them to tenant-level service accounts and effectively decoupling the tenant from the organization.

The following diagram is a high level reference of what this stage manages, showing two hypothetical tenants (which would need two distinct copies of this stage):

<p align="center">
  <img src="diagram.svg" alt="Tenant-level bootstrap">
</p>

As most of the features of this stage follow the same design and configurations of the [organization-level bootstrap stage](../../stages/0-bootstrap/), we will only focus on the tenant-specific configuration in this document.

## Naming

## How to run this stage

### Tenant-level configuration

### Output files and cross-stage variables

### Running the stage

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->

<!-- END TFDOC -->