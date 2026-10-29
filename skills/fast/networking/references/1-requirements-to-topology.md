# Phase 1 & 2 Reference: Requirements-First Discovery & Topology Mapping

This reference governs **Phase 1 (Context & Functional Requirements)** and **Phase 2 (Topology & Mechanism Mapping)**. Rather than asking the user to pick a FAST dataset name upfront, guide them from **architectural requirements** (or an attached diagram) to the right `fast/stages/2-networking` topology.

---

## 1. Step 1: Entry Mode Detection & Upfront Fact Extraction

Inspect the user's first message and any attached files before asking questions:

### Mode A — Guided Consultative Interview (Default)
- **Trigger:** The user asks for help designing or defining a `2-networking` dataset without providing a complete topology or diagram.
- **Action:** Proceed step-by-step through Section 2 below, asking **one question group per turn**. Always offer a recommended FAST default so the user can accept defaults quickly.

### Mode B — Reference Diagram or IP Table Ingestion
- **Trigger:** The user attaches or points to an architecture diagram (`.png`, `.jpg`, `.svg`, `.pdf`, `.drawio`) or an IP/subnet table (Markdown, CSV, YAML).
- **Action:**
  1. Inspect the image or file and extract a structured **Diagram & Inventory Extraction Table**:
     - **Extracted Facts:** Projects, VPCs, regions, subnet CIDRs, interconnect/VPN links, NVA appliances, NCC hubs, VPC peerings, and DNS zones shown in the diagram.
     - **Inferred Stage 2 Plumbing:** Special-purpose subnets or configurations implied by workload icons in the diagram (e.g., an ALB icon implies a regional `proxy_only: true` subnet; a GKE icon implies `pods` and `services` secondary ranges; a Cloud SQL/AlloyDB icon implies either `psa_configs` or a PSC endpoint).
     - **Ambiguities & Missing Parameters:** Diagrams frequently omit how an NVA is wired (ILB sandwich vs. NCC Router Appliance BGP), whether an NCC hub is `MESH` or `STAR`, BGP ASNs, or whether spoke-to-spoke traffic is allowed.
  2. Present this extraction table to the user, mark satisfied steps in Phase 1 and Phase 2 complete, and ask only the clarifying questions needed to resolve the ambiguities.

### Mode C — Clone & Mutate an Existing Dataset
- **Trigger:** The user names an existing dataset (e.g., *"Start from `hub-and-spokes-ncc`, use `us-central1` and `us-east4`, add a `uat` spoke, and drop VLAN attachments"*).
- **Action:** Confirm the requested delta against the named dataset in `fast/stages/2-networking/datasets/<name>/`, skip directly to **Phase 3 (Step 5)** to confirm the IPAM/naming table for the new/modified resources, and proceed to generation.

---

## 2. Step 2: Functional Requirements Discovery (Step-by-Step Interview)

