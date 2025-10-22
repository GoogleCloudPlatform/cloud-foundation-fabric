# FAST stages

Each of the folders contained here is a separate "stage", or Terraform root module.

Each stage can be run in isolation (for example to only bring up a hub and spoke VPC in an existing environment), but when combined together they form a modular setup that allows top-down configuration of a whole GCP organization.

When deploying as part of a whole organization setup, each stage provides information on its resources to the following stages via predefined contracts, and each stage can pick and choose what to leverage from the preceding ones.

This has two important consequences:

- any stage can be swapped out and replaced by different code as long as it respects the contract, by providing a predefined set of outputs and optionally accepting a predefined set of variables
- data flow between stages can be partially automated (see [stage 0 documentation on output files](./0-org-setup/README.md#output-files-and-cross-stage-variables)), reducing the effort and pain required to compile variables by hand

One important assumption is that the flow of data is always forward looking (or sideways for optional components), so no stage needs to depend on outputs generated further down the chain. This greatly simplifies both the logic and the implementation, and allows stages to be effectively independent.

To achieve this, we rely on specific GCP functionality like [delegated role grants](https://medium.com/google-cloud/managing-gcp-service-usage-through-delegated-role-grants-a843610f2226) to allow controlled delegation of responsibilities, and [conditional access via tags](https://cloud.google.com/iam/docs/tags-access-control) to constrain scope for organization-level roles or when specific resources are managed lower in the chain than IAM bindings.

Refer to each stage's documentation for a detailed description of its purpose, the architectural choices made in its design, and how it can be configured and wired together to terraform a whole GCP organization. The following is a brief overview of each stage.

Stages encapsulate core designs and functionality that is common in most type of GCP organization set-ups. Specialized designs or additional configurations that add specific functionality on top of stages to meet very specific use cases are defined via [add-ons](../addons/).

To destroy a previous FAST deployment follow the instructions detailed in [cleanup](CLEANUP.md).

## Organization (0)

- [Organization Setup](./0-org-setup/README.md)
  This stage combines the legacy bootstrap and resource management stages described below, allowing easy configuration of all related resources via factories. Its flexibility supports any type of organizational design, while still supporting traditional FAST stages like VPC Service Controls, security, networking, and any stage 3.
  
## VPC Service Controls (1)

- [VPC Service Controls](./1-vpcsc/README.md)
  Optionally configures VPC Service Controls protection for the organization.

## Shared resources (2)

- [Security (Legacy)](2-security-legacy/README.md)  
  Manages centralized security configurations in a separate stage, and is typically owned by the security team. This stage implements VPC Security Controls via separate perimeters for environments and central services, and creates projects to host centralized KMS keys used by the whole organization. It's meant to be easily extended to include other security-related resources which are required, like Secret Manager.\
  Exports: KMS key ids, CA ids
- [Security](2-security/README.md)  
  Manages centralized security configurations in a separate stage, and is typically owned by the security team. This stage implements VPC Security Controls via separate perimeters for environments and central services, and creates projects to host centralized KMS keys used by the whole organization. It's meant to be easily extended to include other security-related resources which are required, like Secret Manager.\
  Exports: KMS key ids, CA ids
- Networking ([Networking factory](2-networking/README.md)) ([Peering/VPN](2-networking-a-simple/README.md)/[NVA (w/ optional BGP support)](2-networking-b-nva/README.md)/[Separate environments](2-networking-c-separate-envs/README.md))  
  Manages centralized network resources in a separate stage, and is typically owned by the networking team. This stage implements all the networking resources required to establish connectivity with on-prem environments, across multiple VPC and to/from the internet.
  Exports: host project ids and numbers, vpc self links
- [Project Factory](./2-project-factory/)  
  YAML-based factory to create and configure application or team-level projects. Configuration includes VPC-level settings for Shared VPC, service-level configuration for CMEK encryption via centralized keys, and service account creation for workloads and applications. This stage can be cloned if an org-wide or dedicated per-environment factories are needed.

## Environment-level resources (3)

- [Data Platform](./3-data-platform-dev/)
- [GKE Multitenant](./3-gke-dev/)
- [Google Cloud VMware Engine](./3-gcve-dev/)
