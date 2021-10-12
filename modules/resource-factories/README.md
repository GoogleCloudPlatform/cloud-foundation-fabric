# Resource Factories

This set of modules creates specialized resource factories, made of two distinct components:

- a module, which implements the factory logic in Terraform syntax, and
- a set of directories, which hold the configuration for the factory in YAML syntax.

Such resource factories are designed to:

- simplify and rationalize the repetitive creation of common resources, such as firewall rules and subnets.
- enable teams without Terraform specific knowledge to build IaC leveraging human-friendly and machine-parseable YAML files

## Available modules

- [Hierarchical Firewall rules](./hierarchical-firewall)
- [Monitoring rules](./monitoring)
- [Subnets](./subnet)
- [VPC Firewall rules](./vpc-firewall)

## Using the modules

Each module is specialised and comes with a `README.md` file which describes the module interface, as well as the directory structure each module requires.
