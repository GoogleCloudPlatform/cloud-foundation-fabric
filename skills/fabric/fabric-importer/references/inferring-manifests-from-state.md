# Inferring Import Manifests from Terraform State

When migrating or refactoring existing Google Cloud infrastructure managed by Terraform into Cloud Foundation Fabric (CFF), inferring the `import-manifest.yaml` directly from existing Terraform state file(s) (`.tfstate`) is the most precise and deterministic way to define the import boundary.

---

## Why State-Driven Manifest Generation?

| Approach | Strength | Trade-off / Note |
| :--- | :--- | :--- |
| **State-Driven Inference (`manifest_from_state.py`)** | Exactly matches the existing Terraform management footprint. No risk of accidentally pulling unmanaged live assets into the stage scope. | Requires access to state files (`terraform state pull` or GCS bucket access). |
| **Live Asset Survey (`inventory.py survey` + `manifest_init.py`)** | Discovers all live cloud assets, including unmanaged or out-of-band resources. | Broader denominator; requires manually waiving pre-existing or external assets. |

---

## Workflow

### 1. Retrieve the Terraform State(s)

Pull the state files for the target stages or root modules:

```bash
# Example for FAST Stage 0
gsutil cp gs://<iac-core-project>-iac-org-state/default.tfstate stage-0.tfstate

# Or pull via Terraform CLI
terraform -chdir=path/to/stage-0 state pull > stage-0.tfstate
```

For multi-stage environments (e.g., FAST stages 0, 1, 2), you can pull states for all relevant stages:
```bash
terraform -chdir=fast/stages/0-org-setup state pull > stage-0.tfstate
terraform -chdir=fast/stages/1-vpcsc state pull > stage-1.tfstate
terraform -chdir=fast/stages/2-networking state pull > stage-2-networking.tfstate
terraform -chdir=fast/stages/2-security state pull > stage-2-security.tfstate
```

### 2. Generate the Manifest

Run `manifest_from_state.py`:

```bash
uv run scripts/manifest_from_state.py \
  --state stage-0.tfstate \
  --out import-manifest.yaml
```

To synthesize a manifest across multiple stages (note `--force`: the
manifest is human-owned and gate-relevant, so it is never overwritten
silently — use `--out -` to review on stdout first):
```bash
uv run scripts/manifest_from_state.py \
  --state stage-0.tfstate stage-1.tfstate stage-2-networking.tfstate stage-2-security.tfstate \
  --out import-manifest.yaml --force
```

All state files must belong to the same organization: a state spanning
several is refused rather than silently resolved to one of them.

When running on an isolated stage state (e.g. `stage-2-networking.tfstate`) that contains resources across multiple folders without including an organization resource in that state, specify the intended scope root with `--root`:
```bash
uv run scripts/manifest_from_state.py \
  --state stage-2-networking.tfstate \
  --root organizations/123456789012 \
  --out import-manifest.yaml
```

### 3. Review and Collect

Review the generated `import-manifest.yaml`, then collect the live denominator:

```bash
uv run scripts/inventory.py collect --manifest import-manifest.yaml --out inventory.json
```

---

## Type & Level Mapping Reference

The inference script automatically maps Terraform `google_*` resources to CAI asset types and container levels:

