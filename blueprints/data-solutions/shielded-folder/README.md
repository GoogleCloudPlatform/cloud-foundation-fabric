# Shielded folder

This module implements an opinionated Folder configuration to implement GCP best practices. Configurations implemented on the folder would be beneficial to host Workloads hineriting contrains from the folder they belong to.

In this blueprint, a folder will be created implementing the following features:
- Organizational policies
- Hirarckical firewall rules
- VPC-SC

Withing the folder the following projects will be created:
- '


#TODO Proper README (after deciding if this is a blueprint or a FAST stage)

# Implemented
- Use of Scoped Policies (create or inherit)
- VPC SC adding all Folder's project into the perimeter
- Org policies
- Hierarchical firewall rules

# TODO
- Log sync
- KMS