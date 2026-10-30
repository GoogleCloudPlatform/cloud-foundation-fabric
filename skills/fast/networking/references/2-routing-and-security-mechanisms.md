# Phase 2 Reference: Routing and Security Mechanisms Across Topologies

This reference governs **Phase 2 (Topology, IPAM & Plumbing Proposal)**. Once the baseline topology is selected in `1-requirements-to-topology.md`, use this guide to explain and configure how North-South, East-West, Hybrid, Egress, DNS, and Inspection mechanisms work in YAML.

---

## 1. Cross-Topology Mechanism Matrix

| Mechanism | `Single Shared VPC` *(Simple / PoC / Single-IAM)* | `hub-and-spokes-ncc` *(Multi-VPC Cloud-Native Default)* | `hub-and-spokes-nva-ncc` *(Multi-Region NVA Default)* | `hub-and-spokes-nva` *(Single-Region ILB Sandwich)* | `hub-and-spokes-peerings` *(Small Static Estate)* | `hub-and-spokes-vpns` *(Legacy / Niche)* |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Spoke-to-Hub Routing** | N/A (single VPC `vpcs/main/`; no hub or peering needed). | `ncc_config` on hub & spokes (`hub: $ncc_hubs:hub`). | Dual NCC hubs (`routing` `MESH` + `transit` `STAR`); spokes attach to `transit` `edge` group. | Direct multi-NIC NVA attachment across `dmz`, `hub`, `dev`, `prod` + static routes to `$addresses:<vpc>/main` (no VPC peering). | Reciprocal `peering_config` on both hub & spoke (`routes_config.export/import: true`, enabled by default). | `vpcs/<vpc>/vpns/*.yaml` with reciprocal `$vpn_gateways:` + BGP. |
| **East-West / Spoke Routing** | **Native intra-VPC routing**; isolated via Firewall Policies, Secure Tags, or Cloud NGFW. | **Direct** (`MESH` preset) or **Blocked at routing layer** (`STAR` `edge` group). | **Inspected via NVA:** Spokes in `transit/edge` route through NVAs in `transit/center` via BGP origination (`advertise` + `routes`). | **Inspected via NVA:** Spoke static routes point inter-spoke prefixes to the local spoke ILB VIP (`$addresses:<spoke>/main`). | **Blocked by design** (VPC Peering is strictly non-transitive). | Filtered via Cloud Router BGP `route_policies` (`IMPORT`/`EXPORT`) in `hub`. |
| **On-Prem Hybrid Transit** | Terminates directly in `main` (`vpcs/main/vpns/` or `vlan-attachments/`); zero transitivity hops. | Terminates in `hub`; `ncc_spoke_config` on VPN/VLAN attaches tunnels/VLANs as NCC hybrid spokes. | Terminates in `routing` VPC on `routing` `MESH` hub; NVA inspects between `routing` and `transit` hubs. | Terminates in `dmz` or `hub` VPC; static routes steer traffic through NVA ILBs to spokes. | Terminates in `hub`; spokes import custom routes via peering (`routes_config.import: true`). | Terminates in `hub`; re-advertised to spokes over inter-VPC BGP. |
| **Internet Egress** | `nat_config` (Cloud NAT) and PGA on `main`. | Per-VPC `nat_config` (Cloud NAT) and Private Google Access (`PGA`). | Per-VPC `nat_config` or centralized `0.0.0.0/0` originated on `routing` CR $\rightarrow$ NVA (`masquerade_exclude`) $\rightarrow$ Cloud NAT. | Per-VPC `nat_config` or centralized default route via NVA to `dmz`/`untrusted` NIC (`masquerade: true`) + Cloud NAT. | Per-VPC `nat_config` (Cloud NAT) and PGA. | Per-VPC `nat_config` or default route over hub VPN. |
| **Firewall & Inspection** | Hierarchical policy (`goto_next`) + VPC rules + Secure Tags (+ optional Cloud NGFW or PBR). | Hierarchical policy (`goto_next`) + VPC firewall rules (+ optional Cloud NGFW `$security_profile_groups`). | Stateful 3rd-party NVA inspection via BGP RA spokes (active-passive MED or active-active ECMP) + VPC/Hierarchical rules. | Stateful 3rd-party NVA inspection via ILB next-hop (`PER_CONNECTION`, `NONE` affinity, `NEVER_PERSIST`) + VPC/Hierarchical rules. | Hierarchical policy (`goto_next`) + VPC firewall rules (+ optional Cloud NGFW `$security_profile_groups`). | Hierarchical policy + VPC firewall rules + BGP prefix filtering. |
| **Cloud DNS Pattern** | All `private` and `forwarding` zones bind directly to `client_networks: [$networks:main]` (no DNS peering needed). | Per-spoke private zones bound to spoke + `hub`; `hub` hosts on-prem forwarding; spokes peer `.` to `hub` + RPZ. | Per-spoke private zones bound to spoke + `routing`; `routing` hosts on-prem forwarding; `transit` & spokes peer `.` to `routing` + RPZ. | Per-spoke private zones bound to spoke + `hub`; `dmz` & spokes peer `.` to `hub`. | Per-spoke private zones bound to spoke + `hub`; `hub` hosts on-prem forwarding; spokes peer `.` to `hub`. | Per-spoke private zones bound to spoke + `hub`; spokes peer `.` to `hub`. |

