# FAST stages

Each of the folders contained here is a separate "stage", or Terraform root module.

Each stage can be run in isolation (for example to only bring up a hub and spoke VPC in an existing environment), but when combined together they form a modular setup that allows top-down configuration of a whole GCP organization.

When deploying as part of a whole organization setup, each stage provides information on its resources to the following stages via predefined contracts, and each stage can pick and choose what to leverage from the preceding ones.

This has two important consequences:

- any stage can be swapped out and replaced by different code as long as it respects the contract, by providing a predefined set of outputs and optionally accepting a predefined set of variables
- data flow between stages can be partially automated (see [stage 0 documentation on output files](./0-bootstrap/README.md#output-files-and-cross-stage-variables)), reducing the effort and pain required to compile variables by hand

One important assumption is that the flow of data is always forward looking (or sideways for optional components), so no stage needs to depend on outputs generated further down the chain. This greatly simplifies both the logic and the implementation, and allows stages to be effectively independent.

To achieve this, we rely on specific GCP functionality like [delegated role grants](https://medium.com/google-cloud/managing-gcp-service-usage-through-delegated-role-grants-a843610f2226) to allow controlled delegation of responsibilities, and [conditional access via tags](https://cloud.google.com/iam/docs/tags-access-control) to constrain scope for organization-level roles or when specific resources are managed lower in the chain than IAM bindings.

Refer to each stage's documentation for a detailed description of its purpose, the architectural choices made in its design, and how it can be configured and wired together to terraform a whole GCP organization. The following is a brief overview of each stage.

To destroy a previous FAST deployment follow the instructions detailed in [cleanup](CLEANUP.md).

## Organization (0 and 1)

- [Bootstrap](0-bootstrap/README.md)  
  Enables critical organization-level functionality that depends on broad permissions. It has two primary purposes. The first is to bootstrap the resources needed for automation of this and the following stages (service accounts, GCS buckets). And secondly, it applies the minimum amount of configuration needed at the organization level to avoid the need of broad permissions later on, and to implement from the start critical auditing or security features like organization policies, sinks and exports.\
  Exports: automation variables, organization-level custom roles
- [Resource Management](1-resman/README.md)  
  Creates the base resource hierarchy (folders) and the automation resources that will be required later to delegate deployment of each part of the hierarchy to separate stages. This stage also configures resource management tags used in scoping specific IAM roles on the resource hierarchy.\
  Exports: folder ids, automation service account emails, tags
- [VPC Service Controls](./1-vpcsc/README.md)
  Optionally configures VPC Service Controls protection for the organization.

## Multitenancy

Implemented as an [add-on stage 1](./1-tenant-factory/), with optional FAST compatibility for tenants.

## Shared resources (2)

- [Security](2-security/README.md)  
  Manages centralized security configurations in a separate stage, and is typically owned by the security team. This stage implements VPC Security Controls via separate perimeters for environments and central services, and creates projects to host centralized KMS keys used by the whole organization. It's meant to be easily extended to include other security-related resources which are required, like Secret Manager.\
  Exports: KMS key ids
- Networking ([Peering/VPN](2-networking-a-simple/README.md)/[NVA (w/ optional BGP support)](2-networking-b-nva/README.md)/[Separate environments](2-networking-c-separate-envs/README.md))  
  Manages centralized network resources in a separate stage, and is typically owned by the networking team. This stage implements a hub-and-spoke design, and includes connectivity via VPN to on-premises, and YAML-based factories for firewall rules (hierarchical and VPC-level) and subnets. It's currently available in four flavors: [spokes connected via VPC peering/VPN](2-networking-a-simple/README.md), [spokes connected via appliances (w/ optional BGP support)](2-networking-b-nva/README.md) and [separated network environments](2-networking-c-separate-envs/README.md).\
  Exports: host project ids and numbers, vpc self links
- [Project Factory](./2-project-factory/)  
  YAML-based factory to create and configure application or team-level projects. Configuration includes VPC-level settings for Shared VPC, service-level configuration for CMEK encryption via centralized keys, and service account creation for workloads and applications. This stage can be cloned if an org-wide or dedicated per-environment factories are needed.
- [Network Security](./2-network-security/) Optional stage that integrates with security and networking stages to manage a centralized [NGFW Enterprise](https://cloud.google.com/firewall/docs/about-firewalls) deployment.

## Environment-level resources (3)

- [GKE Multitenant](3-gke-dev/)
- [Google Cloud VMware Engine](3-gcve-dev/)
