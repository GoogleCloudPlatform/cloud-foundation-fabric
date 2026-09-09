# Service Agent IAM Bindings on External Resources

**authors:** [ludomagno](https://github.com/ludomagno)
**date:** Sep 9, 2026

## Status

Proposed

## Context

The `project` module can grant its own service agents roles on resources outside the project in exactly two places, using interfaces which map the specific relationships:

- `shared_vpc_service_config`, whose `service_agent_iam`, `network_users`, `iam_bindings_additive`, `service_agent_subnet_iam` and `network_subnet_users` all resolve against the Shared VPC host project.
- `service_encryption_key_ids`, which grants agents on KMS keys in another project with the role hardcoded to `roles/cloudkms.cryptoKeyEncrypterDecrypter`.

There is no mechanism for an arbitrary external target. Service accounts created by the respective module already have one, through `iam_project_roles` and `iam_project_bindings` and their folder, organization, billing, storage and service account siblings, all exposed in `project-factory` on each `service_accounts` entry. Service agents in the project module have no equivalent.

The gap matters because a service agent's member string cannot be written by the caller: it embeds the project number, which does not exist until the project is created. The module that creates the project is therefore the only place that can name the member, and any grant on an external resource has to originate there.

The gap is also shared in the project factory, where context can be used to assign roles by reference to service agents belonging to other projects, but *only if those projects are also created within the same project factory instance*, or carried downstream via context.

The case that surfaced this is a Secure Source Manager instance in a VPC Service Controls perimeter. Its service agent needs `roles/privateca.certificateRequester` on a Certificate Authority Service pool owned by a preceding stage, before the instance is created. Nothing in the current interface can express it.

## Decision

Add one variable per external target type, and keep the surface as small and flat as possible since usage is minimal (specific cases for one or two roles), while still providing support for the full additive IAM interface including conditions.

```hcl
variable "service_agents_project_bindings" {
  type = map(object({
    service = string
    project = string
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}
```

`service_agents_folder_bindings` is the same type with `folder` in place of `project`. Organization is deliberately left out until a case needs it; the pattern extends without further decisions.

Four points that follow:

1. **`service` is a service name**, resolved internally to agents through `local.aliased_service_agents` as `shared-vpc.tf`, and not via`local.service_agents_by_api` as `cmek.tf` does which includes dependent services (`container.googleapis.com` ---> `[compute, container-engine-robot]`).
2. **Targets and roles resolve through context**, `ctx.project_ids` and `ctx.folder_ids` for the target and `ctx.custom_roles` for the role, since the target is usually a factory-managed resource whose id is unknown at authoring time.
3. **Conditions are supported directly**, with `templatestring(..., var.context.condition_vars)` on the expression, per the conventions already used across the module.
4. **No parallel `_roles` variable.** The dual-variable pattern adopted for `iam-service-account` exists because that module has one implicit subject, so `map(list(string))` buys real terseness. Here the subject is explicit in every entry, the terse form would save one line per grant, and these grants are rare. One variable per target type is enough.

One variable per target type is preferred over a single variable carrying the target type as a field, even though the latter would collapse the set into one. Per-target variables are the established pattern across `iam-service-account`, and consistency with it is worth more than the reduction.

## Consequences

- **Closes the interface gap** that currently forces service agent grants on external resources to be made out of band, outside Terraform.
- **`shared_vpc_service_config.service_agent_iam` becomes a special case of the new variable**, with the target fixed to the host project. It will be marked as deprecated and later retired in favour of it, which would remove the near-collision between the two names.
- **Adds two variables** to the public interface of the `project` module, and two more to `project-factory` and to every FAST stage that carries a copy of the project schema.
- **A single entry can produce several bindings**, which is visible in plan output and in state keys. Callers who want one binding should name one API that maps to one agent.
- **No implicit ordering.** The external target must already exist and the caller must hold rights on it; nothing in the variable creates a dependency, which matches how `iam_project_roles` behaves on service accounts today.
