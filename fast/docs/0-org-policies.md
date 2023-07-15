# Support initial org policies in bootstrap stage

**authors:** [Ludo](https://github.com/ludoo), [Roberto](https://github.com/drebes) \
**date:** July 15, 2023

## Status

Under discussion.

## Context

Some organization policies might need to be applied right from the start in stage 0, to better configure defaults for organization resources or to improve security. Two examples are skipping default network creation for projects (which would avoid creating a network in the IaC project), and deprivileging service accounts.

There are essentially two ways of achieving this

- moving organization policies from stage 1 to stage 0, which would also mean moving tags or at least the `org-policies` key and its values
- turning on the organization policy factory in stage 0

The first approach is complex and results in a "fat" stage 0, which then would need to be applied every time an organization policy or even worse a tag is changed. This is counter to our initial approach where stage 0 is a "decoupling" (from org admin permissions) stage, only taking care of org-level IAM and logging, and the initial IaC resources.

The second approach is lightweight and its only impact is in the need to avoid duplication between the organization policies managed in stage 0, and those managed in stage 1.

## Decision

No decision yet, this will need to be discussed.

## Consequences

TBD
