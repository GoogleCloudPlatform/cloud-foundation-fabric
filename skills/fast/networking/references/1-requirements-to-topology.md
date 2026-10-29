# Phase 1 & 2 Reference: Requirements Discovery & Unified Topology/IPAM Proposal

This reference governs **Phase 1 (Requirements Discovery)** and **Phase 2 (Topology, IPAM & Plumbing Proposal)**. Rather than asking the user to pick a FAST dataset name upfront—or dumping unrelated questions in static blocks—guide them through a **Conditional Decision DAG** and then present a **single unified Topology + Pre-Filled IPAM Proposal** for confirmation before generating YAML.

---

## 1. Silent Entry Detection (Never Ask a "Mode A/B/C" Question)

Inspect the user's first message and any attached files silently—**never** ask the user a multiple-choice question about "which mode" they want or expose internal labels (`Mode A/B/C`):

- **If the user starts with a general request (no diagram or detailed spec attached):** Start **Turn 1** of the Conditional Interview DAG (Section 2) immediately. You may include a brief one-line note in prose (*"If you have an architecture diagram, IP table, or existing dataset you'd like to adapt, feel free to share it at any point"*), then ask the Turn 1 baseline questions.
- **If the user attaches or points to an architecture diagram (`.png`, `.jpg`, `.svg`, `.pdf`, `.drawio`) or an IP/subnet table / detailed prompt:**
  1. Extract all stated facts (Projects, Single VPC vs. Hub & Spokes, regions, subnet CIDRs, interconnect/VPN links, NVAs, NCC hubs, peerings, DNS zones) and infer the required Stage 2 plumbing (e.g., GKE secondary ranges, `/23` `proxy_only: true` subnets for ALBs, `psa_configs` for Cloud SQL/AlloyDB, `$security_profile_groups:` for Cloud NGFW Enterprise).
  2. Mark **Phase 1** completed and jump straight to **Phase 2 (Unified Topology, IPAM & Plumbing Proposal)** (Section 4), pre-filling sensible defaults for any unspecified CIDRs/ASNs and highlighting only the remaining ambiguities for confirmation.
- **If the user asks to clone & mutate an existing in-tree dataset:** Jump straight to **Phase 2 (Section 4)** showing the proposed delta and IPAM table against `fast/stages/2-networking/datasets/<name>/`.

---

## 2. Phase 1: Conditional Interview DAG (Step-by-Step Discovery)

Follow this conditional flow so you never ask moot questions (such as asking about hubs and spokes when the user selected a Single Shared VPC):

```text
  ┌────────────────────────────────────────────────────────────────────────────┐
  │ Turn 1 (Step 1): Baseline & Primary VPC Footprint Fork                     │
  │ (Ask together ONLY if not already stated in the user's initial prompt)     │
  │  1. Stage 0 Integration (`0-org-setup` outputs vs. Standalone `.tfvars`)   │
  │  2. Concrete Target Region(s) (`1..N` specific regions + shortname keys)   │
  │  3. VPC Footprint Fork:                                                    │
  │     • Path A: Single Shared VPC (1 VPC, microsegmented via FW/Tags/NGFW)   │
  │     • Path B: Multi-VPC Hub & Spokes (Separate VPCs for IAM / quota scale) │
  └───────────────────┬────────────────────────────────────┬───────────────────┘
                      │                                    │
         [Path A: Single Shared VPC]          [Path B: Multi-VPC Hub & Spokes]
         (SKIP all hub/spoke/NCC/peering       ▼
          and transit-NVA questions!)     ┌────────────────────────────────────┐
                      │                   │ Turn 2B (Step 2a): Multi-VPC Scope │
                      │                   │  1. Which spoke environments?      │
                      │                   │  2. Inter-VPC reachability &       │
                      │                   │     transit inspection model?      │
                      │                   └────────────────┬───────────────────┘
                      │                                    │
                      └─────────────────┬──────────────────┘
                                        ▼
  ┌────────────────────────────────────────────────────────────────────────────┐
  │ Turn 2A (if Path A) / Turn 3B (if Path B) (Step 2b):                       │
  │ Connectivity, Security & Workload Plumbing (tailored to Path A or Path B)  │
  │  1. Hybrid Connectivity (None / HA VPN / Cloud Interconnect / Both)        │
  │  2. Internet Egress (Cloud NAT / Air-gapped [or Centralized via NVA])      │
  │  3. Firewall Posture (Cloud-Native L4 Policies vs. Cloud NGFW Enterprise)  │
  │  4. Workload Plumbing (None / GKE / L7 ALB `proxy_only` / PSA / PSC / etc) │
  └────────────────────────────────────┬───────────────────────────────────────┘
                                       ▼
  ┌────────────────────────────────────────────────────────────────────────────┐
  │ Phase 2 (Step 3 — Single Unified Sign-Off Gate):                           │
  │ Present Topology + Pre-Filled Regional IPAM/ASN/DNS Defaults + Output Path │
  │ (User confirms defaults or tweaks CIDRs/names -> Proceed to Phase 3 Gen)   │
  └────────────────────────────────────────────────────────────────────────────┘
```

