---
trigger: always_on
---

Stages in the FAST folder are split between Terraform code and datasets. The code is used to implement generic resource creation factories (project, folder, etc.), while the actual description of the resources and their relationships is implemented via YAML configurations read by the factories. YAML configurations are grouped in "datasets" which implement a complete design. Each factory has a reference JSON schema used to describe and validate the YAML data.

- factories are generally implemented in modules, not in FAST stages
- modules deal with one specific resource set (eg an instance and its disks, a project and its org policies, IAM, etc.) and generally implement a single factory
- the project and vpc factory modules are the exception, as they are designed as "macro modules" to support interrelated creation of resources pertaining to a larger scope
- FAST stages should generally not implement factories, but leverage those defined in modules and their associated schemas