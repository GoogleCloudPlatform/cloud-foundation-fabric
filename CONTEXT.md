# Context Support in Cloud Foundation Fabric

Context is a standardized mechanism in CFF modules to allow loose coupling between resources. It enables modules to refer to external resources (like Project IDs, Service Accounts, KMS Keys, etc.) via logical keys (mnemonics) rather than hardcoded IDs or complex variable piping.

## Contents

- [Interface](#interface)
  - [Usage Examples](#usage-examples)
- [Supported Namespaces](#supported-namespaces)
- [Implementation Patterns](#implementation-patterns)
  - [1. Local Lookup Map](#1-local-lookup-map)
  - [2. Usage in Resources](#2-usage-in-resources)
  - [3. Dereferencing Single Values](#3-dereferencing-single-values)
- [Testing Standard](#testing-standard)
  - [1. Test Configuration (`tftest.yaml`)](#1-test-configuration-tftestyaml)
  - [2. Test Inputs (`context.tfvars`)](#2-test-inputs-contexttfvars)
  - [3. Expected Output (`context.yaml`)](#3-expected-output-contextyaml)
- [Module Adoption Status](#module-adoption-status)
- [Refactoring Learning Checklist](#refactoring-learning-checklist)

## Interface

Modules capable of context interpolation expose a single `context` variable.

```terraform
variable "context" {
  description = "Context-specific interpolations."
  type = object({
    # Common namespaces
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    project_ids    = optional(map(string), {})
    # ... other namespaces as needed
  })
  default  = {}
  nullable = false
}
```

> [!NOTE]
> The `condition_vars` namespace is an exception: it is a `map(map(string))` used for `templatestring` variable substitution in IAM conditions and Organization Policies, rather than simple value replacement.

### Usage Examples

Context variables are passed as a map of maps. The keys of the outer map correspond to the supported namespaces. The inner map defines the alias (key) and the actual value (value) to be substituted.

#### Example: Project, IAM and Condition Context

```terraform
module "my-project" {
  source = "./modules/project"
  # Context definition
  context = {
    project_ids = {
      shared-vpc = "host-project-123"
    }
    iam_principals = {
      gcp-devops = "group:gcp-devops@example.com"
    }
    condition_vars = {
      tag_values = {
        "context/foo" = "tagValues/1234567890"
      }
    }
  }
  # Context usage via "$" prefix
  shared_vpc_host_config = {
    host_project = "$project_ids:shared-vpc"
  }
  iam = {
    "roles/owner" = ["$iam_principals:gcp-devops"]
  }
  # IAM condition using condition_vars
  iam_bindings = {
    context_access = {
      role    = "roles/storage.objectViewer"
      members = ["$iam_principals:gcp-devops"]
      condition = {
        title      = "match_tag"
        expression = "resource.matchTagId(tagValueId, '$${tag_values['context/foo']}')"
      }
    }
  }
}
```

## Supported Namespaces

The following namespaces are currently defined across the codebase. Modules typically implement a subset of these relevant to their function.

| Namespace | Description | Typical Value Format |
| :--- | :--- | :--- |
| `access_levels` | Access Context Manager Levels | `accessPolicies/123/accessLevels/name` |
| `addresses` | IP Addresses | `1.2.3.4` or `projects/p/regions/r/addresses/n` |
| `bigquery_datasets` | BigQuery Dataset IDs | `project_id:dataset_id` |
| `cidr_ranges` | CIDR blocks | `10.0.0.0/24` |
| `cidr_ranges_sets` | Sets of CIDR ranges | List of CIDRs |
| `condition_vars` | IAM Condition Variables | Map of values for interpolation |
| `custom_roles` | Custom IAM Roles | `organizations/123/roles/RoleName` |
| `email_addresses` | Email addresses | `user@example.com` |
| `folder_ids` | Folder IDs | `folders/123456` |
| `folder_sets` | Sets of Folders | List of Folder IDs |
| `iam_principals` | IAM Principals | `group:name@example.com`, `serviceAccount:...` |
| `identity_sets` | VPC-SC Identity Sets | List of identities |
| `kms_keys` | KMS Key IDs | `projects/p/locations/l/keyRings/k/cryptoKeys/c` |
| `locations` | GCP Regions/Zones | `europe-west1` |
| `log_buckets` | Logging Buckets | `projects/p/locations/l/buckets/b` |
| `networks` | VPC Network IDs | `projects/p/global/networks/n` |
| `notification_channels` | Monitoring Channels | `projects/p/notificationChannels/123` |
| `project_ids` | Project IDs | `my-project-id` |
| `project_numbers` | Project Numbers | `1234567890` |
| `project_sets` | Sets of Projects | List of Project IDs |
| `pubsub_topics` | Pub/Sub Topics | `projects/p/topics/t` |
| `regions` | GCP Regions | `europe-west1` |
| `resource_sets` | VPC-SC Resource Sets | List of projects/services |
| `routers` | Cloud Routers | `projects/p/regions/r/routers/name` |
| `service_account_ids` | Service Account IDs (short) | `my-sa` (often used in project factory) |
| `service_sets` | VPC-SC Service Sets | List of APIs |
| `storage_buckets` | GCS Bucket Names | `my-bucket-name` |
| `subnets` | Subnet IDs | `projects/p/regions/r/subnetworks/s` |
| `subnetworks` | Subnet IDs | `projects/p/regions/r/subnetworks/s` |
| `tag_keys` | Tag Key IDs | `tagKeys/123` |
| `tag_values` | Tag Value IDs | `tagValues/456` |
| `vpc_host_projects` | Shared VPC Host Project IDs | `host-project-id` |
| `vpc_sc_perimeters` | VPC-SC Perimeter Names | `accessPolicies/123/servicePerimeters/name` |
| `vpn_gateways` | VPN Gateway IDs | `projects/p/regions/r/targetVpnGateways/name` |

## Implementation Patterns

### 1. Local Lookup Map

Modules usually compute a local map that handles the lookup logic. If a key is found in the context variable, the context value is used. If not, the key itself is used (passthrough), or it facilitates the expansion of short aliases.

```terraform
locals {
  # ... processing
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"
}

> [!NOTE]
> `condition_vars` is excluded from the flattening loop because it preserves its nested structure for `templatestring` usage.
```

### 2. Usage in Resources

Resources use `lookup()` to resolve values.

```terraform
resource "google_project_iam_binding" "authoritative" {
  # ...
  members = [
    for m in each.value : lookup(local.ctx.iam_principals, m, m)
  ]
}
```

This allows a user to pass either a raw IAM principal (`user:foo@example.com`) or a context reference (`$iam_principals:my-user`).


### 3. Dereferencing Single Values

For variables that represent a single value (like `project_id`, `location`, or `network`), the best practice is to resolve them once in `locals` and use the local variable throughout the module.

```terraform
locals {
  # ... context processing
  project_id = var.project_id == null ? null : lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
}

resource "google_storage_bucket" "bucket" {
  project = local.project_id
  # ...
}
```

## Testing Standard

Modules supporting context **MUST** have a dedicated test case to verify context interpolation works correctly.

### 1. Test Configuration (`tftest.yaml`)

Add a `context` test entry in `tests/modules/<module>/tftest.yaml`.

```yaml
tests:
  # ... other tests
  context:
    # Uses context.tfvars and context.yaml by convention
```

### 2. Test Inputs (`context.tfvars`)

Create `tests/modules/<module>/context.tfvars` defining the mocks:

```terraform
context = {
  iam_principals = {
    my-user = "user:test@example.com"
  }
}
# Variable using the context key
iam = {
  "roles/viewer" = ["$iam_principals:my-user"]
}
```

### 3. Expected Output (`context.yaml`)

Run the following command to generate the initial plan summary, then **manually add the Apache 2.0 license header**:

```bash
python3 tools/plan_summary.py modules/<module> tests/modules/<module>/context.tfvars > tests/modules/<module>/context.yaml
```

The file `tests/modules/<module>/context.yaml` contains the expected plan output (inventory). This ensures the module correctly resolves `$iam_principals:my-user` to `user:test@example.com` in the generated resource.

```yaml
values:
  google_project_iam_binding.authoritative["roles/viewer"]:
    members:
      - user:test@example.com
```

## Module Adoption Status

| Module | Context Implemented | Could Use Context |
| :--- | :--- | :--- |
| [`agent-engine`](./modules/agent-engine) | ✅ | ✅ |
| [`ai-applications`](./modules/ai-applications) | ❌ | ✅ |
| [`alloydb`](./modules/alloydb) | ❌ | ✅ |
| [`analytics-hub`](./modules/analytics-hub) | ❌ | ✅ |
| [`api-gateway`](./modules/api-gateway) | ❌ | ✅ |
| [`apigee`](./modules/apigee) | ❌ | ✅ |
| [`artifact-registry`](./modules/artifact-registry) | 🔵 | ✅ |
| [`backup-dr`](./modules/backup-dr) | ❌ | ✅ |
| [`biglake-catalog`](./modules/biglake-catalog) | ❌ | ✅ |
| [`bigquery-connection`](./modules/bigquery-connection) | ✅ | ✅ |
| [`bigquery-dataset`](./modules/bigquery-dataset) | ✅ | ✅ |
| [`bigtable-instance`](./modules/bigtable-instance) | ❌ | ✅ |
| [`billing-account`](./modules/billing-account) | ✅ | ✅ |
| [`binauthz`](./modules/binauthz) | ❌ | ✅ |
| [`certificate-authority-service`](./modules/certificate-authority-service) | ✅ | ✅ |
| [`certificate-manager`](./modules/certificate-manager) | ❌ | ✅ |
| [`cloud-build-v2-connection`](./modules/cloud-build-v2-connection) | ✅ | ✅ |
| [`cloud-config-container`](./modules/cloud-config-container) | ❌ | ❌ |
| [`cloud-deploy`](./modules/cloud-deploy) | ❌ | ✅ |
| [`cloud-function-v1`](./modules/cloud-function-v1) | ✅ | ✅ |
| [`cloud-function-v2`](./modules/cloud-function-v2) | ✅ | ✅ |
| [`cloud-identity-group`](./modules/cloud-identity-group) | ❌ | ✅ |
| [`cloud-run-v2`](./modules/cloud-run-v2) | ✅ | ✅ |
| [`cloudsql-instance`](./modules/cloudsql-instance) | ❌ | ✅ |
| [`compute-mig`](./modules/compute-mig) | 🔵 | ✅ |
| [`compute-vm`](./modules/compute-vm) | ✅ | ✅ |
| [`container-registry`](./modules/container-registry) | ❌ | ✅ |
| [`data-catalog-policy-tag`](./modules/data-catalog-policy-tag) | ✅ | ✅ |
| [`data-catalog-tag`](./modules/data-catalog-tag) | ❌ | ❌ |
| [`data-catalog-tag-template`](./modules/data-catalog-tag-template) | ❌ | ✅ |
| [`dataform-repository`](./modules/dataform-repository) | ❌ | ✅ |
| [`datafusion`](./modules/datafusion) | ❌ | ✅ |
| [`dataplex`](./modules/dataplex) | ❌ | ✅ |
| [`dataplex-aspect-types`](./modules/dataplex-aspect-types) | ✅ | ✅ |
| [`dataplex-datascan`](./modules/dataplex-datascan) | ❌ | ✅ |
| [`dataproc`](./modules/dataproc) | ❌ | ✅ |
| [`dns`](./modules/dns) | ✅ | ✅ |
| [`dns-response-policy`](./modules/dns-response-policy) | ✅ | ✅ |
| [`endpoints`](./modules/endpoints) | ❌ | ✅ |
| [`firestore`](./modules/firestore) | ❌ | ✅ |
| [`folder`](./modules/folder) | ✅ | ✅ |
| [`gcs`](./modules/gcs) | ✅ | ✅ |
| [`gcve-private-cloud`](./modules/gcve-private-cloud) | ❌ | ✅ |
| [`gke-cluster-autopilot`](./modules/gke-cluster-autopilot) | 🔵 | ✅ |
| [`gke-cluster-standard`](./modules/gke-cluster-standard) | 🔵 | ✅ |
| [`gke-hub`](./modules/gke-hub) | 🔵 | ✅ |
| [`gke-nodepool`](./modules/gke-nodepool) | 🔵 | ✅ |
| [`iam-service-account`](./modules/iam-service-account) | ✅ | ✅ |
| [`kms`](./modules/kms) | ✅ | ✅ |
| [`logging-bucket`](./modules/logging-bucket) | ✅ | ✅ |
| [`looker-core`](./modules/looker-core) | ❌ | ✅ |
| [`managed-kafka`](./modules/managed-kafka) | ❌ | ✅ |
| [`ncc-spoke-ra`](./modules/ncc-spoke-ra) | ❌ | ✅ |
| [`net-address`](./modules/net-address) | ❌ | ✅ |
| [`net-cloudnat`](./modules/net-cloudnat) | ✅ | ✅ |
| [`net-firewall-policy`](./modules/net-firewall-policy) | ✅ | ✅ |
| [`net-ipsec-over-interconnect`](./modules/net-ipsec-over-interconnect) | ❌ | ✅ |
| [`net-lb-app-ext`](./modules/net-lb-app-ext) | ❌ | ✅ |
| [`net-lb-app-ext-regional`](./modules/net-lb-app-ext-regional) | ❌ | ✅ |
| [`net-lb-app-int`](./modules/net-lb-app-int) | ❌ | ✅ |
| [`net-lb-app-int-cross-region`](./modules/net-lb-app-int-cross-region) | ❌ | ✅ |
| [`net-lb-ext`](./modules/net-lb-ext) | ❌ | ✅ |
| [`net-lb-int`](./modules/net-lb-int) | ✅ | ✅ |
| [`net-lb-proxy-int`](./modules/net-lb-proxy-int) | ❌ | ✅ |
| [`net-swp`](./modules/net-swp) | ❌ | ✅ |
| [`net-vlan-attachment`](./modules/net-vlan-attachment) | ❌ | ✅ |
| [`net-vpc`](./modules/net-vpc) | ✅ | ✅ |
| [`net-vpc-factory`](./modules/net-vpc-factory) | ✅ | ✅ |
| [`net-vpc-firewall`](./modules/net-vpc-firewall) | ✅ | ✅ |
| [`net-vpc-peering`](./modules/net-vpc-peering) | 🔵 | ❌ |
| [`net-vpn-dynamic`](./modules/net-vpn-dynamic) | ❌ | ✅ |
| [`net-vpn-ha`](./modules/net-vpn-ha) | ✅ | ✅ |
| [`net-vpn-static`](./modules/net-vpn-static) | ❌ | ✅ |
| [`organization`](./modules/organization) | ✅ | ✅ |
| [`project`](./modules/project) | ✅ | ✅ |
| [`project-factory`](./modules/project-factory) | ✅ | ✅ |
| [`projects-data-source`](./modules/projects-data-source) | ❌ | ✅ |
| [`pubsub`](./modules/pubsub) | ✅ | ✅ |
| [`secops-rules`](./modules/secops-rules) | ❌ | ✅ |
| [`secret-manager`](./modules/secret-manager) | ✅ | ✅ |
| [`secure-source-manager-instance`](./modules/secure-source-manager-instance) | ❌ | ✅ |
| [`service-directory`](./modules/service-directory) | ❌ | ✅ |
| [`source-repository`](./modules/source-repository) | ❌ | ✅ |
| [`spanner-instance`](./modules/spanner-instance) | ❌ | ✅ |
| [`vpc-sc`](./modules/vpc-sc) | ✅ | ✅ |
| [`workstation-cluster`](./modules/workstation-cluster) | ✅ | ✅ |

## Refactoring Learning Checklist

### Variables & Locals

- **Variables**: No comments inside `type = object(...)` definitions.
- **Locals Ordering**:
  - `_` prefixed locals first (used only in current block).
  - Lexical order for the rest.
- **One-shot Locals**:
  - Resolve frequently used context variables (`project_id`, `location`, `kms_key`) once in `locals` block.
  - Guard against nulls if necessary (e.g. `var.key == null ? null : lookup(...)`).

### Resources & Outputs

- **Resource Attributes**: `provider` attribute comes first.
- **Outputs**: Use resolved locals in `outputs.tf` (especially for URLs/IDs) to ensure context substitutions are reflected.

### Tests

- **Configuration**: Use correct structure in `tftest.yaml` (test names as keys, empty values or dicts). **Do not use `count`**.
- **Inventory**:
  - Use `tools/plan_summary.py` to generate `context.yaml`.
  - **Always add the Apache 2.0 license header** to the generated YAML file.
  - Verify context keys (e.g. `$tag_values:tv1`) are handled correctly.

