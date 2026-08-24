# Import maturity matrix

Maturity ladder — every resource family is at exactly one level:

| Level | Meaning | Exit criterion |
|---|---|---|
| **N** — named | Appears in an example manifest; no mapping rules yet | — |
| **C** — cookbook | Mapping rules + import IDs + module addresses derived from module source; not yet plan-tested live | cookbook section exists |
| **V** — verified | Clean imports, both gates green, address table confirmed live against real Google Cloud resources | verified across live rounds |

Verification target: everything in the four FAST-stage example
manifests at **V**. Maturity decays — every V carries the provider and
Fabric ref it was verified against; re-verify on bumps (see
"Regression habit").

## Matrix

| Family | Module | Level | Status / Notes |
|---|---|---|---|
| Org IAM + audit configs | organization | **V** | Seeded audit configs, `${` escaping verified |
| Org policies (incl. dry-run, parameters, custom constraints) | organization | **V** | Three-stream denominator enumeration verified |
| Custom roles | organization | **V** | From-scratch and modified roles verified |
| Org log sinks | organization | **V** | Destinations graduated to typed module references |
| Folders + folder IAM | folder (per instance) | **V** | Parent chaining and in-place rename verified |
| Projects, services, project IAM | project (per instance) | **V** | Project services and IAM bindings verified |
| Service accounts + impersonation IAM | iam-service-account | **V** | Leaf-IAM opt-in verified |
| VPC networks / subnets / routes | net-vpc | **V** | ForceNew alignment and subnet address mapping verified |
| Log buckets (sink destinations) | logging-bucket | **V** | Reference graduation verified |
| GCS buckets | gcs | **V** | State buckets, ForceNew project ID prefix verified |
| BigQuery datasets | bigquery-dataset | **V** | Datasets, import IDs, `description = null` alignment verified (tables/views/routines unverified) |
| Pub/Sub topics | pubsub | **V** | Topics, import IDs, sink reference graduation verified (subscriptions/schemas unverified) |
| DNS zones / policies | dns | **V** | Private zones, VPC reference link verified |
| NCC spokes (linked-VPC) | raw resource — **capability gap**: no Fabric module (`ncc-spoke-ra` is router-appliance only) | **V** (raw) | Upstream-issue candidate, lift with `moved {}` when a module appears |
| Cloud Routers / NAT | net-cloudnat | **V** | Integrated router + NAT verified |
| Firewall policies | net-firewall-policy | **C** | Mapping rules documented in cookbook (Hierarchical, Global, and Regional Network policies) |
| VPN / Interconnect attachments | net-vpn-*, net-vlan-attachment | **C** | Mapping rules documented in cookbook |
| KMS keyrings / keys + key IAM | kms | **V** | Seeded keyring, key, leaf-IAM on CryptoKey verified; permanent residue documented |
| Certificate Authority Service | certificate-authority-service | **V** | CA pools: CAI type, import ID, pool address (`google_privateca_ca_pool.default[0]`), `ca_configs = {}` default-CA trap, and `publishing_options` support verified on Fabric ref containing PR #4106 (commit `a153861aae`). Note: on releases lacking #4106, CAS reverts to capability gap |
| VPC-SC policy / perimeters | vpc-sc | **V** | Live AccessPolicy adopted, AccessLevel, dry-run ServicePerimeter; bare-numeric policy import ID verified; `unknown`-level classification handled in `inventory.py`. Enforced perimeters (`status` block) unverified |
| Tags (keys/values/bindings) | organization / folder / project tags | **V** | TagKey, TagValue, TagBinding, import IDs, address shapes, and `templatestring` escaping matrix (`$$${`) verified across org, 10 folders, and project (tag IAM unverified) |
| Billing account IAM | billing-account | **N** | — |
| Workload identity pools / providers | project identity-providers | **V** | WorkloadIdentityPool, WorkloadIdentityPoolProvider, import IDs, address shapes, 30-day soft-delete residue, and org policy constraints verified |
| Anything else | — | fallback | documented raw-resource fallback + capability-gap report |

## Verification Notes & Caveats

- **CAS & Custom Roles**: CAS `publishing_options` requires Fabric PR #4106 (`a153861aae`). Custom roles title/description convergence requires Fabric PR #4102.
- **Provider Label Inheritance**: Provider v5/v6/v7 generates computed `terraform_labels: {} -> {...}` diffs for resources with inherited provider labels. These are accounted for via scoped rules in `scripts/benign-drift.yaml`.

## Regression habit

On every provider minor bump, Fabric ref bump, or after long dormancy:
re-run both gates on the persisted workspace. New provider artifacts
fail loudly as residuals; resolve via value-guarded benign rules in
`scripts/benign-drift.yaml`, then re-stamp `verified_against`. Never widen
a rule to make a bump pass.
