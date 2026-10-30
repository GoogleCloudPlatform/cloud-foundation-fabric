# Phase 2 & 3 Reference: Dataset Directory Layout, Schemas & `$token` Rules

This reference governs **Phase 2 (Topology, IPAM & Plumbing Proposal)** and **Phase 3 (Dataset Generation & Validation)**. Consult the live JSON schemas in `fast/stages/2-networking/schemas/*.schema.json` alongside this guide when generating or modifying YAML files.

---

## 1. Canonical Dataset Directory Hierarchy & Schema Mapping

Every YAML file in a `2-networking` dataset must sit at one of the canonical factory paths below and begin with a `# yaml-language-server: $schema=...` header pointing to the corresponding schema in `fast/stages/2-networking/schemas/`:

| Dataset-Relative Path | JSON Schema (`fast/stages/2-networking/schemas/`) | Factory & Purpose |
| :--- | :--- | :--- |
| `defaults.yaml` | `defaults.schema.json` | Stage defaults (`vpcs.defaults`, `projects.defaults`), `output_files`, and `context` maps (`locations`, `cidr_ranges`, `cidr_ranges_sets`, `email_addresses`, `iam_principals`, etc.). |
| `folders/**/.config.yaml` | `folder.schema.json` | Optional folder hierarchy definitions (up to 4 levels) under the networking branch. |
| `projects/**/*.yaml` or `folders/**/*.yaml` *(except `.config.yaml`)* | `project.schema.json` | Networking host/transit project definitions (`name`, `parent`, `services`, `shared_vpc_host_config`, `project_reuse`). Projects placed under `folders/<dir>/<proj>.yaml` automatically inherit `parent: $folder_ids:<dir>`. |
| `ncc-hubs/*.yaml` | `ncc-hub.schema.json` | NCC Hub (`name`, `project_id`, `preset_topology: MESH\|STAR`, `export_psc`, `groups`). |
| `nvas/*.yaml` | `nva.schema.json` | Multi-NIC NVA clusters (`auto_instance_config.nics`, `instance_groups`, `ilb_config`, `ncc_ra_config`, `bgp_config`). |
| `firewall-policies/**/*.yaml` | `firewall-policy.schema.json` | Hierarchical Firewall Policies (`parent_id: $folder_ids:<key>`) and Global/Regional Network Firewall Policies (`parent_id: $project_ids:<key>`, `region: global` or `$locations:<key>`, `attachments: { <vpc>: $networks:<vpc> }`). |
| `dns/zones/**/*.yaml` | `dns.schema.json` | Cloud DNS zones (`private`, `forwarding`, `peering`, `public`, `recordsets`, `delegations`). |
| `dns/response-policies/**/*.yaml` | `dns-response-policy-rules.schema.json` | Cloud DNS Response Policy zones and rules (`local_data`, `behavior: bypassResponsePolicy`). |
| `vpcs/<vpc-key>/.config.yaml` | `vpc.schema.json` | VPC configuration (`name`, `project_id`, `mtu`, `routing_mode`, `nat_config`, `ncc_config`, `peering_config`, `psa_configs`, `network_attachments`, `routers`, `routes`, `policy_based_routes`, `dns_policy`, `factories_config`). |
| `vpcs/<vpc-key>/addresses.yaml` | `addresses.schema.json` | Reserved addresses in `<vpc-key>` (`internal`, `external`, `global`, `psc`, `psa`). |
| `vpcs/<vpc-key>/firewall-rules/**/*.yaml` | `firewall-rules.schema.json` | VPC-level `ingress` and `egress` firewall rules. |
| `vpcs/<vpc-key>/subnets/**/*.yaml` | `subnet.schema.json` | Subnet definitions (`name`, `region`, `ip_cidr_range`, `secondary_ip_ranges`, `proxy_only`, `psc`, `private_nat`, `iam`). |
| `vpcs/<vpc-key>/vpns/**/*.yaml` | `vpn.schema.json` | HA VPN gateways (`name`, `region`, `peer_gateways`, `router_config`, `tunnels`, `ncc_spoke_config`). |
| `vpcs/<vpc-key>/vlan-attachments/**/*.yaml` | `vlan-attachments.schema.json` | Dedicated/Partner Interconnect VLAN attachments (`name`, `region`, `peer_asn`, `router_config`, `dedicated_config` / `partner_config`, `ncc_spoke_config`). |
| `vpcs/<vpc-key>/attachment-groups/**/*.yaml` | `attachment-groups.schema.json` | Interconnect attachment groups for SLA redundancy. |

---

## 2. Symbolic Context (`$token`) Namespace & Key Derivation Rules