---

## 2. Cloud-Native Routing Mechanics (`single-vpc`, `ncc` & `peerings`)

### 2.0 Single Shared VPC (`single-vpc`)
- **Dataset Structure:** Derived by simplifying `hub-and-spokes-peerings` to a single host project (`projects/net-core-0.yaml` with `shared_vpc_host_config.enabled: true`) and a single VPC (`vpcs/main/.config.yaml`). Omit `ncc-hubs/`, `nvas/`, `peering_config`, and `ncc_config`.
- **Environment Segmentation without Multiple VPCs:**
  - Create either general-purpose regional subnets or per-environment regional subnets (e.g., `vpcs/main/subnets/dev-ew8.yaml`, `prod-ew8.yaml`) inside `vpcs/main/subnets/`, delegating subnet-level `roles/compute.networkUser` IAM to downstream service projects.
  - Enforce East-West isolation between environments or tiers using Hierarchical/VPC Firewall Policies, IAM-governed Secure Tags (`$tag_values:`), and optional Cloud NGFW Enterprise (`$security_profile_groups:`).
- **Direct Hybrid, PSA & DNS Simplicity:**
  - HA VPNs (`vpcs/main/vpns/`), VLAN attachments (`vpcs/main/vlan-attachments/`), and Private Services Access (`psa_configs`) all attach directly to `main`, eliminating inter-VPC transitivity constraints.
  - All Cloud DNS `private` and `forwarding` zones in `dns/zones/` bind directly to `client_networks: [$networks:main]`, and `dns/response-policies/*.yaml` lists only `networks: [$networks:main]`—do **not** create a `peer-root.yaml` DNS peering zone in a Single VPC dataset.

### 2.1 Network Connectivity Center (`hub-and-spokes-ncc`)
- **`MESH` vs. `STAR` Preset Topology (`ncc-hubs/<hub>.yaml`):**
  - `preset_topology: MESH` (default) places all spokes in `groups.default`, enabling direct line-rate routing between every spoke (microsegmented via Firewall Policies, Secure Tags, or Cloud NGFW Enterprise).
  - `preset_topology: STAR` creates two groups (`center` and `edge`). Attach shared-service/transit VPCs to `$ncc_groups:<hub>/center` and workload environment VPCs (`dev`, `prod`) to `$ncc_groups:<hub>/edge` when you want routing-table isolation between workload spokes while sharing central services.
  - *Constraint:* `preset_topology` is immutable after hub creation.
- **PSC Propagation:** `export_psc` defaults to `true` in `factory-ncc.tf` so Private Service Connect consumer endpoints created in one spoke (such as `hub`) are automatically reachable from all connected VPC spokes.
- **NCC Hybrid Spokes (`vpns/*.yaml` & `vlan-attachments/*.yaml`):**
  - Adding `ncc_spoke_config: { hub: $ncc_hubs:hub }` to a VPN or VLAN attachment file registers it as an NCC hybrid spoke (`factory-ncc.tf` automatically configures `include_import_ranges = ["ALL_IPV4_RANGES"]` so Cloud Routers import dynamic routes from the hub and advertise spoke subnets back to on-premises peers).
  - **`site_to_site_data_transfer` (`true` default vs. `false`):** In `factory-ncc.tf`, `vpn.schema.json`, and `vlan-attachments.schema.json`, `site_to_site_data_transfer` **defaults to `true`**, allowing two hybrid spokes attached to the hub (for example, an On-Premises VPN/Interconnect and a colocated Partner Interconnect) to exchange routes and traffic directly through Google Cloud. Explicitly set `site_to_site_data_transfer: false` when external sites only communicate with GCP VPCs or when deploying in a GCP region that does not support NCC site-to-site data transfer.

