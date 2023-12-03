# Add new service account for CI/CD with plan-only permissions

**authors:** [Ludo](https://github.com/ludoo)
**date:** December 3, 2023

## Status

In development.

## Context

The current CI/CD workflows are inherently insecure, as the same service account is used to run `terraform plan` in PR checks, and `terraform apply` in merges.

The Workload Identity Federation provider allows pinning a branch which could be used to only allow using the service account in merges, but that has the consequence of preventing PR checks to work.

## Proposal

The obvious solution is to use two separate service accounts for CI/CD

- a lower privileged one that is only able to read resources and can be safely used to run `terraform plan` during PR checks
- a higher privileged one which can modify resources and is used to run `terraform apply` during merges, and can be restricted to work from a single branch (typically `main`)

Implementing this proposal would mean

- adding the read-only service account and relevant set of role bindings to stage 0 and 1 for all CI/CD repositories
- changing the definition of the per-repository WIF provider so two providers are actually created if a branch condition is desired, one for the deprivileged service account with no condition, and one for the priviled one with the condition (typically on the `main` branch)
- changing the CI/CD workflows to separate `plan` and `apply` credentials

## Decision

This has been surfaced a while ago and implementation was only pending actual time for development. Development has started.

## Consequences

Existing CI/CD workflows will need to be replaced.
