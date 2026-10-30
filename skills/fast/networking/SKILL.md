---
name: fast-networking
description: Designs, customizes, and validates Cloud Foundation Fabric FAST Stage 2 (2-networking) YAML datasets from user requirements, reference diagrams, or existing topologies. Use when a user asks to design a GCP landing zone network, choose or customize a 2-networking dataset (Single Shared VPC, NCC, NVA NCC Router Appliance, NVA ILB sandwich, VPC Peering, HA VPN), convert a network diagram into FAST YAML, or validate a 2-networking dataset.
---

# FAST `2-networking` Dataset Designer

This skill guides users from functional networking and security requirements—or an attached reference diagram/IP table—to a complete, schema-validated Cloud Foundation Fabric FAST Stage 2 (`fast/stages/2-networking`) YAML dataset in a custom directory.

## Core Principles & Execution Rules

> [!IMPORTANT]
> **MANDATORY PROGRESS BLOCK (HUMAN VISIBILITY):**
> For all design and customization tasks, prepend the following 3-phase progress block to **every** response so the user always sees the current phase and active step (if the user only asks to validate an existing dataset on disk, run `scripts/validate_dataset.py` directly and report the results):
> ```text
> FAST 2-Networking Designer Progress:
> - Phase 1: Requirements Discovery
>   (Step 1/2: Baseline & VPC Footprint - IN PROGRESS)
> - Phase 2: Topology, IPAM & Plumbing Proposal
>   (Not started)
> - Phase 3: Dataset Generation & Validation
>   (Not started)
> ```

> [!IMPORTANT]
> **Understanding Turn Boundaries & Conditional Questioning (`ask_user` / `ask_question` / `question`):**
> - Once you ask the user a question or present a specification for confirmation, **stop execution immediately (do not call more tools)**.
> - Never simulate, guess, or assume the user's answer in the same turn. Wait for the user's next message.
> - **NEVER ask a meta-question about how the user wants to start:** Never ask whether the user wants an interview vs. diagram import vs. cloning a dataset. If the user did not attach a diagram or name an existing dataset in their prompt, start **Turn 1** of the interview immediately (you may mention in one line of prose that they can share a diagram or dataset name at any time).
> - **NEVER bundle dependent questions in the same turn or question tool call:** Only mutually **independent** questions may be asked together. You **MUST** resolve whether the user wants a **Single Shared VPC** vs. **Multi-VPC Hub & Spokes** *before* asking any questions about spoke-to-spoke routing, NCC hubs, peering, or inter-VPC transit NVAs.
> - **Concrete Options Only:** Every multiple-choice option must be self-contained and actionable. Never offer a vague option like *"Single region (e.g., europe-west8 or europe-west1)"* that forces an extra follow-up turn just to ask *which* single region they meant; list the specific common region choices directly and allow custom free-text input.

1. **Step-by-Step by Default, Adaptive on Rich Input:**
   - **Default Mode (Conditional Interview DAG):** When the user starts with a general request (e.g., *"Help me define my FAST networking dataset"*), follow the Conditional Interview DAG in `references/1-requirements-to-topology.md`, asking only the questions that apply to the user's chosen branch (`2` turns for Single Shared VPC; `3` turns for Multi-VPC Hub & Spokes) and recommending sensible FAST defaults.
   - **Adaptive Mode (Diagram, IP Table, or Detailed Spec Provided):** When the user provides an architecture diagram (PNG/SVG/PDF/Draw.io), an IP table, or a detailed prompt upfront, extract all stated facts immediately, mark **Phase 1** completed, jump straight to **Phase 2 (Topology, IPAM & Plumbing Proposal)** with pre-filled defaults for any unspecified CIDRs/ASNs, and ask for a single sign-off before generating files.
   - **Validation-Only Mode:** When the user points to an existing dataset directory and asks to validate or test it, run `uv run skills/fast/networking/scripts/validate_dataset.py <path>` directly and report the findings.
   - **Zero-Redundancy Rule:** Never ask the user to repeat a region, CIDR, environment name, connectivity choice, or workload type they already provided in their prompt or diagram.