### 2.2 VPC Network Peering (`hub-and-spokes-peerings`)
- **Reciprocal Declaration:** Peering must be declared in **both** VPCs' `.config.yaml` files (`hub` $\rightarrow$ `prod` and `prod` $\rightarrow$ `hub`).
- **Custom Route Exchange:** `factory-peering.tf` defaults `routes_config.export` and `routes_config.import` to `true` so spokes automatically import on-premises prefixes learned by `hub` over VPN/Interconnect.
- **Non-Transitivity Traps:**
  1. Workloads in `dev` cannot reach `prod` over `hub` (and if they later need to exchange anonymized data or run shared agents across both environments, peering cannot route it without an intermediate proxy/NVA or migrating to NCC).
  2. On-premises networks terminating in `hub` cannot reach Private Services Access (`psa_configs` / `servicenetworking`) peered to `dev` or `prod`.
  3. Cloud DNS outbound forwarding packets (`35.199.192.0/19`) cannot traverse a VPC peering link to reach a VPN/Interconnect in another VPC—always host the forwarding zone in the VPC that terminates the hybrid link (and use DNS peering from spokes).

---

## 3. 3rd-Party NVA Routing & Failover Mechanics (`nva-ncc` vs. `nva`)

### 3.1 Multi-Region NVA via NCC Router Appliance (`hub-and-spokes-nva-ncc`)
Whenever 3rd-party stateful NVA VMs are used in a **multi-regional architecture** (or alongside PSA managed services), recommend `hub-and-spokes-nva-ncc`:

```text
  [On-Prem VPN/VLAN] ──> ( routing VPC ) <──BGP── [ NVA nic0 ]
                              │                       │ (Stateful Inspection)
                        (routing MESH hub)            ▼
                                                [ NVA nic1 ] ──BGP──> ( transit VPC )
                                                                            │
                                                                 (transit STAR hub: center)
                                                                            │
                                                                 (transit STAR hub: edge)
                                                                      ├── ( dev VPC )
                                                                      └── ( prod VPC )
```

1. **Dual-Hub Architecture:**
   - **`routing` Hub (`MESH`):** Connects hybrid spokes (HA VPN / VLAN attachments in the `routing` VPC) and `nic0` of each regional NVA as a Router Appliance spoke.
   - **`transit` Hub (`STAR`):** Connects `nic1` of each regional NVA to the `center` group (`$ncc_groups:transit/center`) and workload spoke VPCs (`dev`, `prod`) to the `edge` group (`$ncc_groups:transit/edge`).
   - *Critical Rule:* **Never host workloads in the `transit` VPC.** The `transit` VPC is the routing VPC for the `transit` RA spokes and learns spoke subnet routes directly from the hub; a VM inside `transit` would send traffic to a spoke via the NVA, while return traffic from the spoke would bypass the NVA and go directly to the `transit` subnet (asymmetric drop).
2. **`routes` (Data Plane) vs. `advertise` (Control Plane) in `nvas/*.yaml`:**
   - `routes` installs static Linux kernel routes inside the NVA guest OS via that NIC's subnet gateway so the OS knows which interface forwards to a prefix.
   - `advertise` originates prefixes in FRR via BGP `network` statements toward Cloud Router peers (used on `nic1` in `transit` so edge spokes—which do not exchange subnet routes with each other in a `STAR` hub—learn routes to other spokes through the NVA).
   - *Invariant:* Because FRR prefers its own locally originated `network` statement (`weight 32768`) over eBGP routes learned from Cloud Router (`weight 0`), **every prefix listed in `advertise` must be covered by a kernel route in `routes`** (or the default route on a `masquerade` NIC), otherwise the NVA kernel will lack a forwarding entry and blackhole the traffic.
