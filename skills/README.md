# Fabric Skills

This directory contains skills for AI agents to leverage Cloud Foundation Fabric (CFF). These skills provide context, guidelines, and tools for agents to perform specific tasks related to CFF.

## Auto-Discovery in a Repository Clone

Cloning this repository automatically exposes the stable user-facing skills (`fabric-builder`, `fast-networking`, and `fast-prerequisites`) and the contributor skill (`cff-contributing`) through per-skill symlinks in `.agents/skills/` (with `.claude/skills` aliased to `../.agents/skills` for Claude Code). Incubating skills (such as `fabric-importer`) and maintainer-only skills (`skills/maintainer/`) are intentionally not linked there so cloners do not pick up beta or maintainer workflows by default; because repo-facing `cff-*` skills link to repository files, install opt-in maintainer skills by symlinking them into the checkout's `.agents/skills/` (ignored by `.gitignore`).

## Installing with `agents-cli`

You can install the user-facing Fabric skills (`fabric-builder`, `fast-networking`, and `fast-prerequisites`) into your project's `.agents/skills/` directory (or globally into `~/.agents/skills/` with `--global`) using [`agents-cli`](https://google.github.io/agents-cli/guide/extensions/):

```bash
agents-cli extension add GoogleCloudPlatform/cloud-foundation-fabric
```

## Available Skills

Skills are organized into four audience-oriented buckets, and every leaf directory matches its `SKILL.md` frontmatter `name:` so skills can be symlinked or installed directly into a flat `.agents/skills/<name>` directory without remapping.

### Fabric (`skills/fabric/`)

- **[fabric-builder](./fabric/fabric-builder)**: Generates idiomatic Cloud Foundation Fabric (CFF) Terraform configurations and schema-validated YAML factory datasets (`project-factory`, `net-vpc-factory`, `vpc-sc`, in-module `factories_config`, and FAST stage datasets). Includes `scripts/fabric.py` for live module, factory catalog, and JSON schema lookups plus YAML validation.
- **[fabric-importer](./fabric/fabric-importer)**: Reverse-engineers live GCP resources into Cloud Foundation Fabric Terraform modules with native import blocks, driven by an agreed import manifest and verified by automated completeness and plan-convergence gates. Use when migrating or importing existing GCP infrastructure into Cloud Foundation Fabric or Terraform.

### FAST (`skills/fast/`)

- **[fast-networking](./fast/fast-networking)**: Designs, customizes, and validates FAST `2-networking` YAML datasets from user requirements, reference diagrams, or existing topologies. Use when a user asks to design a GCP landing zone network, choose or customize a `2-networking` dataset (Single Shared VPC, NCC, NVA NCC Router Appliance, NVA ILB sandwich, VPC Peering, HA VPN), convert a network diagram into FAST YAML, or validate a `2-networking` dataset.
- **[fast-prerequisites](./fast/fast-prerequisites)**: Guides the user step-by-step through the prerequisites for the FAST `0-org-setup` stage, supporting both Standard GCP and Google Cloud Dedicated (GCD) environments. Use when a user asks to prepare or run prerequisites for `0-org-setup` or bootstrap the FAST landing zone.

### Contributor (`skills/contributor/`)

- **[cff-contributing](./contributor/cff-contributing)**: Design-first contributor guide and PR workflow for Cloud Foundation Fabric. Use when implementing a Fabric GitHub issue, designing or modifying modules, YAML factories, schemas, or FAST boundaries, writing `tftest`/README tests, or preparing a Fabric pull request.

### Maintainer (`skills/maintainer/`)

- **[cff-issue-triage](./maintainer/cff-issue-triage)**: Maintainer GitHub issue triage guide for Cloud Foundation Fabric. Use when triaging incoming Fabric issues or sweeping the backlog to classify bugs, enhancements, questions, duplicates, or out-of-scope proposals, verify claims against current code and released provider docs, recommend labels and disposition, and optionally hand off into `cff-contributing`.
- **[cff-pr-review](./maintainer/cff-pr-review)**: Maintainer pull request review guide for Cloud Foundation Fabric. Use when reviewing a Fabric GitHub PR or local branch diff for architectural fit, canonical module and factory interfaces, HCL and OpenTofu correctness, test inventory accuracy, FAST blast radius, and repository hygiene.
- **[cff-release](./maintainer/cff-release)**: Guide for cutting a new release of the Cloud Foundation Fabric (CFF) repository. Use this skill when asked to create, prepare, or draft a new release.
