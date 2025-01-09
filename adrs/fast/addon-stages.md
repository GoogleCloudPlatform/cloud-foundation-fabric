# Add-on stages

**authors:** [Ludo](https://github.com/ludoo), [Julio](https://github.com/juliocc)  
**date:** Jan 5, 2025

## Status

Under implementation in [#2800](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2800)

## Context

Some optional features are too complex to directly embed in stages, as they would complicate the variable scope, need to be replicated across parallel stages, and introduce a lot of nested code for the benefit of a small subset of users.

This need has surfaced with the network security stage, which has taken the approach of spreading its resources across different stages (security, networking, and its own netsec) and resulted in very layered, complicated code which is not easy to deploy or maintain.

This is how the current netsec stage looks like from a resource perspective:

![image](https://github.com/user-attachments/assets/c9778cd8-8dd4-4f7c-b74b-c5d8ad7e7d30)

Furthermore, the stage also tries to do "too much", by behaving as a full stage and adopting a design that statically maps its resources onto all FAST environments and networks. This results in code that is really hard to adapt for real life use cases and impossible to keep forward compatible, as changes are extensive and spread out across three stages.

## Proposal

The proposal is to adopt a completely different approach, where large optional featuresets that we don't want to embed in our default stages should become "addon stages" that:

- reuse the IaC service account and bucket of the stage they interact with (e.g. networking for network security) to eliminate the need for custom IAM
- encapsulate all their resources in a single root module (the add-on stage)
- don't implement a static design but deal with the smallest possible unit of work, so that they can be cloned to implement different designs via tfvars
- provide optional FAST output variables for the main stages

This is what the network security stage looks like, once refactored according this proposal:

![image](https://github.com/user-attachments/assets/748b8b53-8df7-444e-9c71-f74e462a96f1)

With this approach

- there are no dependencies in resman except for a providers file that adds a prefix to the state backend and reuses networking service accounts and bucket
- the stage design does not deal with environments, but simply implements one complete set of NGFW resources in a given project (typically the net landing or shared environment project) and allows free configuration of zones and VPC attachments
- any relevant resource already defined in the "main" stages can be referred to via interpolation, by using the stages outputs as contexts

The code then becomes really simple to use, read and evolve since it's essentially decoupled from the main stages except for a handful of FAST interface variables.

Add-on stages should live in a separate folder from stages, and once we finally manage to reafctor networking into a simple stage, we go back to having a clear progression for main stages that should make it easier for users to get to grips with FAST's complexity. We might also want to scrap the plugins folder, and replace with a short document explaining the pattern.

```bash
fast
├── addons
    ├── 1-resman-tenants
    └── 2-networking-ngfw
├── extras
│   ├── 0-cicd-github
│   └── 0-cicd-gitlab
└── stages
    ├── 0-bootstrap
    ├── 1-resman
    ├── 1-vpcsc
    ├── 2-networking-a-simple
    ├── 2-networking-b-nva
    ├── 2-networking-c-separate-envs
    ├── 2-project-factory
    ├── 2-security
    ├── 3-gcve-dev
    └── 3-gke-dev
```

An add-on stage:

- reuses its "parent stage" IaC resources and leverages their existing IAM
- uses a generated backend file that adds a prefix to the parent GCS backend
- optionally defines a CI/CD configuration that creates dedicated WIF/service accounts/workflow configurations and resources, that allow impersonating the "parent stage" service accounts from a separate repository

## Decision

Implement the proposal.

## Consequences

This approach also maps well to the current tenant factory stage, which essentially acts as a parallel resman stage reusing the same set of IaC resources.