3. **Active-Passive (No Session Sync) vs. Active-Active ECMP:**
   - **Active-Passive + Regional Affinity (Default in `hub-and-spokes-nva-ncc`):** Configure explicit per-instance BGP peers on the Cloud Routers using `$nva_addresses:<nva>-<zone>-<index>/<vpc>` and `$nva_instances:<nva>-<zone>-<index>`, attaching distinct `IMPORT` route policies (`med.set(100)` for primary zone `b`, `med.set(150)` for standby zone `c`, and `med.set(10100)` / `10150` for remote-region prefixes). This guarantees symmetric forward and return paths through the same regional primary NVA without requiring cross-instance state synchronization, while failing over automatically within the region or across regions if an appliance or region fails.
   - **Active-Active ECMP:** Configure a fan-out peer (`nva: <nva-key>`) on the Cloud Router interfaces sharing a single import policy. Both zonal instances advertise at equal MED; use only when the NVA performs stateless inspection or runs active-active state synchronization (e.g., FGSP) and SNAT is excluded for private ranges (`masquerade_exclude`).
4. **Why `NCC-RA` Wins for Managed Services (`PSA`):**
   - Managed service producer networks (`servicenetworking` for Cloud SQL, AlloyDB, Memorystore, NetApp) do not have GCE network tags and cannot use network-tagged static routes. Because `NCC-RA` injects dynamic BGP routes into the VPC route table with regional MED priorities, PSA-peered services automatically use the local region's healthy NVA and fail over to the secondary region dynamically.

