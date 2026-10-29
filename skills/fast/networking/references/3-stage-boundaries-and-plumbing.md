# Phase 2 Reference: Stage 2 Boundaries & Downstream Plumbing Contract

`fast/stages/2-networking` is a **foundational network plumbing stage**. It creates the projects, VPCs, subnets, IP reservations, routers, interconnects/VPNs, NCC hubs/spokes, base NVAs, DNS zones, and firewall policies that downstream stages consume.

When a user states a requirement for a security capability, load balancer, container platform, or managed database, **never** invent unsupported YAML keys inside `2-networking` and **never** tell the user FAST cannot support it. Instead:
1. Configure the **Stage 2 network plumbing** required by that service in the YAML dataset.
2. Explain what is delegated to the **follow-up stage** (`0-org-setup`, `1-vpcsc`, `2-security`, `2-project-factory`, or workload stages).
3. Document every delegated item in the generated dataset's `README.md` under a **Downstream Stage Handoffs** section.

---

## 1. Stage Boundary Principle & Representative Plumbing Matrix

**General Boundary Principle:** Any GCP service or security capability whose data-plane or control-plane depends on shared VPC primitives (subnets, secondary ranges, special-purpose subnets, IP reservations, PSA peerings, PSC network attachments, routes, DNS zones/RPZ, or firewall policy rules) has those **foundational network primitives provisioned in `2-networking`** (per `fast/stages/2-networking/schemas/*.schema.json`), while the **service, endpoint, or workload resource itself is provisioned in a follow-up stage**.

The table below shows representative examples of how common capabilities split across `2-networking` and downstream stages:

