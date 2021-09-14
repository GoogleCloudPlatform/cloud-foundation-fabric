# Terraform modules suite for Google Cloud

The modules collected in this folder are designed as a suite: they are meant to be composed together, and are designed to be forked and modified where use of third party code and sources is not allowed.

Modules try to stay close to the low level provider resources they encapsulate, and they all share a similar interface that combines management of one resource or set or resources, and the corresponding IAM bindings.

Authoritative IAM bindings are primarily used (e.g. `google_storage_bucket_iam_binding` for GCS buckets) so that each module is authoritative for specific roles on the resources it manages, and can neutralize or reconcile IAM changes made elsewhere.

Specific modules also offer support for non-authoritative bindings (e.g. `google_storage_bucket_iam_member` for service accounts), to allow granular permission management on resources that they don't manage directly.

## Foundational modules

- [folder](./folder)
- [organization](./organization)
- [project](./project)
- [service account](./iam-service-account)
- [logging bucket](./logging-bucket)

## Networking modules

- [address reservation](./net-address)
- [Cloud DNS](./dns)
- [Cloud NAT](./net-cloudnat)
- [Cloud Endpoints](./endpoints)
- [L4 Internal Load Balancer](./net-ilb)
- [Service Directory](./service-directory)
- [VPC](./net-vpc)
- [VPC firewall](./net-vpc-firewall)
- [VPC peering](./net-vpc-peering)
- [VPN static](./net-vpn-static)
- [VPN dynamic](./net-vpn-dynamic)
- [VPN HA](./net-vpn-ha)
- [ ] TODO: xLB modules

## Compute/Container

- [COS container](./cos-container) (coredns, mysql, onprem, squid)
- [GKE cluster](./gke-cluster)
- [GKE nodepool](./gke-nodepool)
- [Managed Instance Group](./compute-mig)
- [VM/VM group](./compute-vm)

## Data

- [BigQuery dataset](./bigquery-dataset)
- [Datafusion](./datafusion)
- [GCS](./gcs)
- [Pub/Sub](./pubsub)
- [Bigtable instance](./bigtable-instance)

## Development

- [Artifact Registry](./artifact-registry)
- [Container Registry](./container-registry)
- [Source Repository](./source-repository)
- [Apigee Organization](./apigee-organization)
- [Apigee X Instance](./apigee-x-instance)

## Security

- [Cloud KMS](./kms)
- [Secret Manager](./secret-manager)
- [VPC Service Control](./vpc-sc)

## Serverless

- [Cloud Functions](./cloud-function)