FAST `2-networking` resolves `$namespace:key` tokens across factories. Never hardcode GCP resource self-links when a context token exists.

### 2.1 Resources Created Inside the Dataset
Pay close attention to whether a token key comes from the **directory/file stem** or the **`name:` attribute** inside the YAML file:

| Token Syntax | Key Derivation Rule | Resolved Value & Where Used |
| :--- | :--- | :--- |
| `$project_ids:<project-key>` | **File stem** of `projects/**/<project-key>.yaml` or `folders/**/<project-key>.yaml` (e.g., `projects/net-core-0.yaml` $\rightarrow$ `$project_ids:net-core-0`). | Project ID. Used in `project_id:` across VPCs, DNS zones, NCC hubs, NVAs, and `ncc-hubs/*.yaml` `auto_accept`. |
| `$folder_ids:<folder-key>` | **Relative directory path** under `folders/` (or passed from Stage 0 `var.folder_ids`, e.g., `$folder_ids:networking`). | Folder ID (`folders/123456`). Used in `projects/*.yaml` `parent:` and `firewall-policies/*.yaml` `parent_id:` / `attachments:`. |
| `$networks:<vpc-key>` | **Directory path** under `vpcs/<vpc-key>/.config.yaml` (e.g., `vpcs/prod/.config.yaml` with `name: prod-0` is referenced as **`$networks:prod`**, NOT `prod-0`). | VPC self-link (or name in VPNs). Used in `peering_config`, `dns/zones/*.yaml` `client_networks` & `peer_network`, `firewall-policies/*.yaml` `attachments`, and `nvas/*.yaml` `nics[].network`, `ilb_config.forwarding_rules[].network`, & `ncc_ra_config.spokes[].network`. |
| `$subnets:<vpc-key>/<region>/<subnet-name>` | `<vpc-key>` (directory under `vpcs/`) + **resolved region name** (e.g. `europe-west1`, NOT the `$locations:` alias) + **`name:` attribute** inside the subnet YAML. *(Resolves regular and `private_nat` subnets only, not `proxy_only` or `psc` subnets).* | Subnet self-link. Used in `addresses.yaml` (`subnetwork` / `subnet_self_link`), `nvas/*.yaml` (`nics[].subnet`), Cloud NAT `subnetworks`, and Cloud Router `interfaces[].subnet`. |
| `$ncc_hubs:<hub-name>` | Required **`name:` attribute** inside `ncc-hubs/<file>.yaml`. | NCC Hub ID. Used in `vpcs/<vpc>/.config.yaml` `ncc_config.hub`, `vpns`/`vlan-attachments` `ncc_spoke_config.hub`, and `nvas/*.yaml` `ncc_ra_config.spokes[].hub`. |
| `$ncc_groups:<hub-name>/<group-key>` | `<hub-name>` (`name:` in `ncc-hubs/*.yaml`) + map key under `groups:` (e.g., `$ncc_groups:hub/default` or `$ncc_groups:transit/center`). | NCC Group ID. Used in `ncc_config.group`, `ncc_spoke_config.group`, and `ncc_ra_config.spokes[].group`. |
| `$routers:<vpc-key>/<router-key>` | `<vpc-key>` (directory under `vpcs/`) + map key under `routers:` in `vpcs/<vpc-key>/.config.yaml`. | Cloud Router name. Used in `vpns/*.yaml` and `vlan-attachments/*.yaml` under `router_config.name` (with `create: false`). |
| `$vpn_gateways:<vpc-key>/<vpn-name>` | `<vpc-key>` + required **`name:` attribute** inside `vpcs/<vpc-key>/vpns/<file>.yaml` (e.g., `vpcs/hub/vpns/onprem.yaml` with `name: to-onprem` $\rightarrow$ `$vpn_gateways:hub/to-onprem`). | HA VPN Gateway ID. Used in `peer_gateways.<key>.gcp` for GCP-to-GCP HA VPNs. |
| `$vlan_attachments:<vpc-key>/<att-name>` | `<vpc-key>` + required **`name:` attribute** inside `vpcs/<vpc-key>/vlan-attachments/<file>.yaml`. | VLAN Attachment ID. Used in `vpcs/<vpc-key>/attachment-groups/*.yaml` `attachments:`. |
| `$attachment_groups:<vpc-key>/<grp-name>` | `<vpc-key>` + required **`name:` attribute** inside `vpcs/<vpc-key>/attachment-groups/<file>.yaml`. | Interconnect Attachment Group ID. Used in `vpcs/<vpc-key>/vlan-attachments/*.yaml` `attachment_group:`. |
| `$addresses:<vpc-key>/<addr-key>` | `<vpc-key>` + map key under `internal:` in `vpcs/<vpc-key>/addresses.yaml` (e.g., `internal: { app-ilb: ... }` in `vpcs/prod/addresses.yaml` $\rightarrow$ **`$addresses:prod/app-ilb`**, with NO `/internal/` segment). | Reserved internal IP address. Used in `vpcs/<vpc-key>/.config.yaml` `routes` (`next_hop`) and `policy_based_routes` (`next_hop_ilb_ip`). |
| `$addresses:<vpc-key>/<nva-name>` | `<vpc-key>` (from `ilb_config.forwarding_rules[].network`) + **`name:` attribute** of the NVA in `nvas/<file>.yaml`. | NVA Internal Passthrough NLB VIP in `<vpc-key>`. Used in `vpcs/<vpc-key>/.config.yaml` `routes` (`next_hop_type: ilb`, `next_hop:`) and `policy_based_routes` (`next_hop_ilb_ip:`). |
| `$nva_instances:<nva-name>-<zone>-<index>` | `<nva-name>` (`name:` in `nvas/*.yaml`) + `<zone>` key in `instance_groups:` + `0`-based instance index (for `auto_create_instances > 0`, e.g., `$nva_instances:primary-b-0`). | NVA VM instance self-link. Used in explicit Cloud Router `peers[].router_appliance_instance` (`vpcs/<vpc>/.config.yaml`) and `ncc_ra_config.spokes[].instances[].vm`. |
| `$nva_addresses:<nva-name>-<zone>-<index>/<vpc-key>` | Instance key (`<nva-name>-<zone>-<index>`) + `<vpc-key>` of the attached NIC (e.g., `$nva_addresses:primary-b-0/routing`). | NVA VM NIC internal IP in `<vpc-key>`. Used in explicit Cloud Router `peers[].address` and `ncc_ra_config.spokes[].instances[].ip`. |

