# Application Factory Module — PRD

## Overview

A Terraform module at `modules/application-factory/` that allows users to specify all the resource-level components for an application or service via a YAML interface. Part of the same family as `project-factory` and `net-vpc-factory`.

- **Single application** per module instance (future FAST stage will use Terraform workspaces)
- **YAML-driven**: one `<resource-type>/<resource-name>.yaml` file per resource instance
- Resource name derived from filename, can be overridden in YAML (same as project-factory)
- **No Terraform resources directly** — wraps existing low-level modules
- **No defaults/overrides/merges** in this iteration (deferred to later)

## Projects

The module supports multiple projects. Project IDs come from:

- `context.project_ids` (external static references)
- Explicit `project_id` in each resource's YAML file

## Context

The `context` variable uses the standard keys from other modules, extended with new keys:

- Standard: `condition_vars`, `custom_roles`, `email_addresses`, `folder_ids`, `iam_principals`, `kms_keys`, `locations`, `log_buckets`, `notification_channels`, `project_ids`, `project_numbers`, `pubsub_topics`, `storage_buckets`, `tag_keys`, `tag_values`, `vpc_host_projects`, `vpc_sc_perimeters`
- New: `secrets`, `datasets`, `artifact_registries`

### Context enrichment

Resources created within the factory enrich the context for downstream resources:

| Resource Type | Enriches Context Key |
|---------------|---------------------|
| `iam-service-account` | `iam_principals` |
| `gcs` | `storage_buckets` |
| `pubsub` | `pubsub_topics` |
| `bigquery-dataset` | `datasets` |
| `secret-manager` | `secrets` |
| `artifact-registry` | `artifact_registries` |

External static references via `var.context` are merged with factory-created enrichments.

### Context seen by each module

The context passed to each low-level module is always a merge of:

1. **Variable-level static context** (`var.context`) — provided externally by the caller
2. **Factory-created enrichments** — from other resources created within this factory, limited to the keys relevant for that module's phase

This ensures every module sees both the external references and the internally-created resources it may need to reference.

## IAM Split

Only `iam-service-account` uses the two-phase split pattern (create + IAM, like the project-factory). All other modules get IAM inline in a single call.

## Resource Types (10)

| Phase | Resource Type | Module Source | Enriches Context | IAM Split |
|-------|--------------|---------------|------------------|-----------|
| 1 | service-accounts | `iam-service-account` | `iam_principals` | Yes |
| 2 | gcs | `gcs` | `storage_buckets` | No |
| 2 | pubsub | `pubsub` | `pubsub_topics` | No |
| 2 | bigquery | `bigquery-dataset` | `datasets` | No |
| 2 | secret-manager | `secret-manager` | `secrets` | No |
| 2 | artifact-registry | `artifact-registry` | `artifact_registries` | No |
| 3 | compute-vm | `compute-vm` | — | No |
| 3 | cloudsql | `cloudsql-instance` | — | No |
| 4 | net-lb-int | `net-lb-int` | — | No |
| 4 | net-lb-app-int | `net-lb-app-int` | — | No |

### Phase dependencies

- **Phase 1**: Service accounts are created first, enriching `iam_principals` for all subsequent phases.
- **Phase 2**: Storage, messaging, data, and security resources. Can reference service accounts. Enrich their respective context keys.
- **Phase 3**: Compute and database resources. Can reference everything from phases 1-2.
- **Phase 4**: Load balancers. Can depend on VMs from phase 3.

## YAML Structure

```
<basepath>/
  service-accounts/
    sa-name.yaml
  gcs/
    bucket-name.yaml
  pubsub/
    topic-name.yaml
  bigquery/
    dataset-name.yaml
  secret-manager/
    secret-name.yaml
  artifact-registry/
    repo-name.yaml
  compute-vm/
    vm-name.yaml
  cloudsql/
    instance-name.yaml
  net-lb-int/
    lb-name.yaml
  net-lb-app-int/
    lb-name.yaml
```

Each YAML file's schema matches the corresponding low-level module's variable types. Fields are accessed via `try` statements to protect the lower-level interface.

## `factories_config` Variable

Same pattern as project-factory: a `basepath` plus per-resource-type relative paths.

