# Shared VPC sample

This sample creates a basic [Shared VPC](https://cloud.google.com/vpc/docs/shared-vpc) infrastructure, where two service projects are connected to separate subnets, and the host project exposes Cloud DNS and Cloud KMS as centralized services. The service projects are slightly different, as they are meant to illustrate the IAM-level differences that need to be taken into account when sharing subnets for GCE or GKE.

This sample is meant to show the wiring between different modules needed to create Shared VPC infrastructures, and is designed for prototyping or experimentation. Additional best practices and security considerations need to be taken into account in real world scenarios (removal of default service accounts, disabling of external IPs, firewall design, etc).

![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates several distinct groups of resources:

- three projects (Shared VPC host and two service projects)
- VPC-level resources (VPC, subnets, firewall rules, etc.)
- one internal Cloud DNS zone and associated records
- one Cloud KMS keyring with one key
- IAM roles to wire all the above resource together
- one test VM in each project

The resources and outputs used for testing are encapsulated in the `test-resources.tf` file, and can be safely removed as a unit.