When running the consultative interview, gather requirements across the following **five functional groups**. Ask one group per turn (or combine two closely related groups if the user's initial prompt already partially answered one).

### Group 1: Stage 0 Integration & Target Regions (`1..N`)
*What to ask:*
1. **FAST `0-org-setup` Integration vs. Standalone Stage Execution:** Are you running `2-networking` on top of an existing FAST `0-org-setup` deployment, or standalone?
   - *Why this matters:* `2-networking` can create new projects or reuse existing projects in either mode. Knowing if `0-org-setup` is used is strictly for **tfvars, provider, and context plumbing** (whether `0-globals.auto.tfvars.json` and `0-org-setup.auto.tfvars.json` provide `$folder_ids`, `$storage_buckets`, `billing_account`, and `prefix`, or whether those variables must be supplied directly in `2-networking.auto.tfvars`).
2. **Target Regions (`1..N`) & Location Keys:** How many GCP regions (`1` to `N`) and which specific regions do you plan to use?
   - *Note on `defaults.yaml` location keys:* `primary` and `secondary` in the reference datasets are just arbitrary key names in `context.locations`. A dataset can define `1` to `N` regions using either role names (`primary`, `secondary`) or concise region shortnames (such as `ew1`, `ew8`, `ew12`, `usc1`). Propose clean region shortnames (or `primary`/`secondary` if they prefer) matching the regions the user selects.

### Group 2: VPC Segmentation Drivers & Inter-VPC Reachability
*Important architectural framing to share with the user before asking:*
- **Network microsegmentation does NOT require multiple VPCs in GCP:** Hierarchical/Network Firewall Policies, IAM-governed Secure Tags, and Cloud NGFW Enterprise (L7 IPS) enforce granular microsegmentation within a single Shared VPC. Multiple VPCs are introduced primarily to **isolate IAM/administrative blast radii** (e.g., separate host projects for `dev` vs. `prod`) and to **scale horizontally** across quota domains.

*What to ask:*
1. **VPC & Environment Boundaries:** Which environments or administrative domains need separate Shared VPCs? *(Default: `dev` and `prod`; common additions: `nonprod`/`uat`, `dmz`, or a single consolidated workload VPC)*.
2. **Inter-VPC Reachability Pattern:** How should your spoke VPCs communicate with each other and with shared services?
   - **Option A — Strictly Isolated Spokes (Hub-and-Spoke only):** `dev` and `prod` only reach centralized shared services and on-premises networks in the `hub` VPC, never each other.
     - *Advisory warning:* Remind the user that **"strict spoke isolation" almost never holds true over time**—as soon as they need to exchange anonymized data between `prod` and `dev`, or run shared agents (CI/CD, automation, or AI agents) that must operate across both environments, hard non-transitivity in VPC Peering becomes a painful blocker.
   - **Option B — Direct Spoke-to-Spoke Reachability (Full Mesh):** Workloads across spokes can route directly at line rate (with segmentation enforced by Firewall Policies / Secure Tags / Cloud NGFW Enterprise).
   - **Option C — Central Group vs. Isolated Edge Groups (Star Topology):** Multiple spokes exist where central/shared-service spokes are reachable by all edge spokes, while edge spokes remain isolated from one another at the routing table layer. *(While traditional VPC Peering also isolates spokes, **NCC (`STAR` or `MESH`) is strongly favored** for scale and transitive hybrid/PSA/PSC routing).*
   - **Option D — Inspected East-West Traffic:** Spoke-to-spoke (and/or hybrid) traffic must be inspected at L7—either natively via **Cloud NGFW Enterprise** (transparently on top of NCC/Peering/single-VPC) or by hairpinning traffic through **3rd-party stateful NVA VMs**.

### Group 3: Network Security & Packet Inspection Posture
*Important architectural framing:*
- **Inspection is largely orthogonal to VPC topology:** Cloud-native firewalls, Secure Tags, and Cloud NGFW Enterprise operate transparently inside any VPC or across NCC/Peering without changing routing, and Policy-Based Routing (PBR) can hairpin traffic through an appliance even within a single VPC. Inspection only drives the *inter-VPC topology* when **3rd-party multi-NIC NVA VMs** act as the central transit router between VPCs.

*What to ask:*
- **What level of network firewalling and packet inspection is required?**
  - **Option A — Cloud-Native L4 Firewalls (Default):** Hierarchical Firewall Policies at the folder/org level (`goto_next` delegation) combined with VPC firewall rules. Zero appliance VM cost or latency.
  - **Option B — Cloud NGFW Enterprise (Managed L7 IPS / TLS Inspection):** Cloud-native routing (`ncc` or `peerings`) paired with Google-managed firewall endpoints and `$security_profile_groups` rules in `2-networking` firewall policies (with endpoint/profile provisioning delegated to `0-org-setup` / `2-security`).
  - **Option C — 3rd-Party Stateful NVA VMs (Palo Alto, Fortinet, Check Point, Linux/FRR):** Traffic between trust zones (e.g., Untrusted/DMZ, Hybrid, and Workload Spokes) must traverse multi-NIC NVA VMs.
    - *Follow-up when Option C is chosen (`NCC-RA` vs. `ILB Sandwich`):*
      - **Always recommend `hub-and-spokes-nva-ncc` (NCC Router Appliance with dynamic BGP) for multi-regional architectures.** It is the **only** pattern that provides automatic regional failover via BGP/MED policies *and* allows managed services (such as PSA-peered Cloud SQL, AlloyDB, or NetApp) to use the best available regional route, since managed services do not support network-tagged static routes.
      - Use **`hub-and-spokes-nva` (ILB Sandwich with static routes)** only for single-region deployments or specific point-to-point/DMZ `ILB-as-next-hop` legs where BGP is not used.

### Group 4: Hybrid Connectivity & Internet Egress
*What to ask:*
1. **On-Premises / Multicloud Links:** Do you need **HA VPN**, **Dedicated / Partner Cloud Interconnect (VLAN attachments)**, both, or neither?
   - *If multiple hybrid links exist (e.g., On-Premises + Colocated Partner/Database Interconnect):* Do external sites need to route directly to each other through Google Cloud (`site_to_site_data_transfer: true` on NCC hybrid spokes), or only to GCP VPCs?
2. **Internet Egress Model:** Should spoke VPCs egress directly via per-VPC **Cloud NAT** (`nat_config`), or must internet egress be centralized through an NVA / DMZ VPC (or omitted entirely for air-gapped spokes)?

### Group 5: Workload & Managed Service Plumbing
*What to ask:*
- **Which higher-level GCP platforms will run in these VPCs so `2-networking` can pre-provision their network plumbing?**
  - **GKE Clusters (Standard / Autopilot):** Requires `pods` and `services` secondary CIDR ranges on workload subnets.
  - **Application Load Balancers (Internal L7 ALB / Regional External ALB / Service Extensions):** Requires a regional `proxy_only: true` (`REGIONAL_MANAGED_PROXY`, `/23` recommended) subnet per VPC and region.
  - **Private Service Connect (PSC):**
    - *Publishing services (Producer):* Requires `psc: true` (`PRIVATE_SERVICE_CONNECT`) NAT subnets.
    - *Consuming services (Consumer):* Requires reserved internal IPs (`psc_addresses` in `addresses.yaml`), private DNS zones, and `export_psc: true` on the NCC hub.
  - **Private Services Access (PSA — Cloud SQL, AlloyDB, Memorystore, NetApp Volumes):** Requires `psa_configs` CIDR allocations (`servicenetworking`) on the VPC and custom route export if accessed from on-premises.
  - **Serverless / Vertex AI (Cloud Run Direct VPC Egress, Vertex AI Agent Engine PSC-I):** Requires dedicated `/24` (min `/26`) subnets, optional `network_attachments` in `.config.yaml`, and DNS Response Policy (`*.rep.googleapis.com.`) bypasses.

---

## 3. Step 3: Mapping Requirements to the Canonical `2-networking` Topologies

Use this decision tree and comparison matrix to recommend the exact baseline dataset from `fast/stages/2-networking/datasets/`:

```text
  [Do inter-VPC or hybrid flows require 3rd-party multi-NIC NVA VMs as the transit router?]
   ├── YES ──> [Is the deployment multi-regional or using PSA/managed services across spokes?]
   │            ├── Multi-region (Recommended Default) ──> datasets/hub-and-spokes-nva-ncc (BGP Router Appliance)
   │            ├── Single-region / Static ILB only ─────> datasets/hub-and-spokes-nva (ILB Sandwich)
   │            └── Hybrid (NCC-RA core + ILB DMZ leg) ──> datasets/hub-and-spokes-nva-ncc (+ ilb_config on DMZ NIC)
   │
   └── NO (Cloud-native routing, with L4 Firewall Policies and/or Cloud NGFW Enterprise)
        ├── Recommended Default (Any scale, hybrid/PSA/PSC transitivity) ──> datasets/hub-and-spokes-ncc
        │    ├── Full spoke-to-spoke routing (microsegmented via FW/NGFW) ─> preset_topology: MESH
        │    └── Routing-level isolation between edge spokes via center ───> preset_topology: STAR
        │
        ├── Small static estate (<= 5 spokes, $0 hub fee) ─────────────────> datasets/hub-and-spokes-peerings
        │    (Warn user: strict isolation almost always bites later—e.g. exchanging anonymized prod/dev data or running agents across both envs)
        │
        └── Legacy / Niche (Not recommended for new designs; NCC wins) ────> datasets/hub-and-spokes-vpns
```

### Canonical Topology Comparison Matrix

| In-Tree Dataset (`fast/stages/2-networking/datasets/`) | Core Connectivity & VPC Layout | Spoke-to-Spoke Behavior | Scale & Quota Envelope | Best Fit & Recommendation Posture | Watch Out For... |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`hub-and-spokes-ncc`** *(Recommended Cloud-Native Default)* | Central NCC Hub (`hub.yaml`) connecting `hub-0` (with hybrid VPN/VLAN spokes), `dev-0`, and `prod-0` as VPC spokes. | **Configurable:** Full any-to-any with `preset_topology: MESH`, or isolated edge spokes with `preset_topology: STAR` (`center` vs. `edge` groups). | Scales up to **250 VPC spokes** per hub (`4,000` subnet routes; `1,000` dynamic prefixes/region; `1,000` propagated PSC endpoints). | **Primary recommendation** for cloud-native and Cloud NGFW Enterprise estates; native transitive hybrid routing, PSC propagation (`export_psc: true`), and Producer VPC Spoke support. | `preset_topology` (`MESH` vs. `STAR`) is immutable after hub creation; `auto_accept` project lists on hub groups must not contain duplicates. |
| **`hub-and-spokes-nva-ncc`** *(Recommended Multi-Region NVA Default)* | Dual NCC Hubs (`routing` `MESH` + `transit` `STAR`); multi-region NVAs (`nvas/primary.yaml`, `secondary.yaml`) attached as **NCC Router Appliance** spokes (`ncc_ra_config` + `bgp_config`). | **Inspected:** `dev-0` and `prod-0` attach to `transit` `edge` group; NVAs attach to `transit` `center` and `routing` `default`, inspecting all N-S and E-W flows over dynamic BGP. | Scales to NCC limits (**250 spokes**) with zero static routes and automatic intra-region / cross-region BGP failover. | **Always recommend for multi-region 3rd-party NVA architectures.** Only way to get automatic cross-region failover and let managed services (`PSA`) follow the best available route (since managed services do not support tagged static routes). | Never place workloads in the `transit` VPC (asymmetric return path); every prefix in `advertise` (control plane) must have a matching kernel route in `routes` (data plane). |
| **`hub-and-spokes-nva`** | Multi-NIC NVA (`nvas/main.yaml`) with `ilb_config` attached to `dmz-0`, `hub-0`, `dev-0`, and `prod-0` (spokes peered to `hub-0`). | **Inspected:** Static routes in each VPC steer inter-zone and hybrid traffic to the NVA's per-VPC Internal Passthrough NLB VIP (`$addresses:<vpc>/main`). | Bounded by NVA VM shape bandwidth and VPC peering group limits if spokes peer to a common hub. | Single-region 3rd-party NVA deployments, or specific `ILB-as-next-hop` DMZ/cross-environment legs where dynamic BGP is not used. | Static routes lack regional proximity metrics for multi-region failover; requires symmetric 5-tuple hashing (`PER_CONNECTION`, `session_affinity: NONE`, `NEVER_PERSIST`) and a shared health check. |
| **`hub-and-spokes-peerings`** *(also symlinked as `classic`)* | `hub-0` peered via `peering_config` with `dev-0` and `prod-0` (`export/import_custom_routes: true`). | **Isolated** (VPC Peering is strictly non-transitive). | Small estates (**$\le 5$–$10$ spokes**). Shares peering-group quotas (`subnet_ranges_per_peering_group` = 1,000; `static_routes_per_peering_group` = 300). | Small, cost-sensitive setups (`$0` hub fee). **Caution:** Warn the user that "strict spoke isolation" is almost never true long-term—scenarios like exchanging anonymized data between `prod` and `dev` or running agents that work across both environments will bite them under non-transitive peering. | On-premises routes in `hub-0` cannot transit to PSA (`servicenetworking`) peered to `dev-0`/`prod-0`; Cloud DNS forwarding (`35.199.192.0/19`) cannot hop across peering to a VPN in another VPC. |
| **`hub-and-spokes-vpns`** *(Legacy / Niche)* | `hub-0` connected to `dev-0` and `prod-0` via GCP-to-GCP HA VPN tunnels (`vpcs/<vpc>/vpns/*.yaml`) and Cloud Router BGP. | **Policy-Controlled:** Spokes exchange routes through `hub-0` Cloud Routers, filtered via CEL `route_policies` (`IMPORT`/`EXPORT`). | Up to 5 HA VPN gateways/region/project; bandwidth capped at **1.5–3 Gbps per IPsec tunnel** (`1460` byte MTU). | **Avoid for modern greenfield designs (NCC wins on throughput, cost, and simplicity).** Retain only for legacy brownfield compatibility or hard cross-org IPsec requirements. | IPsec tunnel throughput ceiling and MTU clamping (`1460` / `1406`); VPC firewall rules must allow `icmp` ingress so Path MTU Discovery (`ICMP Type 3 Code 4`) functions. |

---

## 4. Step 4: Normalized Topology & Plumbing Sign-Off Template

Before moving to **Phase 3 (Detailed IPAM & Parameter Confirmation)**, present a concise **Normalized Topology Specification** to the user and ask for confirmation:

```markdown
### Proposed FAST `2-networking` Topology Specification

- **Base Dataset Pattern:** `datasets/<chosen-dataset>`
- **Output Directory:** `<target-custom-dataset-dir>`
- **Stage 0 Integration:** [FAST `0-org-setup` (`$folder_ids:networking`) | Standalone / Reused Projects]
- **Regions (`context.locations`):** `<key-1>` = `<region-1>` [, `<key-2>` = `<region-2>`, ...]

| Project Key (`projects/`) | VPC Key (`vpcs/`) | Role & Topology Attachment | Special Plumbing in `2-networking` |
| :--- | :--- | :--- | :--- |
| `net-core-0` | `hub` (or `routing` + `transit`) | Central Hub / Hybrid Transit / DNS | [HA VPN / VLAN Attachments / NCC Hub / NVA NICs / Cloud DNS Forwarding & RPZ] |
| `net-dev-0` | `dev` | Non-Production Shared VPC Spoke | [Primary subnets, GKE secondaries, `/23` `proxy_only`, `psc`, `psa_configs`, Cloud NAT] |
| `net-prod-0` | `prod` | Production Shared VPC Spoke | [Primary subnets, GKE secondaries, `/23` `proxy_only`, `psc`, `psa_configs`, Cloud NAT] |

- **Routing & Inspection Summary:** [1–2 bullets on how Spoke-to-Spoke, Spoke-to-OnPrem, and Internet Egress traffic flows]
- **Downstream Stage Handoffs (Out of Scope for Stage 2):** [List any requested ALBs, Cloud NGFW Enterprise endpoints/profiles, GKE clusters, or Cloud SQL instances that will consume the Stage 2 plumbing in follow-up stages]
```

Wait for the user to confirm (or adjust) this specification before proceeding to Phase 3.
