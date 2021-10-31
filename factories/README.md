# Resource Factories

This set of modules creates specialized resource factories, made of two distinct components:

- a module, which implements the factory logic in Terraform syntax, and
- a set of directories, which hold the configuration for the factory in YAML syntax.

## Available modules

- [Hierarchical Firewall policies](./firewall-hierarchical-policies)
- [VPC Firewall rules](./firewall-vpc-rules)
- [Subnets](./subnets)

## Using the modules

Each module specialises on a single resource type, and comes with a `README.md` file which describes the module interface, and the directory/file structure each module requires.

All modules consume specialized `yaml` configurations - located on a well-defined directory structure that carries metadata. Let's observe an example which leverages the `subnet` module, taken from the [Example environments](example-environments/) directory:

```yaml
# ../example-environments/prod/conf/project-prod-a/vpc-alpha/subnet-alpha-a.yaml

region: europe-west3
ip_cidr_range: 10.0.0.0/24
description: Sample Subnet in project project-prod-a, vpc-alpha
secondary_ip_ranges:
  secondary-range-a: 192.168.0.0/24
  secondary-range-b: 192.168.1.0/24
```

This configuration creates the `subnet-alpha-a` subnet, located in VPC `vpc-alpha`, inside project `project-prod-a`.

## Rationale

This approach is based on modules implementing the factory logic using Terraform code, and a set of directories having a well-defined, semantic structure holding the configuration for the resources in YaML syntax.

Resource factories are designed to:

- accelerate and rationalize the repetitive creation of common resources, such as firewall rules and subnets
- enable teams without Terraform specific knowledge to leverage IaC via human-friendly and machine-parseable YAML files
- make it simple to implement specific requirements and best practices (e.g. "always enable PGA for GCP subnets", or "only allow using regions `europe-west1` and `europe-west3`")
- codify and centralise business logics and policies (e.g. labels and naming conventions)
- allow to easily parse and understand sets of specific resources, for documentation purposes

Terraform natively supports YaML, JSON and CSV parsing - however we've decided to embrace YaML for the following reasons:

- YaML is easier to parse for a human, and allows for comments and nested, complex structures
- JSON and CSV can't include comments, which can be used to document configurations, but are often useful to bridge from other systems in automated pipelines
- JSON is more verbose (reads: longer) and harder to parse visually for humans
- CSV isn't often expressive enough (e.g. dit oesn't allow for nested structures)

If needed, converting factories to consume JSON is a matter of switching from `yamldecode()` to `jsondecode()` in the right place on each module.
