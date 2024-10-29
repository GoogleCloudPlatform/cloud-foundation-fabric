# Factories Refactor and Plan Forward

**authors:** [Ludo](https://github.com/ludoo)
**last modified:** February 16, 2024

## Status

Under discussion.

## Context

Factories evolved progressively in Fabric, from the original firewall factory module, to a semi-standardized approach to management of repeated resources. This progression happened piecemeal and it's now time to define a clear strategy for factories in both Fabric and FAST, so that we can remove guesswork from new developments and provide a predictive approach to users.

The remainder of this section provides a summary of the current status.

### Modules

Several modules implement factories for repeated resources which are typically dependent from the main resource managed in the module:

- `billing-account` provides a factory for billing alert rules tied to the billing account
- `dns-response-policy` provides a factory for rules in within the policy
- `net-firewall-policy` provides a factory for rules within the policy
- `net-vpc` provides a factory for subnets in the VPC
- `net-vpc-firewall` provides a factory for VPC firewall rules
- `organization` and `folder` provide a factory for hierarchical firewall rules within their policy
- `organization`, `folder` and `project` provide a factory for organization policies

The common pattern for modules is management of *multiple resources* typically dependent from the single *main resource* managed by the module.

### Blueprints

The `factories` folder in blueprints contains a collection of factories with a fuzzier approach

- `bigquery-factory` manages tables and views for 1-n datasets by wrapping the `bigquery-dataset` module via simple locals
- `cloud-identity-group-factory` manages Cloud Identity group members for 1-n groups by wrapping the `cloud-identity-group` via simple locals
- `net-vpc-firewall-yaml` is the original factory module managing VPC firewall rules, superseded by the factory in the `net-vpc-firewall` module
- `project-factory` combines the project, service account, and (planned) billing account and VPC modules to implement end-to-end project creation and configuration

There's no clear common pattern for these factories, where some could be moved to the respective module and the project factory combines a collection of modules to implement a process.

### FAST

FAST currently leverages module-level factories (organization policies, subnets, firewalls, etc.), and also provides the project factory as a dedicated level 3 stage by wrapping the relevant blueprint and localizing a few variables for the environment (`prefix`, `labels`).

## Proposal

While the current approach is reasonably clear in regards to modules, it has never been formalized in a set of guidelines that can help authors define when and how new factories would made sense.

On top of this, the `factories` blueprints folder contains code that that should really be moved to module-level factories, and the project factory which could/should be published directly as a FAST stage, since those are consumable as standalone modules.

This proposal aims at addressing the above problems.

### Module-level factory approach

The current approach for module-level factories can be summarized in a single principle:

> factories implemented in modules manage multiple resources which depend from one single main resource (or a small set of main resources) which are the main driver of the module.

For example, the module managing a firewall policy exposes a factory for its rules, or the module managing a VPC exposes a factory for its subnets. But the project module would not expose a projects factory, as one project maps to a single module invocation.

The proposal on factory modules then is to:

- align all factory variables to the same standard, outlined below
- move the groups and bigquery factories from blueprints to the respective modules
- eventually add more factories when it makes sense to do so (e.g. for KMS keys, service accounts, etc.)

The variable interface for module-level factories should use a single top-level `factory_configs` variable, whose type is an object with one or more attributes which are named according to the specific factory. This will allow composing multiple factory configurations into a single variable in FAST stages, by avoiding name overlaps. An example:

```hcl
variable "factory_configs" {
  description = "Path to folder containing budget alerts data files."
  type = object({
    budgets_data_path = optional(string, "data/billing-budgets")
  })
  nullable = false
  default  = {}
}
```

### Blueprint factories

The `factories` folder in blueprints will be emptied, and a single README left in it pointing to all the module-level and FAST stage factories available.

As outlined above, the existing factories will be moved to modules (bigquery and groups), FAST (project factory), or deleted (firewall rules).

### FAST factories

The only change for FAST factories will be moving the project factory from blueprints to the stage folder, and updating the path used for the environment-level wrapping stage.

### File schema and filesystem organization

Factory files schema must mimic and implement the variable interface for the module, including optionals and validation - which are implemented in code and checks.

With notable exceptions (currently only the `cidrs.yaml` file consumed by firewall factories), the following convention for files/directory is proposed:

- Factories should consume directories (vs single files)
- All files should contain a dictionary of resources or a single resource
- If the factory accepts one resource per file (e.g. VPC subnets), the file name should be used for the resource name and the YAML should allow defining a `name:` override
- Files in a directory should be parsed together and flattened into a single dictionary

This allows developers to implement multiple resources in a single file or to use one file per resource, as they see fit.

