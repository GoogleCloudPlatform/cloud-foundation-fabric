# Terraform modules suite for Google Cloud

The modules collected in this folder are designed as a suite: they are meant to be composed together, and are designed to be forked and modified where use of third party code and sources is not allowed.

Modules try to stay close to the low level provider resources they encapsulate, and they all share a similar interface that combines management of one resource or set or resources, and the corresponding IAM bindings.

Authoritative IAM bindings are primarily used (e.g. `google_storage_bucket_iam_binding` for GCS buckets) so that each module is authoritative for specific roles on the resources it manages, and can neutralize or reconcile IAM changes made elsewhere.

Specific modules also offer support for non-authoritative bindings (e.g. `google_storage_bucket_iam_member` for service accounts), to allow granular permission management on resources that they don't manage directly.

These modules are not necessarily backward compatible. Changes breaking compatibility in modules are marked by major releases (but not all major releases contain breaking changes). Please be mindful when upgrading Fabric modules in existing Terraform setups, and always try to use versioned references in module sources so you can easily revert back to a previous version. Since the introduction of the `moved` block in Terraform we try to use it whenever possible to make updates non-breaking, but that does not cover all changes we might need to make.

These modules are used in the examples included in this repository. If you are using any of those examples in your own Terraform configuration, make sure that you are using the same version for all the modules, and switch module sources to GitHub format using references. The recommended approach to working with Fabric modules is the following:

- Fork the repository and own the fork. This will allow you to:
    - Evolve the existing modules.
    - Create your own modules.
    - Sync from the upstream repository to get all the updates.
 
- Use GitHub sources with refs to reference the modules. See an example below:
    ```
    module "project" {
        source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v13.0.0"
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
- [projects-data-source](./projects-data-source)
- [service account](./iam-service-account)
- [organization policy](./organization-policy)

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
- [HA VPN](./net-vpn-ha)
- [ ] TODO: xLB modules

## Compute/Container

- [COS container](./cloud-config-container/onprem/) (coredns, mysql, onprem, squid)
- [GKE cluster](./gke-cluster)
- [GKE nodepool](./gke-nodepool)
- [GKE hub](./gke-hub)
- [Managed Instance Group](./compute-mig)
- [VM/VM group](./compute-vm)

## Data

- [BigQuery dataset](./bigquery-dataset)
- [Datafusion](./datafusion)
- [GCS](./gcs)
- [Pub/Sub](./pubsub)
- [Bigtable instance](./bigtable-instance)
- [Cloud SQL instance](./cloudsql-instance)
- [Data Catalog Policy Tag](./data-catalog-policy-tag)

## Development

- [Artifact Registry](./artifact-registry)
- [Container Registry](./container-registry)
- [Source Repository](./source-repository)
- [Apigee Organization](./apigee-organization)
- [Apigee X Instance](./apigee-x-instance)
- [API Gateway](./api-gateway)

## Security

- [Cloud KMS](./kms)
- [Secret Manager](./secret-manager)
- [VPC Service Control](./vpc-sc)

## Serverless

- [Cloud Functions](./cloud-function)
- [Cloud Run](./cloud-run)
