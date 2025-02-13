# Move organization policies to bootstrap stage

**authors:** [Julio](https://github.com/juliocc), [Ludo](https://github.com/ludoo), [Roberto](https://github.com/drebes) \
**date:** September 13, 2023

## Status

Implemented.

## Context

Three different requirements drive this proposal.

### Organization policies deployed at bootstrap time

Many organizations take security seriously, and would like to have organization policies (for example `iam.automaticIamGrantsForDefaultServiceAccounts`) deployed right from the beginning at bootstrap time. This is currently extremely cumbersome, as organization policies are managed in stage 1.

As an additional benefit, managing some or all organization policies in stage 0 will enable to turn off undesired resource configuration for the initial projects (for example `compute.skipDefaultNetworkCreation`).

### Simplify and limit delegation of Organization Policy Administrator role

Automation service accounts are currently assigned the Organization Policy Administrator role at the organization level, scoped via resource management tags. This is cumbersome as bindings are distributed between stage 0 that delegates role control to the stage 1 service account, and stage 1 that creates the automation service accounts, tags and folder bindings used for scoping.

A more secure way of doing this is via a dedicated resource management tag value hierarchy, and conditions on the organization policies that alter behaviour based on tags. This would allow centrally defining allowed exceptions to organization policies, and selectively granting access to specific exceptions to individual automation service accounts via tag values.

The project factory will need to retain scoped grants, to set policies that enforce lists of resources which would be too cumbersome to maintain in stage 0.

### Reduce stage 1 complexity to allow simpler creation of hierarchy templates

Stage 1 is currently too complex to allow easy cloning into different resource hierarchy templates, which are needed to account for all landing zone designs.

Removing complexity from stage 1 by moving organization policy and its related IAM to stage 0 will be an initial step towards stage 1 simplification.

## Proposal

The proposal is to

- move management of organization policies to stage 0
- move management of the `org_policies` tag key and associated values to stage 0
- remove delegated/conditional grants for the Organization Policy Administrator role from stage 0 and 1

The approach fattens stage 0 and lessens its decoupling role in the overall FAST design, but looks preferable compared to the complexity of splitting organization policy management between stage 0 and 1, or worse delegating control of specific policies to external commands run before stage 0.

## Decision

Decision is to implement this.

## Consequences

Organization policies and related tags will need to be moved from stage 1 to stage 0 state. One approach is to

- switch both states to local state
- use `terraform state mv -state-out` to temporarily move resources from stage 1 to stage 0
- push stage 0 and stage 1 state