### Turn 1 (Step 1): Baseline & Primary VPC Footprint Fork
Ask only the following mutually independent questions (skipping any already answered in the user's prompt):

1. **FAST `0-org-setup` Integration vs. Standalone Stage Execution:** Are you running `2-networking` on top of an existing FAST `0-org-setup` deployment, or standalone?
   - *Why this matters:* `2-networking` can create new projects or reuse existing projects in either mode. Knowing if `0-org-setup` is used is strictly for **tfvars, provider, and context plumbing** (whether `0-globals.auto.tfvars.json` and `0-org-setup.auto.tfvars.json` provide `$folder_ids`, `$storage_buckets`, `billing_account`, and `prefix`, or whether those variables must be supplied directly in `2-networking.auto.tfvars`).
2. **Target Regions (`1..N`) & Location Keys:** Which specific GCP region(s) (`1` to `N`) will host your resources?
   - *Important:* Present **concrete** single-region and multi-region choices (e.g., `europe-west1 + europe-west8`, `europe-west8 + europe-west12`, `europe-west8 (single region)`, `europe-west1 (single region)`, `us-central1 + us-east4`, or custom free-text) so you never need a second question to ask *which* region they picked.
   - *Note on `defaults.yaml` location keys:* `primary` and `secondary` in the reference datasets are just arbitrary key names in `context.locations`. A dataset can define `1` to `N` regions using either role names (`primary`, `secondary`) or concise region shortnames (`ew1`, `ew8`, `ew12`, `usc1`). Propose clean shortname keys matching their chosen regions.
3. **Primary VPC Footprint Fork (`Single Shared VPC` vs. `Multi-VPC Hub & Spokes`):**
   - *Framing to include in the question:* In GCP, network microsegmentation and L7 IPS (via Hierarchical/Network Firewall Policies, IAM-governed Secure Tags, and Cloud NGFW Enterprise) work **inside a single Shared VPC**—you do not need multiple VPCs for network security isolation. Multiple VPCs are used to **isolate IAM/administrative blast radii** across host projects (e.g., `dev` vs. `prod`) and to **scale horizontally** across Andromeda quota domains.
   - **Option A — Single Shared VPC:** A single Shared VPC (`main-0` / `shared-0`) hosting all environments/subnets, segmented via subnet IAM, Firewall Policies, Secure Tags, and optional Cloud NGFW Enterprise. *(Ideal for PoCs, simple/compact estates, or low-latency enclaves—no hubs, spokes, NCC, or peering required).*
   - **Option B — Multi-VPC Hub & Spokes:** Separate Shared VPCs per environment (`dev`, `prod`, etc.) interconnected through a central hub (via NCC, 3rd-party NVAs, or Peering).

> **STOP after Turn 1 and wait for the user's answer before asking Turn 2 questions.**

---

### Turn 2 — Path A (`Single Shared VPC` Selected): Single-VPC Plumbing Discovery
When the user selects **Option A (Single Shared VPC)** in Turn 1:
- **Do NOT ask about spoke environments, spoke-to-spoke routing, NCC hubs, VPC peering, or inter-VPC transit NVAs.**
- Ask only the Single-VPC questions below:
  1. **Environment Subnets within the Single VPC:** Do you want a single general-purpose subnet per region, or separate subnets per logical environment (e.g., `dev` and `prod` subnets within the same Shared VPC for subnet-level IAM delegation)?
  2. **Hybrid Connectivity:** Do you need **HA VPN**, **Cloud Interconnect (VLAN attachments)**, both, or **None (Cloud-only)** terminating in this VPC?
  3. **Internet Egress:** Should the VPC egress via **Cloud NAT** (`nat_config`), or have **no internet egress** (Air-gapped / Private Google Access only)?
  4. **Firewall & Inspection Posture:** Are **Cloud-Native L4 Firewalls** (Hierarchical + VPC Firewall Policies) sufficient, or do you also want **Cloud NGFW Enterprise** (L7 IPS / TLS inspection rules via `$security_profile_groups`—or intra-VPC 3rd-party NVA hairpinning via Policy-Based Routing)?
  5. **Workload & Managed Service Plumbing:** Which platforms will run in this VPC so Stage 2 can pre-provision their subnets/ranges? *(Include an explicit **"None (standard VM subnets only)"** option alongside **GKE Clusters** (`pods`/`services` secondary ranges), **Application Load Balancers** (`/23` `proxy_only: true` subnet), **Private Services Access / PSA** (`psa_configs` for Cloud SQL/AlloyDB/Memorystore/NetApp), **Private Service Connect / PSC** (`psc: true` NAT subnets or `psc_addresses`), and **Serverless / Vertex AI** (`/24` Direct VPC Egress / `network_attachments`))*.

---

### Turn 2 — Path B (`Multi-VPC Hub & Spokes` Selected): Inter-VPC & Inspection Discovery
When the user selects **Option B (Multi-VPC Hub & Spokes)** in Turn 1, ask:

1. **Spoke Environments:** Which workload environments need dedicated spoke Shared VPCs? *(Default: `dev` and `prod`; common additions: `nonprod`/`uat`, `dmz`)*.
2. **Inter-VPC Reachability & Transit Inspection Pattern:** How should your spoke VPCs communicate with each other and with shared services/hybrid links?
   - **Option A — Direct Spoke-to-Spoke over NCC (`hub-and-spokes-ncc` with `MESH`, Recommended Cloud-Native Default):** Full line-rate routing across spokes via NCC `MESH`, with microsegmentation enforced by Firewall Policies, Secure Tags, and/or **Cloud NGFW Enterprise**.
   - **Option B — Central Hub Group + Isolated Edge Spokes over NCC (`hub-and-spokes-ncc` with `STAR`):** Shared-service/hub VPCs in the `center` group are reachable by all `edge` spokes (`dev`, `prod`), while `edge` spokes are isolated from each other at the routing table layer (strongly favored over traditional peering for scale and transitive hybrid/PSA/PSC routing).
   - **Option C — Inspected via 3rd-Party Stateful NVA VMs (Palo Alto, Fortinet, Check Point, Linux/FRR):** Spoke-to-spoke and hybrid traffic is hairpinned through multi-NIC NVA VMs.
     - **Always recommend `hub-and-spokes-nva-ncc` (NCC Router Appliance with dynamic BGP) for multi-regional architectures:** It is the **only** pattern that provides automatic cross-region failover via BGP/MED policies *and* allows managed services (such as PSA-peered Cloud SQL, AlloyDB, or NetApp) to use the best available regional route, since managed services do not support network-tagged static routes.
     - Use **`hub-and-spokes-nva` (ILB Sandwich with static routes)** only for single-region deployments or specific point-to-point/DMZ `ILB-as-next-hop` legs where BGP is not used.
   - **Option D — Strictly Isolated Spokes via VPC Peering (`hub-and-spokes-peerings`):** Small static estate (`<= 5` spokes, `$0` hub fee) where `dev` and `prod` peer only with `hub`.
     - *Advisory warning:* Remind the user that **"strict spoke isolation" almost never holds true over time**—scenarios like exchanging anonymized data between `prod` and `dev`, or running shared CI/CD or AI agents that must operate across both environments, will bite them under non-transitive peering.

### Turn 3 — Path B (`Multi-VPC Hub & Spokes`): Hybrid, Egress, Firewall & Workload Plumbing
Once the Multi-VPC pattern is selected in Turn 2B, ask the remaining plumbing questions:
1. **On-Premises / Multicloud Links:** Do you need **HA VPN**, **Cloud Interconnect (VLAN attachments)**, both, or **None (Cloud-only)**?
   - *(If NCC + multiple hybrid links exist: ask whether external sites need to route directly to each other through GCP via `site_to_site_data_transfer: true`).*
2. **Internet Egress Model:** Per-VPC **Cloud NAT** (`nat_config`), centralized egress through the NVA/DMZ VPC, or **no internet egress** (Air-gapped / PGA only)?
3. **Cloud NGFW Enterprise (if Cloud-Native routing was selected in Turn 2B):** Standard L4 Firewall Policies (`goto_next`), or add **Cloud NGFW Enterprise** (`$security_profile_groups` L7 IPS rules)?
4. **Workload & Managed Service Plumbing:** **None (standard subnets only)**, **GKE** (`pods`/`services` secondaries), **L7 ALB** (`/23` `proxy_only: true`), **PSA** (`psa_configs`), **PSC** (`psc: true` / `psc_addresses`), and/or **Serverless / Vertex AI**?

---

## 3. Mapping Requirements to `2-networking` Topologies

```text
  [Primary VPC Footprint Fork: Single VPC or Multi-VPC Hub & Spokes?]
   ├── Single Shared VPC (PoCs, simple estates, or single IAM boundary)
   │    └──> Custom Single-VPC Dataset (1 project + 1 VPC, no NCC/Peering/DNS-peering; derived from peerings dataset)
   │
   └── Multi-VPC Hub & Spokes (Separate host-project IAM boundaries or horizontal quota scale)
        ├── [Do inter-VPC or hybrid flows require 3rd-party multi-NIC NVA VMs as the transit router?]
        │    ├── Multi-region NVA (Recommended Default) ──> datasets/hub-and-spokes-nva-ncc (BGP Router Appliance)
        │    ├── Single-region NVA / Static ILB only ─────> datasets/hub-and-spokes-nva (ILB Sandwich)
        │    └── Hybrid (NCC-RA core + ILB DMZ leg) ──────> datasets/hub-and-spokes-nva-ncc (+ ilb_config on DMZ NIC)
        │
        └── [Cloud-native routing, with L4 Firewall Policies and/or Cloud NGFW Enterprise]
             ├── Recommended Default (Any scale, hybrid/PSA/PSC transitivity) ──> datasets/hub-and-spokes-ncc
             │    ├── Full spoke-to-spoke routing (microsegmented via FW/NGFW) ─> preset_topology: MESH
             │    └── Routing-level isolation between edge spokes via center ───> preset_topology: STAR
             │
             ├── Small static estate (<= 5 spokes, $0 hub fee) ─────────────────> datasets/hub-and-spokes-peerings
             │    (Warn user: strict isolation almost always bites later—e.g. exchanging anonymized prod/dev data or running agents across both envs)
             │
             └── Legacy / Niche (Not recommended for new designs; NCC wins) ────> datasets/hub-and-spokes-vpns
```

### Topology Comparison Matrix

| Topology Pattern & In-Tree Baseline | Core Connectivity & VPC Layout | East-West Behavior | Scale & Quota Envelope | Best Fit & Recommendation Posture | Watch Out For... |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Single Shared VPC** *(Derived by simplifying `hub-and-spokes-peerings` to 1 project + 1 VPC)* | Single Shared VPC (`vpcs/main/` or `vpcs/shared/`) in 1 host project (`projects/net-core-0.yaml`). Zero `ncc-hubs/`, `nvas/`, or `peering_config`. | **Native intra-VPC routing** at full Andromeda line rate; segmented via subnet IAM, Firewall Policies, Secure Tags, and/or Cloud NGFW Enterprise. | Up to **300 subnets** and **100–1,000 service projects** in a single quota domain. | **Ideal for PoCs, simple/compact estates, or low-latency enclaves** where a single network admin team manages the host project. | All environments share a single Shared VPC host project IAM boundary and VPC quota domain; intra-VPC 3rd-party appliance hairpinning requires Policy-Based Routing (`policy_based_routes`). |
| **`hub-and-spokes-ncc`** *(Recommended Multi-VPC Cloud-Native Default)* | Central NCC Hub (`hub.yaml`) connecting `hub-0` (with hybrid VPN/VLAN spokes), `dev-0`, and `prod-0` as VPC spokes. | **Configurable:** Full any-to-any with `preset_topology: MESH`, or isolated edge spokes with `preset_topology: STAR` (`center` vs. `edge` groups). | Scales up to **250 VPC spokes** per hub (`4,000` subnet routes; `1,000` dynamic prefixes/region; `1,000` propagated PSC endpoints). | **Primary recommendation** for multi-VPC cloud-native and Cloud NGFW Enterprise estates; native transitive hybrid routing, PSC propagation (`export_psc: true`), and Producer VPC Spoke support. | `preset_topology` (`MESH` vs. `STAR`) is immutable after hub creation; `auto_accept` project lists on hub groups must not contain duplicates. |
| **`hub-and-spokes-nva-ncc`** *(Recommended Multi-Region NVA Default)* | Dual NCC Hubs (`routing` `MESH` + `transit` `STAR`); multi-region NVAs (`nvas/primary.yaml`, `secondary.yaml`) attached as **NCC Router Appliance** spokes (`ncc_ra_config` + `bgp_config`). | **Inspected:** `dev-0` and `prod-0` attach to `transit` `edge` group; NVAs attach to `transit` `center` and `routing` `default`, inspecting all N-S and E-W flows over dynamic BGP. | Scales to NCC limits (**250 spokes**) with zero static routes and automatic intra-region / cross-region BGP failover. | **Always recommend for multi-region 3rd-party NVA architectures.** Only way to get automatic cross-region failover and let managed services (`PSA`) follow the best available route (since managed services do not support tagged static routes). | Never place workloads in the `transit` VPC (asymmetric return path); every prefix in `advertise` (control plane) must have a matching kernel route in `routes` (data plane). |
| **`hub-and-spokes-nva`** | Multi-NIC NVA (`nvas/main.yaml`) with `ilb_config` attached to `dmz-0`, `hub-0`, `dev-0`, and `prod-0` (spokes peered to `hub-0`). | **Inspected:** Static routes in each VPC steer inter-zone and hybrid traffic to the NVA's per-VPC Internal Passthrough NLB VIP (`$addresses:<vpc>/main`). | Bounded by NVA VM shape bandwidth and VPC peering group limits if spokes peer to a common hub. | Single-region 3rd-party NVA deployments, or specific `ILB-as-next-hop` DMZ/cross-environment legs where dynamic BGP is not used. | Static routes lack regional proximity metrics for multi-region failover; requires symmetric 5-tuple hashing (`PER_CONNECTION`, `session_affinity: NONE`, `NEVER_PERSIST`) and a shared health check. |
| **`hub-and-spokes-peerings`** *(also symlinked as `classic`)* | `hub-0` peered via `peering_config` with `dev-0` and `prod-0` (`export/import_custom_routes: true`). | **Isolated** (VPC Peering is strictly non-transitive). | Small estates (**$\le 5$–$10$ spokes**). Shares peering-group quotas (`subnet_ranges_per_peering_group` = 1,000; `static_routes_per_peering_group` = 300). | Small, cost-sensitive setups (`$0` hub fee). **Caution:** Warn the user that "strict spoke isolation" is almost never true long-term—scenarios like exchanging anonymized data between `prod` and `dev` or running agents that work across both environments will bite them under non-transitive peering. | On-premises routes in `hub-0` cannot transit to PSA (`servicenetworking`) peered to `dev-0`/`prod-0`; Cloud DNS forwarding (`35.199.192.0/19`) cannot hop across peering to a VPN in another VPC. |
| **`hub-and-spokes-vpns`** *(Legacy / Niche)* | `hub-0` connected to `dev-0` and `prod-0` via GCP-to-GCP HA VPN tunnels (`vpcs/<vpc>/vpns/*.yaml`) and Cloud Router BGP. | **Policy-Controlled:** Spokes exchange routes through `hub-0` Cloud Routers, filtered via CEL `route_policies` (`IMPORT`/`EXPORT`). | Up to 5 HA VPN gateways/region/project; bandwidth capped at **1.5–3 Gbps per IPsec tunnel** (`1460` byte MTU). | **Avoid for modern greenfield designs (NCC wins on throughput, cost, and simplicity).** Retain only for legacy brownfield compatibility or hard cross-org IPsec requirements. | IPsec tunnel throughput ceiling and MTU clamping (`1460` / `1406`); VPC firewall rules must allow `icmp` ingress so Path MTU Discovery (`ICMP Type 3 Code 4`) functions. |

---

## 4. Phase 2 (Step 3): Unified Topology, IPAM & Plumbing Proposal Template

Do **not** split Topology Confirmation and IPAM Confirmation into two separate turns. As soon as Phase 1 requirements are gathered (or extracted upfront in Adaptive Mode), present a **single unified proposal** containing both the selected topology and pre-filled default CIDRs/ASNs/DNS domains, and ask the user once to confirm (or specify any custom CIDRs/names/output path) before generating the dataset in Phase 3:

```markdown
### Proposed FAST `2-networking` Topology & IPAM Blueprint

- **Topology Pattern:** [`Single Shared VPC` | `datasets/<chosen-dataset>`]
- **Target Output Directory:** `<proposed-or-user-specified-path>` *(e.g. `./fast-config/2-networking/data/`)*
- **Stage 0 Integration:** [FAST `0-org-setup` (`$folder_ids:networking`) | Standalone `.tfvars`]
- **Regions (`context.locations`):** `<key-1>` = `<region-1>` [, `<key-2>` = `<region-2>`, ...]

#### 1. Proposed Projects, VPCs & Regional IPAM Allocation (Pre-Filled Defaults)
| Project Key (`projects/`) | VPC Key (`vpcs/`) | Region (`$locations:`) | Subnet / Range Name | Proposed CIDR | Purpose & Stage 2 Plumbing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `net-core-0` | `main` (or `hub` / `routing`) | `<key-1>` | `<subnet-name>` | `10.64.0.0/24` | [Primary subnet / HA VPN / Cloud NAT / DNS] |
| *(Additional rows for secondary regions, `proxy_only`, `psc`, `psa_configs`, GKE `pods`/`services`, and spoke VPCs as applicable)* | | | | | |

#### 2. Routing, BGP, DNS & Firewall Summary
- **East-West & Hybrid Routing:** [1–2 bullets including proposed Cloud Router / Peer BGP ASNs if VPN/Interconnect/NCC-RA is used]
- **Cloud DNS & Firewall Posture:** [Proposed private/forwarding/peering DNS domains (`gcp.example.com.`, `onprem.example.com.`), RPZ, and Hierarchical/VPC Firewall rules]
- **Downstream Stage Handoffs (Out of Scope for Stage 2):** [List any requested ALBs, Cloud NGFW Enterprise endpoints/profiles, GKE clusters, or Cloud SQL instances that will consume the Stage 2 plumbing in follow-up stages, or `None`]
```

Ask the user to confirm this unified blueprint (or tell you any CIDRs, ASNs, domain names, or output path they want changed) before executing **Phase 3 (Dataset Generation & Validation)**.
