# Fast stages

Each of the folders contained here is a separate "stage", or Terraform root module.

Each stage can be run in isolation (for example to only bring up a hub and spoke VPC in an existing environment), but when combined together they form a modular setup that allows top-down configuration of a whole GCP organization.

When combined together, each stage is designed to leverage the previous stage's resources and to provide outputs to the following stages via predefined contracts, that regulate what is exchanged.

This has two important consequences

- any stage can be swapped out and replaced by different code as long as it respects the contract by providing a predefined set of outputs and optionally accepting a predefined set of variables
- data flow between stages can be partially automated (see [stage 00 documentation on output files](./00-bootstrap/README.md#output-files-and-cross-stage-variables)), reducing the effort and pain required to compile variables by hand

One important assumption is that the flow of data is always forward looking, so no stage needs to depend on outputs generated further down the chain. This greatly simplifies both the logic and the implementation, and allows stages to be effectively independent.

To achieve this, we rely on specific GCP functionality like [delegated role grants](https://medium.com/google-cloud/managing-gcp-service-usage-through-delegated-role-grants-a843610f2226) that allow controlled delegation of responsibilities, for example to allow managing IAM bindings at the organization level in different stages only for specific roles.

Refer to each stage's documentation for a detailed description of its purpose, the architectural choices made in its design, and how it can be configured and wired together to terraform a whole GCP organization. The following is a brief overview of each stage.

To destroy a previous FAST deployment follow the instructions detailed in [cleanup](CLEANUP.md).

## Organizational level (00-01)

- [Bootstrap](00-bootstrap/README.md)  
  Enables critical organization-level functionality that depends on broad permissions. It has two primary purposes. The first is to bootstrap the resources needed for automation of this and the following stages (service accounts, GCS buckets). And secondly, it applies the minimum amount of configuration needed at the organization level, to avoid the need of broad permissions later on, and to implement a minimum of security features like sinks and exports from the start.\
  Exports: automation variables, organization-level custom roles
- [CI/CD Bootstrap](00-cicd/README.md)  
  Optionally set up CI/CD repositories and project structure automatically for GitHub and Gitlab. This stage is not needed if repository are created manually.
- [Resource Management](01-resman/README.md)  
  Creates the base resource hierarchy (folders) and the automation resources required later to delegate deployment of each part of the hierarchy to separate stages. This stage also configures organization-level policies and any exceptions needed by different branches of the resource hierarchy.\
  Exports: folder ids, automation service account emails

## Shared resources (02)

- [Security](02-security/README.md)  
  Manages centralized security configurations in a separate stage, and is typically owned by the security team. This stage implements VPC Security Controls via separate perimeters for environments and central services, and creates projects to host centralized KMS keys used by the whole organization. It's meant to be easily extended to include other security-related resources which are required, like Secret Manager.\
  Exports: KMS key ids
- Networking ([VPN](02-networking-vpn/README.md)/[NVA](02-networking-nva/README.md)/[Peering](02-networking-separate-envs/README.md)/[Separate environments](02-networking-separate-envs/README.md))  
  Manages centralized network resources in a separate stage, and is typically owned by the networking team. This stage implements a hub-and-spoke design, and includes connectivity via VPN to on-premises, and YAML-based factories for firewall rules (hierarchical and VPC-level) and subnets. It's currently available in four flavors: [spokes connected via VPN](02-networking-vpn/README.md), [and spokes connected via appliances](02-networking-nva/README.md),  [spokes connected via VPC peering](02-networking-peering/README.md), and [separated network environments](02-networking-separate-envs/README.md).\
  Exports: host project ids and numbers, vpc self links

## Environment-level resources (03)

- [Project Factory](03-project-factory/dev/)  
  YAML-based fatory to create and configure application or team-level projects. Configuration includes VPC-level settings for Shared VPC, service-level configuration for CMEK encryption via centralized keys, and service account creation for workloads and applications. This stage is meant to be used once per environment.
- [Data Platform](03-data-platform/dev/)
- [GKE Multitenant](03-gke-multitenant/dev/)
- GCE Migration (in development)