| Requested Capability | What `2-networking` Provisions (Stage 2 YAML Plumbing) | What is Delegated to Other Stages (Out of Scope for `2-networking`) |
| :--- | :--- | :--- |
| **Cloud NGFW Enterprise** *(L7 IPS, Threat Prevention, TLS Inspection)* | • Hierarchical or network firewall policy rules in `firewall-policies/*.yaml` setting `action: apply_security_profile_group` and `security_profile_group: $security_profile_groups:<key>`.<br/>• Context mapping via `var.security_profile_groups` in `.tfvars`. | • `google_network_security_firewall_endpoint`, `firewall_endpoint_association`, and `security_profile_group` resources (provisioned in **`0-org-setup` / `2-security`** or a dedicated security stack). |
| **Application Load Balancers** *(Internal L7 ALB, Regional External ALB, Service Extensions)* | • Regional proxy-only subnets (`vpcs/<vpc>/subnets/<region>/<name>.yaml` with `proxy_only: true`, `/23` recommended, `/24` minimum per region/VPC).<br/>• Static VIP reservations in `vpcs/<vpc>/addresses.yaml` (`internal`, `external`, or `global`).<br/>• Firewall rules allowing health-check probers (`$cidr_ranges_sets:healthchecks`: `35.191.0.0/16`, `130.211.0.0/22`) and proxy subnet CIDRs. | • Load balancer forwarding rules, target HTTP(S) proxies, URL maps, backend services, NEGs, and Cloud Armor policies (`modules/net-lb-app-*`, deployed in **workload stages**). |
| **Internal Passthrough NLBs** *(Application-Tier L4 ILBs)* | • Workload subnets (`vpcs/<vpc>/subnets/<region>/*.yaml`).<br/>• Static internal VIP reservations in `vpcs/<vpc>/addresses.yaml` (`internal:`).<br/>• Health-check allow rules (`35.191.0.0/16`, `130.211.0.0/22`). | • Application-tier `modules/net-lb-int` resources (deployed in **workload stages**). *(Note: NVA transit ILBs ARE managed directly by `2-networking` via `nvas/*.yaml` `ilb_config`).* |
| **GKE Clusters** *(Standard & Autopilot)* | • Shared VPC host enablement (`shared_vpc_host_config.enabled: true`) and `container.googleapis.com` API in `projects/net-*.yaml`.<br/>• Primary node subnets with `secondary_ip_ranges` (`pods` and `services`) in `vpcs/<vpc>/subnets/<region>/*.yaml`.<br/>• Optional firewall rules for private control-plane webhooks/master CIDRs. | • Service project creation and Shared VPC subnet-level IAM attachment (`roles/compute.networkUser`, `roles/container.hostServiceAgentUser` in **`2-project-factory`**).<br/>• GKE cluster & nodepool provisioning (`modules/gke-*` in **workload stages**). |
| **Private Service Connect (PSC) — Producer** *(Publishing Services Across VPCs/Orgs)* | • Dedicated PSC NAT subnets (`vpcs/<vpc>/subnets/<region>/<name>.yaml` with `psc: true`, `/24` recommended per service attachment).<br/>• Regional `proxy_only: true` subnet if the published producer LB is an Internal Regional ALB. | • Producer load balancer and `google_compute_service_attachment` (`modules/net-lb-*` in **producer workload stages**). |
| **Private Service Connect (PSC) — Consumer** *(Consuming SaaS, Managed DBs, or Google APIs)* | • Consumer PSC endpoint IPs in `vpcs/<vpc>/addresses.yaml` (`psc_addresses` for service attachments or Google API bundles `all-apis` / `vpc-sc`).<br/>• Private Cloud DNS zones/records in `dns/zones/` or RPZ rules in `dns/response-policies/`.<br/>• `export_psc: true` on `ncc-hubs/*.yaml` to propagate consumer endpoints across NCC spokes. | • Producer-side project allowlisting (`consumer_accept_lists`) if the producer is external. |
| **Private Services Access (PSA)** *(Cloud SQL, AlloyDB, Memorystore, NetApp Volumes)* | • `servicenetworking.googleapis.com` API in `projects/net-*.yaml`.<br/>• `psa_configs` in `vpcs/<vpc>/.config.yaml` (allocating `/24`–`/16` internal CIDR ranges, `export_routes: true`, `import_routes: true`).<br/>• Cloud Router `custom_advertise.ip_ranges` if on-premises networks need to reach the PSA ranges.<br/>• Note: If multiple NCC spokes need transitive access to a PSA peering (`servicenetworking-googleapis-com` or `sn-netapp-prod`), document attaching an **NCC Producer VPC Spoke** (`linked_producer_vpc_network`) or using PSC endpoints instead. | • Managed database or storage instances (`modules/cloudsql-*`, `alloydb`, `netapp-volumes` in **workload stages**). |
| **Serverless & Vertex AI Runtimes** *(Cloud Run Direct VPC Egress, Vertex AI Agent Engine PSC-I)* | • Dedicated subnets (`>= /26`, `/24` recommended to account for `2x` rollout IP reservation) in `vpcs/<vpc>/subnets/<region>/*.yaml`.<br/>• `network_attachments` in `vpcs/<vpc>/.config.yaml` for PSC Interfaces (`PSC-I`).<br/>• Cloud DNS RPZ bypass (`*.rep.googleapis.com.` `bypassResponsePolicy`) and ensuring `googleapis.com.` is **not** in `dns/zones/` as a DNS Peering zone on VPCs using `PSC-I`. | • Service project attachment in **`2-project-factory`**.<br/>• Cloud Run services, Vertex AI endpoints, and Agent Engine deployments in **workload stages**. |
| **VPC Service Controls (VPC-SC)** *(Data Exfiltration Perimeters)* | • Plumbing for `restricted.googleapis.com` (`199.36.153.4/30`) routes and DNS response policies (`dns/response-policies/*.yaml`).<br/>• Optional `perimeters` variable mapping on networking host projects. | • Access Context Manager policies, access levels, and regular/bridge service perimeters (managed in **`1-vpcsc`**). |

---

## 2. Example YAML Plumbing Snippets for `2-networking`

The snippets below are **illustrative examples** showing how Stage 2 plumbing is expressed against the `fast/stages/2-networking/schemas/*.schema.json` schemas. Adapt names, keys, regions, and CIDRs to the user's design, and consult the JSON schemas in `fast/stages/2-networking/schemas/` for the full set of supported attributes.

### 2.1 Regional ALB Proxy-Only & PSC Producer Subnets (`vpcs/<vpc>/subnets/<region>/*.yaml`)
```yaml
# vpcs/prod/subnets/europe-west1/prod-proxy-ew1.yaml
# yaml-language-server: $schema=../../../../../schemas/subnet.schema.json

name: prod-proxy-ew1
region: $locations:ew1
ip_cidr_range: 10.100.128.0/23
description: Regional Managed Proxy subnet for Internal and Regional External ALBs
proxy_only: true
active: true
```

