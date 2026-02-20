---
trigger: always_on
---

# Use factory datasets for resource configuration

**FAST stages should generally not implement factories, but leverage those defined in modules and their associated schemas.**

Stages in the FAST folder are split between Terraform code and datasets.

Code is used to implement and wire together "factories" that implement resource management, while the actual description of resources and their relationships is implemented via YAML configurations read by those factories.

- YAML configurations are grouped in "datasets" which implement a complete design for the stage
- each factory has a reference JSON schema used to describe and validate the YAML data
- factories are generally implemented in the underlying modules, not in FAST stages
- modules deal with one specific resource set (eg an instance and its disks, a project and its org policies, IAM, etc.) and generally implement a single factory
- the project and VPC factory modules are the exception, as they are designed as "macro modules" to support interrelated creation of resources pertaining to a larger scope
- modules that do not manage "sets" of resources (e.g. one project, one folder, one dataset, etc.) typically do not have an associated factory, or only do for sub-resources (e.g. rules in a single policy), those factories are either implemented in the "macro modules" or directly in FAST
