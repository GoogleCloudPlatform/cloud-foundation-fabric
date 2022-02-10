# Terraform end-to-end examples for Google Cloud

This section contains **[foundational examples](./foundations/)** that bootstrap the organizational hierarchy and automation prerequisites, **[networking examples](./networking/)** that implement core patterns or features, **[data solutions examples](./data-solutions/)** that demonstrate how to integrate data services in complete scenarios, **[cloud operations examples](./cloud-operations/)** that leverage specific products to meet specific operational needs and **[factories](./factories/)** that implement resource factories for the repetitive creation of specific resources.

Currently available examples:

- **cloud operations** - [Resource tracking and remediation via Cloud Asset feeds](./cloud-operations/asset-inventory-feed-remediation), [Granular Cloud DNS IAM via Service Directory](./cloud-operations/dns-fine-grained-iam), [Granular Cloud DNS IAM for Shared VPC](./cloud-operations/dns-shared-vpc), [Compute Engine quota monitoring](./cloud-operations/quota-monitoring), [Scheduled Cloud Asset Inventory Export to Bigquery](./cloud-operations/scheduled-asset-inventory-export-bq), [Packer image builder](./cloud-operations/packer-image-builder), [On-prem SA key management](./cloud-operations/onprem-sa-key-management)
- **data solutions** - [GCE/GCS CMEK via centralized Cloud KMS](./data-solutions/gcs-to-bq-with-least-privileges/), [Cloud Storage to Bigquery with Cloud Dataflow with least privileges](./data-solutions/gcs-to-bq-with-least-privileges/), [Data Platform Foundations](./data-solutions/data-platform-foundations/)
- **factories** - [The why and the how of resource factories](./factories/README.md)
- **foundations** - [single level hierarchy](./foundations/environments/) (environments), [multiple level hierarchy](./foundations/business-units/) (business units + environments)
- **networking** - [hub and spoke via peering](./networking/hub-and-spoke-peering/), [hub and spoke via VPN](./networking/hub-and-spoke-vpn/), [DNS and Google Private Access for on-premises](./networking/onprem-google-access-dns/), [Shared VPC with GKE support](./networking/shared-vpc-gke/), [ILB as next hop](./networking/ilb-next-hop), [PSC for on-premises Cloud Function invocation](./networking/private-cloud-function-from-onprem/), [decentralized firewall](./networking/decentralized-firewall)
- **third party solutions** - [OpenShift cluster on Shared VPC](./third-party-solutions/openshift)

For more information see the README files in the [foundations](./foundations/), [networking](./networking/), [data solutions](./data-solutions/), [cloud operations](./cloud-operations/) and [factories](./factories/) folders.
