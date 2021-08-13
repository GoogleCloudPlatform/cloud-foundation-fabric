# Terraform Examples and Modules for Google Cloud

This repository provides **end-to-end examples** and a **suite of Terraform modules** for Google Cloud, which support different use cases:

- starter kits used to bootstrap real-world cloud foundations, and reference examples used to deep dive on network patterns or product features
- composable modules that support quick prototyping and testing
- a comprehensive source of lean modules that lend themselves well to changes

The whole repository is meant to be cloned as a single unit, and then forked into separate owned repositories to seed production usage, or used as-is and periodically updated as a complete toolkit for prototyping. You can read more on this approach in our [manifesto](./MANIFESTO.md).

Both the examples and modules require some measure of Terraform skills to be used effectively. If you are looking for a feature-rich black box to manage project or product creation with minimal specific skills, you might be better served by the [Cloud Foundation Toolkit](https://registry.terraform.io/modules/terraform-google-modules) suite of modules.

## End-to-end examples

The examples in this repository are split in several main sections: **foundational examples** that bootstrap the organizational hierarchy and automation prerequisites, **networking examples** that implement core patterns or features, **data solutions examples** that demonstrate how to integrate data services in complete scenarios, and **cloud operations examples** that leverage specific products to meet specific operational needs.

Currently available examples:

- **foundations** - [single level hierarchy](./foundations/environments/) (environments), [multiple level hierarchy](./foundations/business-units/) (business units + environments)
- **networking** - [hub and spoke via peering](./networking/hub-and-spoke-peering/), [hub and spoke via VPN](./networking/hub-and-spoke-vpn/), [DNS and Google Private Access for on-premises](./networking/onprem-google-access-dns/), [Shared VPC with GKE support](./networking/shared-vpc-gke/), [ILB as next hop](./networking/ilb-next-hop), [PSC for on-premises Cloud Function invocation](./networking/private-cloud-function-from-onprem/), [decentralized firewall](./networking/decentralized-firewall)
- **data solutions** - [GCE/GCS CMEK via centralized Cloud KMS](./data-solutions/cmek-via-centralized-kms/), [Cloud Storage to Bigquery with Cloud Dataflow](./data-solutions/gcs-to-bq-with-dataflow/)
- **cloud operations** - [Resource tracking and remediation via Cloud Asset feeds](.//cloud-operations/asset-inventory-feed-remediation), [Granular Cloud DNS IAM via Service Directory](./cloud-operations/dns-fine-grained-iam), [Granular Cloud DNS IAM for Shared VPC](./cloud-operations/dns-shared-vpc), [Compute Engine quota monitoring](./cloud-operations/quota-monitoring), [Scheduled Cloud Asset Inventory Export to Bigquery](./cloud-operations/scheduled-asset-inventory-export-bq)
- **third party solutions** - [OpenShift cluster on Shared VPC](./third-party-solutions/openshift)

For more information see the README files in the [foundations](./foundations/), [networking](./networking/), [data solutions](./data-solutions/) and [cloud operations](./cloud-operations/) folders.

## Modules

The suite of modules in this repository are designed for rapid composition and reuse, and to be reasonably simple and readable so that they can be forked and changed where use of third party code and sources is not allowed.

All modules share a similar interface where each module tries to stay close to the underlying provider resources, support IAM together with resource creation and modification, offer the option of creating multiple resources where it makes sense (eg not for projects), and be completely free of side-effects (eg no external commands).

The current list of modules supports most of the core foundational and networking components used to design end-to-end infrastructure, with more modules in active development for specialized compute, security, and data scenarios.

Currently available modules:

- **foundational** - [folder](./modules/folder), [organization](./modules/organization), [project](./modules/project), [service accounts](./modules/iam-service-account), [logging bucket](./modules/logging-bucket)
- **networking** - [VPC](./modules/net-vpc), [VPC firewall](./modules/net-vpc-firewall), [VPC peering](./modules/net-vpc-peering), [VPN static](./modules/net-vpn-static), [VPN dynamic](./modules/net-vpn-dynamic), [VPN HA](./modules/net-vpn-ha), [NAT](./modules/net-cloudnat), [address reservation](./modules/net-address), [DNS](./modules/dns), [L4 ILB](./modules/net-ilb), [Service Directory](./modules/service-directory), [Cloud Endpoints](./modules/cloudenpoints)
- **compute** - [VM/VM group](./modules/compute-vm), [MIG](./modules/compute-mig), [GKE cluster](./modules/gke-cluster), [GKE nodepool](./modules/gke-nodepool), [COS container](./modules/cos-container) (coredns, mysql, onprem, squid)
- **data** - [GCS](./modules/gcs), [BigQuery dataset](./modules/bigquery-dataset), [Pub/Sub](./modules/pubsub), [Datafusion](./modules/datafusion), [Bigtable instance](./modules/bigtable-instance)
- **development** - [Cloud Source Repository](./modules/source-repository), [Container Registry](./modules/container-registry), [Artifact Registry](./modules/artifact-registry), [Apigee Organization](./modules/apigee-organization), [Apigee X Instance](./modules/apigee-x-instance)
- **security** - [KMS](./modules/kms), [SecretManager](./modules/secret-manager), [VPC Service Control](./modules/vpc-sc)
- **serverless** - [Cloud Function](./modules/cloud-function)

For more information and usage examples see each module's README file.
