# Terraform modules suite for Google Cloud

The modules collected in this folder are designed as a suite: they are meant to be composed together, and are designed to be forked and modified where use of third party code and sources is not allowed.

Modules try to stay close to the low level provider resources they encapsulate, and they all share a similar interface that combines management of one resource or set or resources, and the corresponding IAM bindings.

Authoritative IAM bindings are primarily used (e.g. `google_storage_bucket_iam_binding` for GCS buckets) so that each module is authoritative for specific roles on the resources it manages, and can neutralize or reconcile IAM changes made elsewhere.

Specific modules also offer support for non-authoritative bindings (e.g. `google_storage_bucket_iam_member` for service accounts), to allow granular permission management on resources that they don't manage directly.

These modules are not necessarily backward compatible. Actually, whenever there is a major release, one or more modules have experienced a non-backward compatible change. This means that if you upgrade the version of one of the modules in an existing Terraform configuration, things might stop working. As backward compatibility is not guaranteed, we recommend you to only upgrade a module's version, if the new version provides functionality not existing in the version you are using. If the version you are using, does what you need, refrain from upgrading. 

These modules are used in the examples included in this repository. If you are using any of those examples in your own Terraform configuration, make sure that you are using the same version for all the modules.

The recommended approach to work with these modules is the following one:

* Fork the repository and own the fork. This will allow you to:

    - Evolve the existing modules.
    - Create your own modules.
    - Sync from the upstream repository to get all the updates.

* Use git refs to reference the modules in your fork. See an example below:

    ```
    module "project" {
        source              = "github.com/my-fork/cloud-foundation-fabric.git//modules/project?ref=v12.0.0"
        name                = "my-project"
        billing_account     = "123456-123456-123456"
        parent              = "organizations/123456"
    }
    ```

## Foundational modules

- [billing budget](./billing-budget)
- [folder](./folder)
- [logging bucket](./logging-bucket)
- [naming convention](./naming-convention)
- [organization](./organization)
- [project](./project)
- [service account](./iam-service-account)

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

- [COS container](./cloud-config-container/onprem/) (coredns, mysql, onprem, squid)
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
- [Cloud SQL instance](./cloudsql-instance)

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
- [Cloud Run](./cloud-run)