| Terraform Resource Type | Manifest `type` | Container Levels | Special Handling |
| :--- | :--- | :--- | :--- |
| `google_organization_iam_*` | `iam` | `[organization]` | Authoritative & additive bindings |
| `google_folder_iam_*` | `iam` | `[folder]` | Folder IAM |
| `google_project_iam_*` | `iam` | `[project]` | Project IAM |
| `google_service_account_iam_*` | `iam.googleapis.com/ServiceAccount` | `[project]` | Emits `iam: true` on SA type |
| `google_org_policy_policy`, `google_organization_policy` | `org-policy` | `[organization, folder, project]` | Inferred from parent attribute |
| `google_organization_iam_custom_role` | `iam.googleapis.com/Role` | `[organization]` | Org custom roles |
| `google_project_iam_custom_role` | `iam.googleapis.com/Role` | `[project]` | Project custom roles |
| `google_logging_organization_sink` | `logging.googleapis.com/LogSink` | `[organization]` | Org log sinks |
| `google_logging_folder_sink` | `logging.googleapis.com/LogSink` | `[folder]` | Folder log sinks |
| `google_logging_project_sink` | `logging.googleapis.com/LogSink` | `[project]` | Project log sinks |
| `google_logging_project_bucket_config`| `logging.googleapis.com/LogBucket` | `[project]` | Project log buckets |
| `google_logging_organization_settings` | `logging.googleapis.com/Settings` | `[organization]` | Logs Router settings singleton (CAI has no `OrganizationSettings` type) |
| `google_logging_folder_settings` | `logging.googleapis.com/Settings` | `[folder]` | Logs Router settings singleton |
| `google_essential_contacts_contact` | `essentialcontacts.googleapis.com/Contact` | inferred from `parent` | Essential contacts |
| `google_storage_bucket_iam_*` | `storage.googleapis.com/Bucket` | `[project]` | Emits `iam: true` on the bucket type |
| `google_tags_tag_value_iam_*` | `cloudresourcemanager.googleapis.com/TagValue` | `[organization]` | Emits `iam: true` on the tag value type |
| `google_folder` | `cloudresourcemanager.googleapis.com/Folder` | `[organization, folder]` | Top-level and nested folders |
| `google_project` | `cloudresourcemanager.googleapis.com/Project` | `[organization, folder]` | Projects |
| `google_storage_bucket` | `storage.googleapis.com/Bucket` | `[project]` | GCS Buckets |
| `google_service_account` | `iam.googleapis.com/ServiceAccount` | `[project]` | Service Accounts |
| `google_tags_tag_key` | `cloudresourcemanager.googleapis.com/TagKey` | `[organization]` | Resource Manager Tag Keys |
| `google_tags_tag_value` | `cloudresourcemanager.googleapis.com/TagValue` | `[organization]` | Tag Values |
| `google_tags_tag_binding` | `cloudresourcemanager.googleapis.com/TagBinding` | `[organization, folder, project]` | Tag Bindings |
| `google_project_service` | `serviceusage.googleapis.com/Service` | `[project]` | Enabled APIs |
| `google_access_context_manager_*` | `identity.accesscontextmanager.googleapis.com/*` | `[organization]` | Access Policies, Perimeters, Levels |
| `google_compute_network` | `compute.googleapis.com/Network` | `[project]` | VPCs |
| `google_compute_subnetwork` | `compute.googleapis.com/Subnetwork` | `[project]` | Subnets |
| `google_compute_global_address` | `compute.googleapis.com/Address` | `[project]` | Global IP Addresses |
| `google_compute_router` | `compute.googleapis.com/Router` | `[project]` | Cloud Routers & NAT |
| `google_compute_firewall` | `compute.googleapis.com/Firewall` | `[project]` | Firewall rules |
| `google_compute_firewall_policy` | `compute.googleapis.com/FirewallPolicy` | `[organization, folder]` | Hierarchical Firewall Policies |
| `google_compute_network_firewall_policy` | `compute.googleapis.com/NetworkFirewallPolicy` | `[project]` | Network Firewall Policies |
| `google_compute_ha_vpn_gateway`, `google_compute_vpn_gateway` | `compute.googleapis.com/VpnGateway` | `[project]` | HA & Classic VPN Gateways |
| `google_compute_external_vpn_gateway` | `compute.googleapis.com/ExternalVpnGateway` | `[project]` | External VPN Gateways |
| `google_compute_vpn_tunnel` | `compute.googleapis.com/VpnTunnel` | `[project]` | VPN Tunnels |
| `google_dns_managed_zone` | `dns.googleapis.com/ManagedZone` | `[project]` | Cloud DNS Zones |
| `google_dns_response_policy` | `dns.googleapis.com/ResponsePolicy` | `[project]` | Cloud DNS Response Policies |
| `google_network_connectivity_hub` | `networkconnectivity.googleapis.com/Hub` | `[project]` | NCC Hubs |
| `google_network_connectivity_spoke` | `networkconnectivity.googleapis.com/Spoke` | `[project]` | NCC Spokes |
| `google_storage_managed_folder` | `storage.googleapis.com/ManagedFolder` | `[project]` | Storage Managed Folders |
| `google_storage_managed_folder_iam_*` | `storage.googleapis.com/ManagedFolder` | `[project]` | Emits `iam: true` on ManagedFolder |
| `google_kms_key_ring` | `cloudkms.googleapis.com/KeyRing` | `[project]` | KMS Key Rings |
| `google_kms_crypto_key` | `cloudkms.googleapis.com/CryptoKey` | `[project]` | KMS Keys |
| `google_bigquery_dataset` | `bigquery.googleapis.com/Dataset` | `[project]` | BigQuery Datasets |
| `google_pubsub_topic` | `pubsub.googleapis.com/Topic` | `[project]` | Pub/Sub Topics |
| `google_pubsub_subscription` | `pubsub.googleapis.com/Subscription` | `[project]` | Pub/Sub Subscriptions |
| `google_secret_manager_secret` | `secretmanager.googleapis.com/Secret` | `[project]` | Secret Manager |
| `google_iam_workload_identity_pool` | `iam.googleapis.com/WorkloadIdentityPool` | `[project]` | WIF Pools |
| `google_iam_workload_identity_pool_provider` | `iam.googleapis.com/WorkloadIdentityPoolProvider` | `[project]` | WIF Identity Providers |

