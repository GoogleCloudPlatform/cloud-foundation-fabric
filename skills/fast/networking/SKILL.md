---
name: fast-networking
description: Designs, customizes, and validates Cloud Foundation Fabric FAST Stage 2 (2-networking) YAML datasets from user requirements, reference diagrams, or existing topologies. Use when a user asks to design a GCP landing zone network, choose or customize a 2-networking dataset (VPC Peering, NCC, NVA ILB sandwich, NVA NCC Router Appliance, HA VPN), convert a network diagram into FAST YAML, or validate a 2-networking dataset.
---

# FAST `2-networking` Dataset Designer

This skill guides users from functional networking and security requirements—or an attached reference diagram/IP table—to a complete, schema-validated Cloud Foundation Fabric FAST Stage 2 (`fast/stages/2-networking`) YAML dataset in a custom directory.

## Core Principles & Execution Rules

> [!CRITICAL]
> **MANDATORY PROGRESS BLOCK (HUMAN VISIBILITY):**
> Prepend the following progress block to **every** response so the user always sees the current phase and active step:
> ```text
> FAST 2-Networking Designer Progress:
> - Phase 1: Context & Functional Requirements
>   (Step 1/2: Entry Mode & Core Requirements - IN PROGRESS)
> - Phase 2: Topology & Mechanism Mapping
>   (Not started)
> - Phase 3: VPCs, IPAM & Stage Plumbing
>   (Not started)
> - Phase 4: Dataset Generation & Validation
>   (Not started)
> ```

> [!CRITICAL]
> **Understanding Turn Boundaries:**
> - Once you ask the user a question or present a specification for confirmation, **stop execution immediately (do not call more tools)**.
> - Never simulate, guess, or assume the user's answer in the same turn. Wait for the user's next message.
> - Use `ask_user` / `ask_question` whenever available for structured multiple-choice decisions.

1. **Step-by-Step by Default, Adaptive on Rich Input:**
   - **Default Mode (Interactive Interview):** When the user starts with a high-level goal (e.g., *"Help me define my FAST networking dataset"*), execute each phase sequentially, asking **one focused question group per turn** and recommending sensible FAST defaults when the user has no strong preference.
   - **Adaptive Mode (Diagram, IP Table, or Detailed Spec Provided):** When the user provides an architecture diagram (PNG/SVG/PDF/Draw.io), an IP table, or a detailed prompt upfront, extract all stated facts immediately, mark satisfied steps in Phase 1 and Phase 2 as completed, present a **Normalized Topology & Plumbing Summary**, and ask only for missing parameters or ambiguities before generating files.
   - **Zero-Redundancy Rule:** Never ask the user to repeat a region, CIDR, environment name, connectivity choice, or workload type they already provided in their prompt or diagram.

2. **Stage 2 Boundary ("Plumbing vs. Downstream Consumption"):**
   - `fast/stages/2-networking` provisions **foundational network plumbing only**: networking host projects, VPCs, subnets (primary, secondary, `proxy_only`, `psc`, `PRIVATE_NAT`), `psa_configs`, reserved addresses, Cloud Routers, Cloud NAT, VPC Peering, NCC hubs/spokes, HA VPNs, Interconnect VLAN attachments, NVA instances/ILBs/BGP spokes, Cloud DNS zones/response policies, and hierarchical/VPC firewall policies.
   - Higher-level security and application resources—such as **Cloud NGFW Enterprise** (`firewall_endpoint` and `security_profile_group`), **Application Load Balancers** (`net-lb-app-*`), **GKE clusters**, **Cloud SQL / AlloyDB / NetApp instances**, and **PSC Producer `ServiceAttachment`s**—are deployed in **follow-up stages** (`2-security`, `2-project-factory`, or workload stages).
   - Whenever the user requests one of these capabilities, configure the required Stage 2 plumbing (e.g., `/23` `proxy_only: true` subnets, `psc: true` subnets, `psa_configs`, `$security_profile_groups:` rules in `firewall-policies/`) and record the downstream handoff in the generated dataset's `README.md`. Never invent unsupported YAML keys inside `2-networking`.