```yaml
# vpcs/prod/subnets/europe-west1/prod-psc-nat-ew1.yaml
# yaml-language-server: $schema=../../../../../schemas/subnet.schema.json

name: prod-psc-nat-ew1
region: $locations:ew1
ip_cidr_range: 10.100.130.0/24
description: PSC NAT subnet for publishing Service Attachments
psc: true
```

### 2.2 GKE Node Subnet with Pod & Service Secondaries (`vpcs/<vpc>/subnets/<region>/*.yaml`)
```yaml
# vpcs/prod/subnets/europe-west1/prod-gke-ew1.yaml
# yaml-language-server: $schema=../../../../../schemas/subnet.schema.json

name: prod-gke-ew1
region: $locations:ew1
ip_cidr_range: 10.100.0.0/22
description: Primary subnet for GKE nodes with secondary Pod and Service ranges
secondary_ip_ranges:
  pods:
    ip_cidr_range: 10.104.0.0/17
  services:
    ip_cidr_range: 10.108.0.0/21
```

### 2.3 PSA Ranges & PSC Interfaces (`network_attachments`) in `vpcs/<vpc>/.config.yaml`
```yaml
# Inside vpcs/prod/.config.yaml
psa_configs:
  - ranges:
      cloudsql-psa: 10.110.0.0/20
    export_routes: true
    import_routes: true

network_attachments:
  agent-engine-ew1:
    subnet: prod-psc-int-ew1
    automatic_accept: false
    producer_accept_lists:
      - $project_ids:ai-workload-0
```

### 2.4 Reserved VIPs & PSC Consumer Endpoints (`vpcs/<vpc>/addresses.yaml`)
```yaml
# vpcs/prod/addresses.yaml
# yaml-language-server: $schema=../../../schemas/addresses.schema.json

internal:
  app-ilb-ew1:
    region: $locations:ew1
    subnetwork: $subnets:prod/europe-west1/prod-default-ew1
    address: 10.100.1.10

psc_addresses:
  alloydb-psc-ew1:
    region: $locations:ew1
    subnetwork: $subnets:prod/europe-west1/prod-default-ew1
    address: 10.100.1.50
    service_attachment: projects/producer-prj/regions/europe-west1/serviceAttachments/alloydb-sa
```

### 2.5 Cloud NGFW Enterprise Rule in `firewall-policies/*.yaml`
```yaml
# Inside firewall-policies/networking-policy.yaml
ingress_rules:
  inspect-east-west:
    priority: 1000
    action: apply_security_profile_group
    security_profile_group: $security_profile_groups:ips-profile-group
    description: Delegate L7 IPS inspection to Cloud NGFW Enterprise
    match:
      source_ranges:
        - $cidr_ranges_sets:rfc1918
      destination_ranges:
        - $cidr_ranges_sets:rfc1918
      layer4_configs:
        - protocol: all
```

---

## 3. Handoff Outputs Contract for Downstream Stages

When `2-networking` runs `terraform apply`, it emits stage outputs (`host_project_ids`, `vpc_self_links`, `subnet_self_links`, `subnet_proxy_only_self_links`, `subnet_psc_self_links`, and `2-networking.auto.tfvars.json`) consumed by `2-project-factory` and workload stages.

Always include a **Downstream Stage Handoffs** table in the generated dataset's `README.md` listing:
1. Which **Shared VPC Host Projects** (`$project_ids:<key>`) and **Subnets** (`<vpc>/<region>/<subnet>`) downstream service projects should attach to in `2-project-factory`.
2. Which **`proxy_only`**, **`psc`**, **`psa_configs`**, or **`network_attachments`** resources were pre-created in `2-networking` and which workload stage / CFF module (`gke-cluster-*`, `net-lb-app-*`, `cloudsql-*`) will consume them.
3. Any external context variables (`var.security_profile_groups`, `var.folder_ids`, `var.kms_keys`) that must be passed into `2-networking.auto.tfvars` when running `terraform apply`.