### 2.2 Stage Context & External Variables (`defaults.yaml` & `var.context`)
- **`$locations:<key>`:** Defined under `context.locations` in `defaults.yaml` (e.g., `ew1: europe-west1`, `ew8: europe-west8`). Supported across subnets, routers, Cloud NAT, NVAs, VPNs, VLAN attachments, firewall policies, addresses, routes, and `policy_based_routes`.
- **`$cidr_ranges:<key>` & `$cidr_ranges_sets:<key>`:** Defined under `context.cidr_ranges` and `context.cidr_ranges_sets` in `defaults.yaml`.
  - `$cidr_ranges_sets:<key>` is resolved in **both** `firewall-policies/*.yaml` and VPC `vpcs/<vpc>/firewall-rules/*.yaml`.
  - `$cidr_ranges:<key>` is resolved in `vpcs/<vpc>/.config.yaml` `routes` and `policy_based_routes`, as well as subnet configs and `firewall-rules/*.yaml`.
- **`$custom_roles:<key>`, `$iam_principals:<key>`, `$email_addresses:<key>`, `$kms_keys:<key>`, `$tag_keys:<key>`, `$tag_values:<key>`, `$vpc_sc_perimeters:<key>`:** Defined in `defaults.yaml` `context` (except `folder_ids`, which comes from `var.folder_ids` or `var.context.folder_ids`) or passed from root stage variables (`var.custom_roles`, `var.iam_principals`, `var.service_accounts`, `var.kms_keys`, `var.tag_keys`, `var.tag_values`, `var.perimeters`).
- **`$security_profile_groups:<key>`:** Passed via `var.security_profile_groups` (or `defaults.yaml` `context.security_profile_groups`). Used in `firewall-policies/*.yaml` rules with `action: apply_security_profile_group`.

### 2.3 Common Schema & Factory Gotchas
- **Unique Subnet Filename Stems per VPC (`vpcs/<vpc>/subnets/`):** `modules/net-vpc` keys raw subnet YAML files by `basename(file)` (stripping any `<region>/` subdirectory). Never create two subnet files with the same filename in different regional folders of the same VPC (e.g., `subnets/ew1/default.yaml` and `subnets/ew8/default.yaml` will collide); always include the region or tier in the filename (`subnets/ew1/prod-default-ew1.yaml`).
- **Subnet `secondary_ip_ranges` (`subnet.schema.json`):** Each secondary range entry under `secondary_ip_ranges:` must be an **object** with `ip_cidr_range` (or `reserved_internal_range`), never a bare CIDR string:
  ```yaml
  secondary_ip_ranges:
    pods:
      ip_cidr_range: 10.104.0.0/17
    services:
      ip_cidr_range: 10.108.0.0/21
  ```
