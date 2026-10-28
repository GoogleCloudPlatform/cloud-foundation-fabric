# Hub and spoke with NVAs as NCC Router Appliances

This dataset implements a hub-and-spoke topology where Network Virtual Appliances (NVAs) inspect traffic between spoke VPCs, between spokes and on-premises, and toward the internet. Unlike the [ILB sandwich dataset](../hub-and-spokes-nva/README.md), the NVAs attach to two [Network Connectivity Center (NCC)](https://cloud.google.com/network-connectivity/docs/network-connectivity-center) hubs as [Router Appliance spokes](https://cloud.google.com/network-connectivity/docs/network-connectivity-center/concepts/ra-overview) and exchange routes via BGP with regional Cloud Routers, following the [Cross-Cloud Network with NVAs and regional failover using NCC](https://docs.cloud.google.com/architecture/ccn-distributed-apps-design/ccn-ncc-nva) reference architecture.

<p align="center">
  <img src="diagram.png" alt="Hub and spoke with NVAs as NCC Router Appliances">
</p>

## VPC and NCC design

The dataset creates four global-routing VPCs across two regions (`europe-west1` primary, `europe-west8` secondary) connected across two NCC hubs:

- **Routing VPC** (`routing`, project `net-core-0`, `10.64.0.0/24` and `10.64.1.0/24`): hosts the HA VPN to on-premises ([vpcs/routing/vpns/onprem.yaml](./vpcs/routing/vpns/onprem.yaml)), regional Cloud NAT gateways for internet egress, the NVA `nic0` interfaces, and the `ra-*` Cloud Routers. Attached to the **`routing` hub (`MESH`)** ([ncc-hubs/routing.yaml](./ncc-hubs/routing.yaml)) via the HA VPN hybrid spoke and the NVA `nic0` Router Appliance spokes.
- **Transit VPC** (`transit`, project `net-core-0`, `10.64.16.0/24` and `10.64.17.0/24`): hosts the NVA `nic1` interfaces and the transit `ra-*` Cloud Routers. Attached to the **`transit` hub (`STAR`)** ([ncc-hubs/transit.yaml](./ncc-hubs/transit.yaml)) via the NVA `nic1` Router Appliance spokes in the `center` group. Do not host workloads in this VPC (the hub exports `transit` subnets directly to edge spokes, bypassing the NVAs on the forward leg).
- **Workload VPCs** (`prod` in `10.65.x.0/24` and `dev` in `10.66.x.0/24`, each in its own Shared VPC host project): attached to the **`transit` hub (`STAR`)** in the `edge` group (`auto_accept` on `net-prod-0` and `net-dev-0`). Because edge spokes in a star hub only exchange routes with center spokes, all east-west traffic between `prod` and `dev` is forced through an NVA.

## NVA configuration

One NVA is defined per region ([nvas/primary.yaml](./nvas/primary.yaml) and [nvas/secondary.yaml](./nvas/secondary.yaml)), each expanding to two instances (`b` active, `c` standby):

```yaml
auto_instance_config:
  image: projects/cos-cloud/global/images/family/cos-stable
  instance_type: e2-standard-2
  nics:
    - network: $networks:routing
      subnet: $subnets:routing/europe-west1/routing-primary
      masquerade: true
      masquerade_exclude:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
        - 100.64.0.0/10
    - network: $networks:transit
      routes:
        - 10.65.0.0/16
        - 10.66.0.0/16
      advertise:
        - 10.65.0.0/24
        - 10.66.0.0/24
        - 10.65.1.0/24
        - 10.66.1.0/24
      bgp_inbound_deny:
        - 0.0.0.0/0
      subnet: $subnets:transit/europe-west1/transit-primary
instance_groups:
  b:
    auto_create_instances: 1
  c:
    auto_create_instances: 1
ncc_ra_config:
  spokes:
    - network: $networks:routing
      hub: $ncc_hubs:routing
    - network: $networks:transit
      hub: $ncc_hubs:transit
      group: $ncc_groups:transit/center
bgp_config:
  asn: 64513
  keepalive: 3
  holdtime: 9
```

- **`nics` (`routes` vs. `advertise`)**: `nic0` sits in `routing` with `masquerade: true` and `masquerade_exclude` for private ranges so only internet-bound traffic is SNATed (preserving workload source IPs toward on-premises and avoiding NAT state resets during failover). `nic1` sits in `transit` with `bgp_inbound_deny: ["0.0.0.0/0"]` and configures both `routes` and `advertise`, which operate on two distinct planes:
  - **`routes` (data plane / guest Linux kernel FIB)**: installs static kernel routes (`ip route replace <prefix> via <subnet-gateway> dev eth1`) inside the NVA guest OS (used in both ILB and BGP modes) so the Linux kernel knows to forward packets destined to the workload supernets (`10.65.0.0/16`, `10.66.0.0/16`) out `eth1` (`transit`). It does not advertise anything over BGP.
  - **`advertise` (control plane / FRR BGP `network` origination)**: adds `network <prefix>` statements in FRR (used only in BGP mode) so the NVA originates the workload `/24` subnets (`10.65.0.0/24`, `10.66.0.0/24`, `10.65.1.0/24`, `10.66.1.0/24`) toward all its BGP peers on both `routing` and `transit`. Origination is required because edge spokes in the `transit` star hub do not exchange subnet routes directly, and FRR's per-NIC split-horizon filter prevents reflecting routes learned from the `transit` Cloud Router back to `transit`. Because FRR assigns locally originated `network` statements `weight 32768` (beating any eBGP route with `weight 0` received from Cloud Router), FRR never installs a BGP route in the Linux kernel for prefixes in `advertise`—without the static kernel `routes` on `nic1`, the NVA would attract workload traffic via BGP and misroute it out `eth0`'s default route. (`no bgp network import-check` in `frr.conf.tpl` allows `routes` to use aggregated `/16` supernets while `advertise` originates the individual `/24` subnets.)
- **`instance_groups`**: keyed by zone letter; creates instances named `nva-<nva>-<zone>-<index>` and keyed `<nva>-<zone>-<index>` (`primary-b-0`) in `$nva_instances:` and `$nva_addresses:`. Unmanaged instance groups are only created when `ilb_config.forwarding_rules` is non-empty.
- **`ncc_ra_config.spokes`**: creates one Router Appliance spoke per VPC (`ra-<vpc>-<nva>`) with `site_to_site_data_transfer: true` and `include_import_ranges: ["ALL_IPV4_RANGES"]` by default. External appliances can be attached via `instances` (`vm`, `ip`, optional `name`) on an NVA file without `auto_instance_config` or `instance_groups`.
- **`bgp_config`**: deploys Container-Optimized OS with [assets/nva-startup-script-frr.yaml.tpl](../../assets/nva-startup-script-frr.yaml.tpl) running FRR in a container, derives BGP neighbors from the Cloud Router peers targeting the NVA, and renders [assets/frr.conf.tpl](../../assets/frr.conf.tpl) into the `nva-frr-config` metadata key. A background loop polls `nva-frr-config` every 30 seconds and reloads FRR in place (~1 s graceful restart) without recreating the VM.
- **Instance replacement**: GCP blocks deleting a VM referenced by an RA spoke (HTTP 412) or a BGP peer (HTTP 400), so `terraform_data` triggers (`replace_triggered_by`) replace the NVA's spokes and peers whenever an instance is replaced. To avoid dropping both zones' sessions at once during an instance rebuild, define one NVA YAML file per instance (`primary-b.yaml`, `primary-c.yaml`) so each instance owns its own spokes and peers.

## Cloud Router configuration

Router Appliance peering uses `interfaces` and `peers` under `routers` in [vpcs/routing/.config.yaml](./vpcs/routing/.config.yaml) and [vpcs/transit/.config.yaml](./vpcs/transit/.config.yaml):

```yaml
routers:
  ra-primary:
    region: $locations:primary
    asn: 64512
    custom_advertise:
      all_subnets: true
      ip_ranges:
        "0.0.0.0/0": default
    interfaces:
      intf-0:
        subnet: $subnets:routing/europe-west1/routing-primary
        ip_address: 10.64.0.252
      intf-1:
        subnet: $subnets:routing/europe-west1/routing-primary
        ip_address: 10.64.0.253
        redundant_interface: intf-0
    route_policies:
      import-b:
        type: IMPORT
        terms:
          - priority: 10
            match:
              expression: "destination.inAnyRange([prefix('10.65.0.0/24').orLonger(), prefix('10.66.0.0/24').orLonger()])"
            actions:
              - expression: med.set(100)
              - expression: accept()
          - priority: 20
            match:
              expression: "destination.inAnyRange(prefix('0.0.0.0/0').orLonger())"
            actions:
              - expression: med.set(10100)
              - expression: accept()
      import-c:
        # same terms with 150 and 10150
    peers:
      primary-b-0:
        interface: intf-0
        asn: 64513
        address: $nva_addresses:primary-b-0/routing
        router_appliance_instance: $nva_instances:primary-b-0
        import_policies:
          - import-b
      primary-b-1:
        interface: intf-1
        # same peer on the redundant interface
      primary-c-0:
        # standby instance, import-c
      primary-c-1:
```

- **Interfaces** require two redundant IPs per router (`redundant_interface: intf-0`) specified as literals so the NVA factory can render them into `nva-frr-config` metadata without a dependency cycle.
- **Peers** take the same attributes as VPN/VLAN BGP peers (`asn`, `route_priority`, `custom_advertise`, `custom_learned_ip_ranges`, `md5_authentication_key`, `enable`, `import_policies`, `export_policies`) and either point to an explicit instance (`address` + `router_appliance_instance`) for per-instance policies or set `nva: <key>` to fan out across all spoke instances with a shared policy.

## Routing, flow symmetry and BGP design

### Asymmetric routing hazards: active/passive vs. active/active (ECMP)

Because an NVA bridges separate VPC routing tables (`routing` on `nic0` and `transit` on `nic1`) across global-routing VPCs, the forward and return legs of a flow are routed independently by the ingress and egress VPCs. Stateful NVA functions—such as stateful firewall inspection, Linux `conntrack`, or SNAT (`masquerade`)—drop or reset flows whenever the return leg hits a different NVA instance than the forward leg without shared session state. Two independent sources of asymmetric routing must be addressed:

1. **Intra-region asymmetry across instances (active/passive vs. active/active session sync)**:
   - **Active/passive (default in this dataset, no session sync required)**: each NVA instance has explicit BGP peers (`address` + `router_appliance_instance`) attached to a per-instance Cloud Router `IMPORT` route policy that sets a distinct base MED (`import-b` sets `offset = 100` for the active zone `b` instance; `import-c` sets `offset = 150` for the standby zone `c` instance). Every Cloud Router strictly prefers the `b` instance in both directions and only fails over to `c` when `b`'s BGP session goes down, guaranteeing per-instance symmetry without cross-instance state synchronization.
   - **Active/active ECMP (requires stateless inspection or session sync)**: to distribute traffic across up to 8 instances per Router Appliance spoke, replace the explicit per-instance peers with a fan-out peer (`nva: primary`) referencing a single shared import policy (`offset = 100`). Cloud Router then installs equal-cost multipath (ECMP) routes across all healthy instances in the regional cluster. Because independent VPC routing tables hash forward and return legs separately across the `N` instances (`1/N` chance of hitting the same instance in both directions), active/active ECMP is only viable when the NVA performs stateless forwarding/filtering or runs active-active HA session and NAT state synchronization across instances.
2. **Inter-region asymmetry across global VPCs**:
   - Even with active/passive (`b` vs. `c`) inside each region, if every regional Cloud Router naively assigned `MED = 100` to all prefixes learned from its local NVA, `GLOBAL` VPC routing would create cross-region asymmetry:
     - **North-south (`routing` ↔ workload spoke)**: traffic entering `routing` in `europe-west1` (e.g. from the HA VPN) for an `europe-west8` workload (`10.65.1.0/24`) would cross `primary-b-0` in `europe-west1` (`100` local vs. `100 + ~215 = 315` remote), while the reply from `europe-west8` (`0.0.0.0/0` / on-premises) would cross `secondary-b-0` in `europe-west8`.
     - **Inter-region east-west (region 1 spoke ↔ region 2 spoke)**: a VM in `europe-west1` (`10.65.0.0/24`) sending to `europe-west8` (`10.66.1.0/24`) would egress via `primary-b-0` (`100` local in `ew1`), while the reply from `europe-west8` to `europe-west1` would egress via `secondary-b-0` (`100` local in `ew8`).

### Path selection with Cloud Router import policies

All NVAs share ASN `64513` (providing automatic BGP AS-path loop prevention between regions) and keep FRR MED-neutral (`attribute-unchanged med`, plus `disable-connected-check` for GCE `/32` guest interfaces). Every NVA originates all workload prefixes (`advertise` on `nic1`), giving every `routing` and `transit` Cloud Router a BGP candidate route per workload prefix to rank via `IMPORT` route policies.

Cloud Router converts the imported MED into the dynamic route priority and adds an inter-region cost when a route is used from another region (measured at `215` between `europe-west1` and `europe-west8`). Using per-instance offsets (`offset = 100` on `import-b` for zone `b`, `offset = 150` on `import-c` for zone `c`, or a single `offset = 100` in ECMP mode) and `prefix('...').orLonger()` match expressions, the import policies eliminate both intra-region and inter-region asymmetry:

| Router | Prefixes | MED | Effect |
|---|---|---|---|
| Routing side, any region | Workload prefixes of the router's own region | `offset` (`100` / `150`) | Local appliances preferred for north-south traffic to local workloads |
| Routing side, any region | Anything else | `10000 + offset` (`10100` / `10150`) | Remote workloads reached via their own region's appliances (`offset + 215 = 315` beats `10100`); local appliances act as cross-region fallback |
| Transit side, region ranked `r` | Workload prefixes of regions ranked above `r` | `10000 + offset` (`10100` / `10150`) | Inter-region east-west traffic uses the higher-ranked region's appliances in both directions (`315` beats `10100`), crossing regions once per leg |
| Transit side, any region | Anything else (`0.0.0.0/0`, on-premises, own and lower-ranked workloads) | `offset` (`100` / `150`) | Local appliances preferred for same-region east-west, north-south egress and internet egress |

In this dataset `europe-west1` is ranked first (rank 1) and `europe-west8` second (rank 2), so `ra-primary` on `transit` needs only the catch-all term (`offset`), whereas `ra-secondary` on `transit` demotes `europe-west1`'s workload prefixes (`10.65.0.0/24`, `10.66.0.0/24`) to `10000 + offset`. This guarantees that every flow—same-region east-west, cross-region east-west, and north-south—traverses the same active `b` appliance in both directions, fails over to the local `c` standby (`150`) if `b` goes down, and fails over symmetrically to the surviving region (`10000 + offset`) if an entire regional NVA pair is lost.

### BGP timers

BFD is not supported on Router Appliance BGP sessions, and Cloud Router's own keepalive minimum is 20 s (60 s hold). However, Cloud Router honors a lower hold time proposed by the peer in BGP `OPEN` (`timers bgp 3 9`), reducing silent-failure detection from 51–53 s to 8–11 s (graceful FRR stops withdraw routes in ~0.5–2.3 s).

## Firewall, VPN and DNS

- **Firewall**: alongside the [hierarchical firewall policy](./firewall-policies/networking-policy.yaml), [routing](./vpcs/routing/firewall-rules/default-ingress.yaml) and [transit](./vpcs/transit/firewall-rules/default-ingress.yaml) VPC rules allow TCP 179 from the four Cloud Router interface `/32` addresses and RFC 1918 forwarded traffic. Rule names are suffixed per VPC (`-routing`, `-transit`) because both VPCs share `net-core-0`.
- **VPN and DNS**: the HA VPN in `routing` ([vpcs/routing/vpns/onprem.yaml](./vpcs/routing/vpns/onprem.yaml)) attaches to the `routing` mesh hub as a hybrid spoke, and `net-core-0` hosts centralized Cloud DNS (top-level private zone, on-premises forwarding zone, and Private Google Access response policy) peered to the workload spokes.

<p align="center">
  <img src="diagram-dns.png" alt="Cloud DNS architecture overlay">
</p>

## Tradeoffs compared to the ILB sandwich

| | ILB sandwich ([hub-and-spokes-nva](../hub-and-spokes-nva/README.md)) | NCC Router Appliance (this dataset) |
|---|---|---|
| Next hop & hybrid | Static routes per spoke to ILB VIPs; manual custom route advertisements to on-premises | Dynamic routes via NCC; workload prefixes propagate to on-premises automatically via the `routing` mesh hub |
| Flow symmetry | Relies on symmetric hashing and `NEVER_PERSIST` / `PER_CONNECTION` conntrack across independent ILBs | Enforced by Cloud Router import policies across same-region, cross-region and north-south flows |
| Failure detection | Health check probes (seconds), independent per forwarding rule | BGP hold time: ~1 s graceful stop, 8–11 s silent failure with 3/9 timers (51–53 s with 20/60), no BFD |
| Scaling & updates | Active/active across all healthy instances; seamless instance replacement; startup script edits recreate VMs | Active/standby (or ECMP up to 8 instances); instance replacement recreates the NVA's spokes/peers; BGP config reloads in place via metadata |