2. **Stage 2 Boundary ("Plumbing vs. Downstream Consumption"):**
   - `fast/stages/2-networking` provisions **foundational network plumbing only**: networking host projects, VPCs, subnets (primary, secondary, `proxy_only`, `psc`, `private_nat`), `psa_configs`, reserved addresses, Cloud Routers, Cloud NAT, VPC Peering, NCC hubs/spokes, HA VPNs, Interconnect VLAN attachments, NVA instances/ILBs/BGP spokes, Cloud DNS zones/response policies, and hierarchical/network/VPC firewall policies.
   - Higher-level security and application resources—such as **Cloud NGFW Enterprise** (`firewall_endpoint` and `security_profile_group`, typically managed in a `2-networking-ngfw` or security stage), **Application Load Balancers** (`net-lb-app-*`), **GKE clusters**, **Cloud SQL / AlloyDB / NetApp instances**, and **PSC Producer `ServiceAttachment`s**—are deployed in **follow-up stages** (`2-project-factory` or workload/security stages).
   - Whenever the user requests one of these capabilities, configure the required Stage 2 plumbing (e.g., `/23` `proxy_only: true` subnets, `psc: true` subnets, `psa_configs`, `$security_profile_groups:` rules in `firewall-policies/`) and record the downstream handoff in the generated dataset's `README.md`. Never invent unsupported YAML keys inside `2-networking`.

3. **Custom Dataset Output Target:**
   - Never overwrite the in-tree reference datasets under `fast/stages/2-networking/datasets/` unless explicitly developing/updating Fabric itself.
   - Always generate the user's dataset into a dedicated custom directory (e.g., `./fast-config/2-networking/data/` or a user-specified path) along with a ready-to-use `2-networking.auto.tfvars` file that maps `factories_config` to that directory.

4. **Mandatory Mechanical Validation Gate:**
   - Never declare a generated or modified dataset complete until you have run `scripts/validate_dataset.py` against the target directory (checking JSON schemas, `$token` reference integrity, intra-VPC and cross-VPC CIDR overlaps, and routing/security guardrails, plus `terraform validate` and `terraform plan` when Terraform is available).

---

## Workflow Map

Before executing a phase, read its corresponding reference document for the decision tables, YAML patterns, and guardrails.

### Phase 1: Requirements Discovery
*Description:* Walk the Conditional Interview DAG (or extract facts from an attached diagram/prompt), forking cleanly between **Single Shared VPC** and **Multi-VPC Hub & Spokes**.\
*Reference: [Requirements to Topology Mapping](references/1-requirements-to-topology.md)*
- **Step 1:** Stage 0 Integration, Concrete Target Regions & Primary VPC Footprint Fork (`Single Shared VPC` vs. `Multi-VPC Hub & Spokes`)
- **Step 2:** Branch-Specific Requirements Discovery (`Step 2` Single-VPC Plumbing on Path A; `Step 2a` Spoke Scope/Inspection + `Step 2b` Hybrid/Egress/Plumbing on Path B)

### Phase 2: Topology, IPAM & Plumbing Proposal (Single Sign-Off Gate)
*Description:* Map the functional requirements to a **Single Shared VPC** layout or one of the canonical `2-networking` hub-and-spoke topologies (`ncc`, `nva-ncc`, `nva`, `peerings`, `vpns`), pre-fill sensible non-overlapping default CIDRs, BGP ASNs, DNS zones, and Stage 2 plumbing in a single unified blueprint table, and ask the user once to confirm (or tweak) the proposal and output directory.\
*References:*
- *[Requirements to Topology Mapping](references/1-requirements-to-topology.md)*
- *[Routing and Security Mechanisms](references/2-routing-and-security-mechanisms.md)*
- *[Stage Boundaries and Plumbing](references/3-stage-boundaries-and-plumbing.md)*
- *[Dataset Schema and Tokens](references/4-dataset-schema-and-tokens.md)*
- **Step 3:** Unified Topology, Pre-Filled Regional IPAM/BGP/DNS Defaults, Output Path & Downstream Handoff Sign-Off

### Phase 3: Dataset Generation & Validation
*Description:* Generate the YAML dataset and `2-networking.auto.tfvars` in the user's custom output directory, run `scripts/validate_dataset.py` (`terraform validate` and `terraform plan`), and write the dataset `README.md`.\
*Reference: [Dataset Schema and Tokens](references/4-dataset-schema-and-tokens.md)*
- **Step 4:** YAML Dataset & `2-networking.auto.tfvars` Generation
- **Step 5:** Mechanical Validation (`scripts/validate_dataset.py`, including `terraform validate` and `terraform plan`)
- **Step 6:** Dataset `README.md` & Follow-up Stage Handoff Summary
