# Resource Factories

This set of modules creates specialized resource factories, made of two distinct components:

- a module, which implements the factory logic in Terraform syntax, and
- a set of directories, which hold the configuration for the factory in YAML syntax.

## Available modules

- [Hierarchical Firewall policies](./firewall-hierarchical-policies)
- [VPC Firewall rules](./firewall-vpc-rules)
- [Subnets](./subnets)

## Example implementation

See [Example environments](./example-environments)

## Using the modules

Each module is specialised and comes with a `README.md` file which describes the module interface, as well as the directory structure each module requires.

## Rationale
This approach is based on modules implementing the factory logic using Terraform code and a set of directories having a well-defined, semantic structure, holding the configuration for the resources in YaML syntax.

Resource factories are designed to:

- accelerate and rationalize the repetitive creation of common resources, such as firewall rules and subnets.
- enable teams without Terraform specific knowledge to build IaC leveraging human-friendly and machine-parseable YAML files
- make it simple to implement specific requirements and best practices (e.g. "always enable PGA for GCP subnets", or "only allow using regions `europe-west1` and `europe-west3`")
- codify and centralise business logics and policies (e.g. labels and naming conventions)

Terraform natively supports YaML, JSON and CSV parsing - however we've decided to embrace YaML for the following reasons:

- YaML is easier to parse for a human, and allows for comments and nested, complex structures
- JSON and CSV can't include comments, which can be used to document configurations, but are often useful to bridge from other systems in automated pipelines
- JSON is more verbose (reads: longer) and harder to parse for a human
- CSV isn't often expressive enough (e.g. doesn't allow for nested structures)

If needed, converting factories to consume JSON instead is a matter of switching from `yamldecode()` to `jsondecode()` in the right place on each module.

