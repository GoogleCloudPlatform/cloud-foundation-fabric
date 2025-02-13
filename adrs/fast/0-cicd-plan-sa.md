# Add new service accounts for CI/CD with plan-only permissions

**authors:** [Ludo](https://github.com/ludoo) \
**date:** December 3, 2023

## Status

In development.

## Context

The current CI/CD workflows are inherently insecure, as the same service account is used to run `terraform plan` in PR checks, and `terraform apply` in merges.

The current repository configuration variable allows setting a branch which could be used to only allow using the service account in merges, but that only has the consequence of preventing PR checks to work so it's not working as desired.

## Proposal

The proposal is to create a separate "chain" of less privileged service accounts that can only run `plan`, used only when a repository configuration sets a branch for merges in the `cicd_repositories` variable.

### Use cases

#### Merge branch set in repository configuration

```hcl
cicd_repositories = {
  bootstrap = {
    branch            = "main"
    identity_provider = "github-example"
    name              = "example/bootstrap"
    type              = "github"
  }
}
# tftest skip
```

When a merge branch is set as in the example above, the CI/CD workflow will have two separate flows:

- for PR checks, the OIDC token will be exchanged with credentials for the `plan`-only CI/CD service account, which can only impersonate the `plan`-only automation service account
- for merges, the current flow that enables credential exchange and impersonation of the `apply`-enabled service account will be used

#### No merge branch set in repository configuration

```hcl
cicd_repositories = {
  bootstrap = {
    identity_provider = "github-example"
    name              = "example/bootstrap"
    type              = "github"
  }
}
# tftest skip
```

If no merge branch is set in the repository configuration as in the example above, the current behaviour will be preserved allowing exchange and impersonation of the `apply`-enabled service account from any branch.

### Implementation

No changes to variables will be needed other than a lightweight refactor with `optional`.

The following resource changes will need to be implemented:

- define the set of read-only roles for each stage
- create a new automation service account in each stage and assign the identified roles
- create a new CI/CD service account with `roles/iam.serviceAccountTokenCreator` on the new automation service account
- if a merge branch is set in the repository configuration
  - grant `roles/iam.workloadIdentityUser` on the new CI/CD service account to the `principalSet:` matching any branch
  - define a new provider file that impersonates the new automation service account and use it in the workflow for checks
  - keep the existing token exchange via `principal:`, impersonation and provider file for the `apply` part of the workflow only matching the specified merge branch
- if a branch is not set the current behaviour will be kept

Implementation will modify in stages 0 and 1

- the `automation.tf` files
- any file where IAM roles are assigned to the automation service account
- the `cicd-*.tf` files
- the `templates/workflow-*.yaml` files to implement the new workflow logic
- the `outputs.tf` files to generate the additional provider files

## Decision

This has been surfaced a while ago and implementation was only pending actual time for development. Development has started.

## Consequences

Existing CI/CD workflows will need to be replaced when a merge branch is already defined in the repository configuration (unlikely to happen as the current workflow would not work).