3. **Custom Dataset Output Target:**
   - Never overwrite the in-tree reference datasets under `fast/stages/2-networking/datasets/` unless explicitly Developing/Updating Fabric itself.
   - Always generate the user's dataset into a dedicated custom directory (e.g., `./fast-config/2-networking/data/` or a user-specified path) along with a ready-to-use `2-networking.auto.tfvars` file that maps `factories_config` to that directory.

4. **Mandatory Mechanical Validation Gate:**
   - Never declare a generated or modified dataset complete until you have run `scripts/validate_dataset.py` against the target directory (checking JSON schemas, `$token` reference integrity, CIDR overlaps, and L400 routing/security guardrails, plus `terraform validate` and `terraform plan` when Terraform is available).

---

## Workflow Map

Before executing a phase, read its corresponding reference document for the decision tables, YAML patterns, and guardrails.

### Phase 1: Context & Functional Requirements
*Description:* Identify how the user is starting (Consultative Interview, Reference Diagram/Doc, or Clone & Mutate) and gather functional requirements across regions, environment isolation, traffic inspection, hybrid connectivity, and workloads.\
*Reference: [Requirements to Topology Mapping](references/1-requirements-to-topology.md)*
- **Step 1:** Entry Mode Detection & Upfront Fact Extraction (Diagram / Prompt / Existing Dataset)
- **Step 2:** Functional Requirements Discovery (Regions, Spoke Isolation, Inspection Mandate, Hybrid Links, Workloads)

### Phase 2: Topology & Mechanism Mapping
*Description:* Map the functional requirements to one of the five canonical `2-networking` reference topologies (or a hybrid variant), define how routing, DNS, and security work in that topology, and align on Stage 2 plumbing vs. downstream stage handoffs.\
*References:*
- *[Requirements to Topology Mapping](references/1-requirements-to-topology.md)*
- *[Routing and Security Mechanisms](references/2-routing-and-security-mechanisms.md)*
- *[Stage Boundaries and Plumbing](references/3-stage-boundaries-and-plumbing.md)*
- **Step 3:** Topology Selection & Trade-off Confirmation (`peerings`, `ncc`, `vpns`, `nva`, `nva-ncc`)
- **Step 4:** Routing, DNS, Firewall & Downstream Plumbing Sign-off

### Phase 3: VPCs, IPAM & Stage Plumbing
*Description:* Finalize concrete names, CIDR allocations, BGP ASNs, NVA sizing/modes, DNS domains, and special-purpose subnets (GKE secondaries, ALB `proxy_only`, PSC NAT, PSA ranges, Private NAT).\
*References:*
- *[Stage Boundaries and Plumbing](references/3-stage-boundaries-and-plumbing.md)*
- *[Dataset Schema and Tokens](references/4-dataset-schema-and-tokens.md)*
- **Step 5:** Project, VPC & Regional IPAM Allocation Table
- **Step 6:** Hybrid BGP / NVA / DNS / Firewall Policy Parameter Confirmation

### Phase 4: Dataset Generation & Validation
*Description:* Clone the closest in-tree reference dataset into the user's custom output directory, apply the customized YAML files and `$token` wiring, run `scripts/validate_dataset.py`, and optionally render topology diagrams with `tools/fast-diagrammer`.\
*Reference: [Dataset Schema and Tokens](references/4-dataset-schema-and-tokens.md)*
- **Step 7:** YAML Dataset & `2-networking.auto.tfvars` Generation
- **Step 8:** Mechanical Validation (`scripts/validate_dataset.py`, including `terraform validate` and `terraform plan`) & Visual Diagram Rendering (`tools/fast-diagrammer`)
- **Step 9:** Dataset `README.md` & Follow-up Stage Handoff Summary
