# Terraform modules suite for Google Cloud

The modules collected in this folder are designed as a suite: they are meant to be composed together, and are designed to be forked and modified where use of third party code and sources is not allowed.

Modules try to stay close to the low level provider resources they encapsulate, and they all share a similar interface that combines management of one resource or set or resources, and the corresponding IAM bindings.

Authoritative IAM bindings are primarily used (e.g. `google_storage_bucket_iam_binding` for GCS buckets) so that each module is authoritative for specific roles on the resources it manages, and can neutralize or reconcile IAM changes made elsewhere.

Specific modules also offer support for non-authoritative bindings (e.g. `google_storage_bucket_iam_member` for service accounts), to allow granular permission management on resources that they don't manage directly.

## Foundational modules

- [folders](./modules/folders)
- [log sinks](./modules/logging-sinks)
- [organization](./modules/organization)
- [project](./modules/project)
- [service accounts](./modules/iam-service-accounts)

## Networking modules

- [address reservation](./modules/net-address)
- [Cloud DNS](./modules/dns)
- [Cloud NAT](./modules/net-cloudnat)
- [VPC](./modules/net-vpc)
- [VPC firewall](./modules/net-vpc-firewall)
- [VPC peering](./modules/net-vpc-peering)
- [VPN static](./modules/net-vpn-static)
- [VPN dynamic](./modules/net-vpn-dynamic)
- [VPN HA](./modules/net-vpn-ha))
- [ ] TODO: xLB modules

## Compute/Container

- [COS container](./modules/cos-container) (coredns, mysql, onprem)
- [GKE cluster](./modules/gke-cluster)
- [GKE nodepool](./modules/gke-nodepool)
- [VM/VM group](./modules/compute-vm)

## Data

- [BigQuery dataset](./modules/bigquery)
- [GCS](./modules/gcs)

## Security

- [Cloud KMS](./modules/kms)
