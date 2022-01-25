# Fast stages

Each of the folders contained here is a separate "stage", or Terraform root module.

They are designed to be combined together, each stage leveraging the previous stage's resources and providing outputs to the following stages, but they can also be run in isolation if their specific functionality is all that is needed (e.g. only bring up a hub and spoke VPC in an existing environment).

Refer to each stage's documentation for a detailed description of its purpose, the architectural choices made in its design, and how it can be configured and wired together to terraform a whole GCP organization. The following is a brief overview of each stage.

## Organizational level (00-01)

- [Bootstrap](00-bootstrap/README.md)  
  Enables critical organization-level functionality that depends on broad permissions. It has two primary purposes. The first is to bootstrap the resources needed for automation of this and the following stages (service accounts, GCS buckets). And secondly, it applies the minimum amount of configuration needed at the organization level, to avoid the need of broad permissions later on, and to implement a minimum of security features like sinks and exports from the start.
- [Resource Management](01-resman/README.md)  
  Creates the base resource hierarchy (folders) and the automation resources required later to delegate deployment of each part of the hierarchy to separate stages. This stage also configures organization-level policies and any exceptions needed by different branches of the resource hierarchy.

## Shared resources (02)

- [Security](02-security/README.md)  
  Manages centralized security configurations in a separate stage, and is typically owned by the security team. This stage implements VPC Security Controls via separate perimeters for environments and central services, and creates projects to host centralized KMS keys used by the whole organization. It's meant to be easily extended to include other security-related resources which are required, like Secret Manager.
- [Networking](02-networking/README.md)  
  Manages centralized network resources in a separate stage, and is typically owned by the networking team. This stage implements a hub-and-spoke design, and includes connectivity via VPN to on-premises, and YAML-based factories for firewall rules (hierarchical and VPC-level) and subnets.

## Environment-level resources (03)

- [Project Factory](03-project-factory/README.md)  
  YAML-based fatory to create and configure application or team-level projects. Configuration includes VPC-level settings for Shared VPC, service-level configuration for CMEK encryption via centralized keys, and service account creation for workloads and applications. This stage is meant to be used once per environment.
- Data Platform (in development)
- GKE Multitenant (in development)
- GCE Migration (in development)