### Types this table does not list

A `google_*` type absent from the table is reported as unmapped, and the
warning is precise about what that means: **this tool has no static
Terraform-to-CAI row for it**. It is not a statement about Cloud Asset
Inventory. Triage each one — CAI may model it (add the type by hand), it
may be leaf IAM on a type CAI models (`iam: true` on the parent), CAI may
genuinely not model it (`enumerate:` block or out-of-band enumeration,
see [cai-blind-spots.md](./cai-blind-spots.md)), or it may be deliberately
out of scope (signed waiver). Anything you resolve is worth sending back
as a `TF_TYPE_MAP` entry.

---

## Multi-Scope Partitioning

When resources span both Organization/Folder governance and project-contained resources, `manifest_from_state.py` produces a multi-scope configuration:

```yaml
scopes:
  - name: org-foundation
    root: organizations/123456789012
    levels: [organization, folder]
    types:
      - type: iam
        levels: [organization, folder, project]
      - type: cloudresourcemanager.googleapis.com/Folder
        levels: [organization, folder]

  - name: stage-projects
    root: organizations/123456789012
    levels: [project]
    include:
      - projects/111111111111   # prj-prod-audit-logs-0
      - projects/222222222222   # prj-prod-iac-core-0
    types:
      - type: iam
        levels: [organization, folder, project]
      - type: iam.googleapis.com/ServiceAccount
        levels: [project]
        iam: true
```

This prevents project-level queries from accidentally scanning every unrelated project in the organization while still managing org-level policies and folders.

Every scope carries its own `types:` list; the generator filters the inferred types per scope (a type whose `levels` cannot fire at a scope's levels is left out, because `inventory.py` refuses dead per-scope declarations) but keeps each entry's full inferred `levels` — the intersection with the scope's `levels` happens at collect time, so the entry reads the same in every scope that carries it. Narrowing a generated list further — dropping a type or a level from one scope but not another — is a normal human refinement of the draft. Regenerating the manifest discards such refinements, so refine after generation, not before.