### 3.2 Single-Region ILB Sandwich (`hub-and-spokes-nva`) & Hybrid `NCC-RA` + `ILB` Chaining
- **When to use `ilb_config`:** Single-region NVA deployments (`hub-and-spokes-nva`, where `dmz`, `hub`, `dev`, and `prod` are all attached directly to the NVA's 4 NICs without VPC Peering), or when attaching a 3rd NIC (`nic2`) of an `NCC-RA` NVA to a dedicated DMZ or cross-environment bridge VPC using Internal Passthrough NLB next-hop static routes (`$addresses:<vpc>/<nva-name>`).
- **Mandatory Conntrack & Health Check Guardrails:**
  - The stage's `factory-nva.tf` configures a single shared health check and defaults `ilb_config.connection_tracking` to `track_per_session: false` (`PER_CONNECTION` 5-tuple tracking) and `persist_conn_on_unhealthy: NEVER_PERSIST` (with `session_affinity: NONE` and 600s idle timeout). Never override `ilb_config.connection_tracking` with `track_per_session: true` (`PER_SESSION` 2-tuple hashing causes asymmetric forward/return selection across NVA instances during health flaps).
- **Intra-VPC Hairpinning with Policy-Based Routing (PBR):**
  - If traffic *within* a single VPC (or entering a VPC from a specific source CIDR) must be forced through an NVA ILB, configure `policy_based_routes` in `vpcs/<vpc>/.config.yaml` pointing `next_hop_ilb_ip` to `$addresses:<vpc>/<nva-name>`.
  - *PBR Guardrail:* Always include a higher-priority (lower numeric `priority` value) rule with `use_default_routing: true` matching Private Service Connect / Google API ranges first so wildcard PBR (`0.0.0.0/0`) does not hijack local PSC/PGA traffic into the NVA.

---

## 4. Firewall Policies & Cloud NGFW Enterprise

1. **Hierarchical & Network Firewall Policies (`firewall-policies/*.yaml`):**
   - Both Hierarchical Firewall Policies (`parent_id: $folder_ids:<key>` or `organizations/<id>`) and Network Firewall Policies (`parent_id: $project_ids:<key>` with `region: global` or `$locations:<key>`) are defined in `firewall-policies/*.yaml` with an `attachments:` map inside the policy YAML file.
   - Rules in `modules/net-firewall-policy` default to `action: allow` (ingress) or `action: deny` (egress) if `action` is omitted; always set `action: goto_next` explicitly on rules that should delegate evaluation to lower-level policies or VPC rules.
   - Supports symbolic CIDR sets (`$cidr_ranges_sets:healthchecks`, `$cidr_ranges_sets:rfc1918`) defined in `defaults.yaml`.
2. **VPC Firewall Rules (`vpcs/<vpc>/firewall-rules/*.yaml`):**
   - **Rule Key Uniqueness per Project:** GCE firewall rule names are project-scoped. If two VPCs share the same `project_id` (for example, `routing` and `transit` both living in `$project_ids:net-core-0`), their firewall rule keys across `vpcs/routing/firewall-rules/` and `vpcs/transit/firewall-rules/` **must be distinct** (e.g., `allow-routing-ssh` vs. `allow-transit-ssh`) to avoid HTTP 409 conflicts.
   - **ICMP for PMTUD on VPN VPCs:** Any VPC terminating or transiting HA VPN tunnels must allow `icmp` ingress (especially `ICMP Type 3 Code 4` Fragmentation Needed) so Path MTU Discovery adjusts TCP MSS for in-flight connections across the `1406`/`1460`-byte IPsec tunnel MTU.
3. **Cloud NGFW Enterprise Integration (L7 IPS / TLS Inspection):**
   - In `firewall-policies/*.yaml`, rules can set `action: apply_security_profile_group` and `security_profile_group: $security_profile_groups:<key>` (where `var.security_profile_groups` is passed from a `2-networking-ngfw` or security stage).

---

## 5. Cloud DNS & Name Resolution Mechanics

1. **Private & Hybrid DNS Topologies (`dns/zones/`):**
   There are three main patterns for structuring private and forwarding zones across hub and spoke VPCs:
   - **Pattern A — Per-Environment Zones Bound to Hub + Root Peering (Recommended Default, used in the FAST reference datasets):**
     1. Each environment manages its own private zone in its own spoke project (e.g., `dns/zones/net-dev-0/pvt-dev.yaml` with `project_id: $project_ids:net-dev-0`) and uses **cross-project VPC binding** (`private.client_networks: [$networks:hub, $networks:dev]`) to bind the zone to both the spoke VPC and the centralized hub VPC (`hub` or `routing`).
     2. The centralized hub VPC—which **must** be the VPC where hybrid VPN/Interconnect connectivity terminates so Cloud DNS forwarding packets (`35.199.192.0/19`) have a direct path to on-premises resolvers—hosts the on-premises forwarding zone (`forwarding.client_networks: [$networks:hub]`) and top-level shared private zones.
     3. All spoke VPCs attach to a root peering zone (`domain: .`, `peering.peer_network: $networks:hub`, `client_networks: [$networks:dev, $networks:prod]`)—or, alternatively, bind the forwarding zone directly across VPCs when routing allows. Root peering to the centralized VPC is **preferred** because spokes automatically resolve on-premises domains and all environment zones bound to the hub.
   - **Pattern B — Fully Centralized Zones + Root Peering:**
     - All private zones and on-premises forwarding zones are defined centrally in `net-core-0` and bound to the centralized hub VPC (`$networks:hub` or `$networks:routing`), while every spoke VPC peers root (`domain: .`) to the centralized VPC.
   - **Pattern C — Cross-Project Bindings Only (`client_networks`):**
     - Private zones (defined either centrally in `net-core-0` or per spoke project) are bound directly to all consumer VPCs via `private.client_networks: [$networks:hub, $networks:dev, $networks:prod]` (requires cross-project IAM permissions, which Stage 2 manages when all projects are in the dataset).
2. **Cloud DNS Response Policies (`dns/response-policies/*.yaml`):**
   - Used to steer Google APIs (`*.googleapis.com.`, `*.gcr.io.`, `*.pkg.dev.`) to `private.googleapis.com.` (`199.36.153.8/30`), `restricted.googleapis.com.` (`199.36.153.4/30`), or a custom PSC Google API endpoint IP.
   - **Regional Endpoint (`*.rep.googleapis.com.`) Bypass:** Cloud DNS Response Policies match by **most-specific DNS suffix** (there is no `priority` attribute in `dns-response-policy-rules.schema.json`). When workloads use GCP Regional Endpoints (`<service>.<region>.rep.googleapis.com.`), include a rule for `dns_name: "*.rep.googleapis.com."` with `behavior: bypassResponsePolicy`—because `*.rep.googleapis.com.` is more specific than `*.googleapis.com.`, it automatically bypasses the wildcard CNAME override so regional TLS certificate validation succeeds.
   - **PSC Interfaces (`PSC-I`) & Root / `googleapis.com.` Peering:** If a spoke VPC uses PSC Interfaces (`network_attachments` for Vertex AI Agent Engine with VPC-scoped DNS), note that DNS Peering takes precedence over local private zones; avoid peering `googleapis.com.` (or use Pattern C cross-project bindings + RPZ on that spoke) so local PSC-I resolution is not overridden.
