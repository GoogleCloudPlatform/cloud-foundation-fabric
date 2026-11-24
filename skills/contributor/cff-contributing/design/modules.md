# Module Boundaries and Ownership

This guide governs what belongs inside a Fabric module, when a new module should be created or rejected, how bindings and cross-service relationships are owned, and how outputs handle internal dependencies. Always read this alongside [design/interfaces.md](interfaces.md) — module boundaries and interface shapes co-determine each other.

## Logical Entity vs Product, Feature, or API Namespace

Design every module around a **logical functional unit** — the subset of resources that makes one entity usable on its own — rather than around a single GCP feature or a Terraform provider API prefix.

- **Why we do this:** Originally adopted to make composing end-to-end infrastructure practical, logical-entity encapsulation also turned out to be a major readability win ("code as documentation") and delivers a **"ready to use"** guarantee: once a caller invokes `modules/project` (or any other entity module), sibling modules and human users can immediately rely on it as fully configured (APIs, IAM, policies, logging sinks, Shared VPC, CMEK) across both prototyping and production runs.
- **Resource management modules move in unison:** The three resource management modules (`organization`, `folder`, `project`) share canonical interfaces for every overlapping capability they support (IAM, organization policies, tag keys/values/bindings, logging sinks, PAM entitlements, SCC configs, Model Armor, hierarchical policies). Any feature added or changed across those modules must keep the exact same interface across all applicable levels.
- **API namespace is not a logical entity:** Distinct GCP products can share one API namespace (for example, Vertex AI Search, Dialogflow CX, and Gemini Enterprise all live under `google_discovery_engine_*`). If half of a module's variables never apply to one of the products inside it, or validations conflict across products, the boundary is wrong — split by logical product instead (see [geap-gemini-enterprise ADR](../../../../adrs/modules/20261116-geap-gemini-enterprise.md)).
- **Do not trap shared container settings inside a single-item module:** If GCP scopes a shared setting to a container (for example, one IdP or CMEK configuration per `(project, location)` shared by all apps in that location), managing that shared setting inside a module that creates only one app will collide as soon as a second app is deployed in the same location. Manage the shared container once and accept a map of child items, or place the shared setting on the owning container module (`modules/project`, `modules/net-vpc`, etc.); do not use this rule to justify a thin single-resource wrapper module.

## When NOT to Add a Module

Reject or redirect a request at Step 0 when it falls into any of these patterns:

- **Thin single-resource wrappers:** A module that wraps one `google_*` resource with no logical sub-resources, IAM, context, or ergonomic aggregation adds indirection without value.
- **Standalone feature modules:** Central IAM, tag-binding, or log-sink modules break logical-entity encapsulation.
- **Unrelated resource bundles:** Never combine unrelated resources (such as a project plus a BigQuery dataset) inside a standard module. Only the two aggregation modules (`modules/project-factory` and `modules/net-vpc-factory`) break this boundary.
- **One-off or end-to-end reference topologies:** Opinionated or end-to-end sample architectures do not belong in `modules/`. Place reference designs that cannot fit in FAST under `fast/project-templates/`, end-to-end GCP documentation examples ported to Fabric under module-level recipes (`modules/<module>/recipe-*`), and customer-specific topologies in consumer repositories.

## Binding Ownership

When a GCP feature attaches a policy, binding, or tag to a target (organization, folder, project, or VPC), the **target-side interface is canonical and mandatory** where the API allows it (`tag_bindings`, `firewall_policy`, `cloud_armor_policy`, `firewall_policy_associations`). Ownership follows the logical target entity (for example, organization-level bindings belong in `modules/organization`), not the GCP API or Terraform provider resource prefix. A **policy-side interface** (`attachments` map on the policy module) is accepted as a second interface only when centralized cross-hierarchy management or policy-only flags (such as exclusions) make it a definite usage pattern: hierarchical firewall policies and hierarchical Cloud Armor policies qualify; tags do not. Callers manage any given binding from one side at a time (both module interfaces coexist where dual ownership applies), match cardinality to the API, and see [hierarchy-bindings ADR](../../../../adrs/modules/20261029-hierarchy-bindings.md) for the exact interface shapes and rules.

## Cross-Service Boundaries, `data` Sources, and `local-exec`

- **No project-level companion IAM inside service modules:** A service module manages IAM only on its own resources. Project-level roles required by users or workloads belong in `modules/project` or higher-level composition. Where helpful, expose a wiring output (such as `app_iam_principals`) so callers can pass principals into `modules/project`.
- **Intrinsic cross-project exceptions:** Crossing a project boundary from inside a module is acceptable only when the relationship is intrinsic to the logical entity — for example, `shared_vpc_service_config`, `service_encryption_key_ids`, or `service_agents_project_bindings` in `modules/project` (where only the project module knows the project number needed to construct its service agent email).
- **Avoid `data` sources:** See [CURSED_KNOWLEDGE.md](../../../../CURSED_KNOWLEDGE.md#avoid-data-resources). Reads deferred to apply turn outputs into `known after apply` (causing spurious replacements) and can make partial-apply failures unrecoverable. Use `data` sources only for invariants guaranteed to exist across the state lifecycle, non-`ForceNew` attributes, or opt-in reuse patterns (`project_reuse`, `folder_create = false`).
- **Avoid `local-exec` and external tools:** Never rely on `local-exec`, third-party CLIs, or external scripts. The only acceptable exception is an isolated, documented, temporary workaround for a confirmed upstream GCP API or provider bug, clearly scoped and tagged for removal once the provider catches up (as documented in [geap-gemini-enterprise ADR](../../../../adrs/modules/20261116-geap-gemini-enterprise.md)).

## Outputs and Dependency Encapsulation

Tie primary outputs (such as `id` or `name`) to internal setup resources with explicit `depends_on` — most importantly **IAM**, API enablement, and service identities — so downstream modules receive a ready-to-use entity. Compute primary outputs from inputs where safe (for example, `value = local.project_id`) so they still work as `for_each` keys while `depends_on` preserves ordering.

**Be deliberate about dependency tiering rather than chaining every internal resource blindly:** In complex modules like `modules/project` and `modules/project-factory`, actual usage forces trade-offs (for example, automatically depending downstream work on organization policies can collide with IAM needed to apply those policies, and org policies propagate asynchronously in GCP anyway). Check whether a resource belongs in primary output `depends_on` or in a separate second pass before adding it.

```hcl
# From modules/project/outputs.tf (abridged)
output "id" {
  description = "Project id."
  value       = local.project_id
  depends_on = [
    google_project.project,
    google_project_service.project_services,
    google_project_service_identity.default,
    google_project_iam_member.service_agents,
    google_compute_shared_vpc_service_project.shared_vpc_service,
    google_kms_crypto_key_iam_member.service_agent_cmek
  ]
}
```