```hcl
variable "factories_config" {
  type = object({
    basepath = string
    paths = optional(object({
      service_accounts  = optional(string, "service-accounts")
      gcs               = optional(string, "gcs")
      pubsub            = optional(string, "pubsub")
      bigquery          = optional(string, "bigquery")
      secret_manager    = optional(string, "secret-manager")
      artifact_registry = optional(string, "artifact-registry")
      compute_vm        = optional(string, "compute-vm")
      cloudsql          = optional(string, "cloudsql")
      net_lb_int        = optional(string, "net-lb-int")
      net_lb_app_int    = optional(string, "net-lb-app-int")
    }), {})
  })
}
```

## Outputs

Each resource type exposes its own output, keyed by resource name, surfacing the underlying module outputs.

| Output | Source | Description |
| ------ | ------ | ----------- |
| `service_accounts` | `module.service-accounts` | SA emails, IAM emails, keys |
| `gcs` | `module.gcs` | Bucket names, URLs |
| `pubsub` | `module.pubsub` | Topic IDs, subscription IDs |
| `bigquery` | `module.bigquery` | Dataset IDs |
| `secret_manager` | `module.secret-manager` | Secret IDs, versions |
| `artifact_registry` | `module.artifact-registry` | Repository IDs |
| `compute_vm` | `module.compute-vm` | Instance IDs, IPs |
| `cloudsql` | `module.cloudsql` | Instance names, connection names, IPs |
| `net_lb_int` | `module.net-lb-int` | Forwarding rule IDs, IPs |
| `net_lb_app_int` | `module.net-lb-app-int` | Forwarding rule IDs, IPs |

Each output is the full module object for that resource, allowing consumers to access any attribute the low-level module exposes.

## Implementation Tasks

### Preliminary Tasks

| Task | Path | Details |
| ---- | ---- | ------- |
| T0a | `schemas/*.schema.json` | JSON Schema for each resource type's YAML interface |
| T0b | `sample/<type>/*.yaml` | Sample dataset exercising all 10 resource types |
| T0c | (validation) | Validate sample dataset against schemas |

### Module Implementation

| Task | File | Details |
| ---- | ---- | ------- |
| T1 | `main.tf` | Context locals, path resolution, YAML reading infrastructure |
| T2 | `variables.tf` | `context`, `factories_config` variables |
| T3 | `service-accounts.tf` | Phase 1: create SAs + IAM split, export `iam_principals` enrichment |
| T4 | `gcs.tf` | Phase 2: buckets, export `storage_buckets` enrichment |
| T5 | `pubsub.tf` | Phase 2: topics, export `pubsub_topics` enrichment |
| T6 | `bigquery.tf` | Phase 2: datasets, export `datasets` enrichment |
| T7 | `secret-manager.tf` | Phase 2: secrets, export `secrets` enrichment |
| T8 | `artifact-registry.tf` | Phase 2: registries, export `artifact_registries` enrichment |
| T9 | `compute-vm.tf` | Phase 3: VMs |
| T10 | `cloudsql.tf` | Phase 3: CloudSQL instances |
| T11 | `net-lb-int.tf` | Phase 4: internal TCP/UDP LBs (depends on VMs) |
| T12 | `net-lb-app-int.tf` | Phase 4: internal HTTP(S) LBs (depends on VMs) |
| T13 | `outputs.tf` | All outputs |

### Follow-up Tasks

| Task | Details |
| ---- | ------- |
| T14 | Add native `context` variable support to `artifact-registry`, `cloudsql-instance`, `net-lb-app-int` modules (project_id, locations, IAM, custom_roles, kms_keys, tag_values) |
| T15 | Tests |
| T16 | README |
| T17 | Ensure YAML schemas for resource types also supported by `project-factory` are reused from there |

## Patterns to Follow

- **Context interpolation**: single `local.ctx` / `var.context` per the [context locals ADR](../../adrs/20251013-context-locals.md)
- **`try` statements**: protect all YAML field access to avoid breaking lower-level module interfaces
- **Module wrapping**: pass YAML data through to module variables, never use Terraform resources directly
- **YAML reading**: `fileset` + `yamldecode` pattern from project-factory
- **Path resolution**: basepath-relative paths with `pathexpand`, same as project-factory