- **VPC `network_attachments` (`vpc.schema.json`):** Under `network_attachments.<key>`, `subnet` must be `<resolved-region>/<subnet-name>` (e.g., `europe-west1/prod-psc-int-ew1`), the connection toggle is `automatic_connection: true|false` (not `automatic_accept`), and `producer_accept_lists` / `producer_reject_lists` take literal project IDs (they do not interpolate `$project_ids:`).
- **Disabling VLAN Attachments (`vpcs/<vpc>/.config.yaml`):** To disable loading `vlan-attachments/` for a VPC (such as in the reference datasets), set `factories_config: { vlan_attachments: "none" }` inside `vpcs/<vpc>/.config.yaml`—there is no `vlan_attachments` key under `var.factories_config.paths` in `.tfvars`.
- **Firewall Policies (`firewall-policies/*.yaml`) vs. VPC Firewall Rules (`vpcs/<vpc>/firewall-rules/*.yaml`):**
  - `firewall-policies/*.yaml` (`firewall-policy.schema.json`) uses `ingress_rules` / `egress_rules`, `action: allow|deny|goto_next|apply_security_profile_group`, `match.source_ranges`, `match.destination_ranges`, and `match.layer4_configs: [{ protocol: tcp, ports: ["22"] }]`.
  - `vpcs/<vpc>/firewall-rules/*.yaml` (`firewall-rules.schema.json`) uses `ingress` / `egress` maps where each rule defines top-level `source_ranges` / `destination_ranges`, `rules: [{ protocol: tcp, ports: ["22"] }]` (with `deny: false` for allow or `deny: true` for deny), and `enable_logging: { include_metadata: false }` (an object, not a boolean).

---

## 3. Generating `2-networking.auto.tfvars`

Always generate a companion `2-networking.auto.tfvars` file next to (or pointing to) the custom dataset directory:

### 3.1 When Deployed on Top of FAST `0-org-setup`
`0-globals.auto.tfvars.json` and `0-org-setup.auto.tfvars.json` already supply `billing_account`, `organization`, `prefix`, `folder_ids`, `service_accounts`, and `storage_buckets`. The `.tfvars` file only needs `factories_config`:

```hcl
factories_config = {
  dataset = "/absolute/or/relative/path/to/custom-dataset"
}
```

### 3.2 When Deployed Standalone (Without `0-org-setup`)
Provide the required FAST root variables (`billing_account`, `organization`, `prefix`) and any referenced `$folder_ids` or `$project_ids` (if reusing existing projects). In `defaults.yaml`, either omit `output_files.storage_bucket` (or use `output_files.local_path`) or pass `storage_buckets` in `.tfvars` so `apply` does not attempt to write to an unresolved `$storage_buckets:iac-0/iac-outputs` string:

```hcl
billing_account = {
  id = "012345-6789AB-CDEF01"
}

organization = {
  domain      = "example.com"
  id          = 123456789012
  customer_id = "C01234567"
}

prefix = "myorg"

folder_ids = {
  networking = "folders/1234567890"
}

factories_config = {
  dataset = "/absolute/or/relative/path/to/custom-dataset"
}
```

---

## 4. Phase 3 Execution: Validation & `terraform plan`

After writing the YAML files into the user's custom dataset directory:

1. **Run the Bundled Validator Script (Mandatory Gate):**
   ```bash
   uv run skills/fast/networking/scripts/validate_dataset.py <path/to/custom-dataset>
   ```
   - This script validates:
     1. Every YAML file against its JSON schema in `fast/stages/2-networking/schemas/`.
     2. All `$token` references, strict CIDR syntax (no host bits set), intra-VPC and cross-VPC CIDR overlaps, unique subnet file basenames per VPC, reciprocal VPC peerings, unique firewall rule names per project, and NVA (`ilb_config` / `ncc_ra_config` / BGP / `routes` vs. `advertise`) guardrails.
     3. Isolated `terraform init -backend=false`, `terraform validate`, and `terraform plan -refresh=false` in a temporary directory using synthetic FAST variables.
   - Fix any reported errors or unintended warnings and re-run until `validate_dataset.py` exits with code `0`.

2. **Write `<custom-dataset>/README.md`:**
   Include a concise `README.md` in the custom dataset folder summarizing:
   - Topology overview and regional IPAM & VPC summary table.
   - **Downstream Stage Handoffs** (any requested ALBs, Cloud NGFW Enterprise security profile groups, GKE secondary ranges, PSC service attachments, or PSA databases that follow-up stages will deploy on top of this plumbing).
