# Remove initial gcloud commands needed to bootstrap

**authors:** [Ludo](https://github.com/ludoo)\
**date:** July 13, 2023

## Status

Rejected.

## Context

The initial `gcloud` commands that grant IAM roles to the user running `apply` for the first time, are sometimes seen as an extra hurdle and an unnecessary complication.

These are the roles in question

- `roles/logging.admin`
- `roles/owner`
- `roles/resourcemanager.organizationAdmin`
- `roles/resourcemanager.projectCreator`

One proposal we investigated was internalizing those IAM bindings in the actual Terraform code, either via bare resources or an additional organization module invocation, and depending subsequent resources on it.

On further investigation, this poses a few challenges

- the roles in question are managed authoritatively, and it would be best they remained so (e.g. to clear the Project Creator role, or ensure Organization Administrators match what is in the code)
- project creation depends on those roles, but this creates a cycle dependency as the service accounts created are also assigned those roles, and they cannot implicitly depend (via the project) on the same roles

Working around this issue would require a substantial amount of hoops and a lot of development effort. It would also result in potentially less safe and more fragile code.

## Decision

What we decided is to leave those external commands in place, as the hurdle is minimal and not worth the expense and risks of removing it.

## Consequences

Nothing changes due to this decision.
