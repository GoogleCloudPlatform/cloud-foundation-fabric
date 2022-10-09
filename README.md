<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/GoogleCloudPlatform/cloud-foundation-fabric/master/assets/logos/fabric-logo-colors-gray-800.png?v1">
    <img src="https://raw.githubusercontent.com/GoogleCloudPlatform/cloud-foundation-fabric/master/assets/logos/fabric-logo-colors-800.png?v1" alt="Cloud Foundation Fabric">
  </picture>
</p>

# Terraform Examples and Modules for Google Cloud

This repository provides **end-to-end blueprints** and a **suite of Terraform modules** for Google Cloud, which support different use cases:

- organization-wide [landing zone blueprint](fast/) used to bootstrap real-world cloud foundations
- reference [blueprints](./blueprints/) used to deep dive on network patterns or product features
- a comprehensive source of lean [modules](./modules/dns) that lend themselves well to changes

The whole repository is meant to be cloned as a single unit, and then forked into separate owned repositories to seed production usage, or used as-is and periodically updated as a complete toolkit for prototyping. You can read more on this approach in our [contributing guide](./CONTRIBUTING.md), and a comparison against similar toolkits [here](./FABRIC-AND-CFT.md).

## Organization blueprint (Fabric FAST)

Setting up a production-ready GCP organization is often a time-consuming process. Fabric [FAST](fast/) aims to speed up this process via two complementary goals. On the one hand, FAST provides a design of a GCP organization that includes the typical elements required by enterprise customers. Secondly, we provide a reference implementation of the FAST design using Terraform.

## Modules

The suite of modules in this repository are designed for rapid composition and reuse, and to be reasonably simple and readable so that they can be forked and changed where use of third party code and sources is not allowed.

All modules share a similar interface where each module tries to stay close to the underlying provider resources, support IAM together with resource creation and modification, offer the option of creating multiple resources where it makes sense (eg not for projects), and be completely free of side-effects (eg no external commands).

The current list of modules supports most of the core foundational and networking components used to design end-to-end infrastructure, with more modules in active development for specialized compute, security, and data scenarios.

Currently available modules:

- **foundational** - [folder](./modules/folder), [organization](./modules/organization), [project](./modules/project), [service accounts](./modules/iam-service-account), [logging bucket](./modules/logging-bucket), [billing budget](./modules/billing-budget), [projects-data-source](./modules/projects-data-source), [organization-policy](./modules/organization-policy)
- **networking** - [VPC](./modules/net-vpc), [VPC firewall](./modules/net-vpc-firewall), [VPC peering](./modules/net-vpc-peering), [VPN static](./modules/net-vpn-static), [VPN dynamic](./modules/net-vpn-dynamic), [HA VPN](./modules/net-vpn-ha), [NAT](./modules/net-cloudnat), [address reservation](./modules/net-address), [DNS](./modules/dns), [L4 ILB](./modules/net-ilb), [L7 ILB](./modules/net-ilb-l7), [Service Directory](./modules/service-directory), [Cloud Endpoints](./modules/endpoints)
- **compute** - [VM/VM group](./modules/compute-vm), [MIG](./modules/compute-mig), [GKE cluster](./modules/gke-cluster), [GKE nodepool](./modules/gke-nodepool), [GKE hub](./modules/gke-hub), [COS container](./modules/cloud-config-container/cos-generic-metadata/) (coredns, mysql, onprem, squid)
- **data** - [GCS](./modules/gcs), [BigQuery dataset](./modules/bigquery-dataset), [Pub/Sub](./modules/pubsub), [Datafusion](./modules/datafusion), [Bigtable instance](./modules/bigtable-instance), [Cloud SQL instance](./modules/cloudsql-instance), [Data Catalog Policy Tag](./modules/data-catalog-policy-tag)
- **development** - [Cloud Source Repository](./modules/source-repository), [Container Registry](./modules/container-registry), [Artifact Registry](./modules/artifact-registry), [Apigee Organization](./modules/apigee-organization), [Apigee X Instance](./modules/apigee-x-instance), [API Gateway](./modules/api-gateway)
- **security** - [KMS](./modules/kms), [SecretManager](./modules/secret-manager), [VPC Service Control](./modules/vpc-sc)
- **serverless** - [Cloud Function](./modules/cloud-function), [Cloud Run](./modules/cloud-run)

For more information and usage examples see each module's README file.

## End-to-end blueprints

The [blueprints](./blueprints/) in this repository are split in several main sections: **[networking blueprints](./blueprints/networking/)** that implement core patterns or features, **[data solutions blueprints](./blueprints/data-solutions/)** that demonstrate how to integrate data services in complete scenarios, **[cloud operations blueprints](./blueprints/cloud-operations/)** that leverage specific products to meet specific operational needs and **[factories](./blueprints/factories/)** that implement resource factories for the repetitive creation of specific resources, and finally **[GKE](./blueprints/gke)** and **[serverless](./blueprints/serverless)** design blueprints.
