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

    ```terraform
    module "project" {
        source              = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v13.0.0"
        name                = "my-project"
        billing_account     = "123456-123456-123456"
        parent              = "organizations/123456"
    }
    ```

## Foundational modules

- [billing budget](./billing-budget)
- [Cloud Identity group](./cloud-identity-group/)
- [folder](./folder)
- [service accounts](./iam-service-account)
- [logging bucket](./logging-bucket)
- [organization](./organization)
- [project](./project)
- [projects-data-source](./projects-data-source)

## Networking modules

- [Address reservation](./net-address)
- [Cloud Endpoints](./endpoints)
- [DNS](./dns)
- [DNS Response Policy](./dns-response-policy/)
- [Firewall policy](./net-firewall-policy)
- [External Application Load Balancer](./net-lb-app-ext/)
- [External Passthrough Network Load Balancer](./net-lb-ext)
- [Internal Application Load Balancer](./net-lb-app-int)
- [Internal Passthrough Network Load Balancer](./net-lb-int)
- [Internal Proxy Network Load Balancer](./net-lb-proxy-int)
- [Internal ]
- [NAT](./net-cloudnat)
- [Service Directory](./service-directory)
- [VPC](./net-vpc)
- [VPC firewall](./net-vpc-firewall)
- [VPN dynamic](./net-vpn-dynamic)
- [VPC peering](./net-vpc-peering)
- [VPN HA](./net-vpn-ha)
- [VPN static](./net-vpn-static)

## Compute/Container

- [VM/VM group](./compute-vm)
- [MIG](./compute-mig)
- [COS container](./cloud-config-container/cos-generic-metadata/) (coredns/mysql/nva/onprem/squid)
- [GKE autopilot cluster](./gke-cluster-autopilot)
- [GKE standard cluster](./gke-cluster-standard)
- [GKE hub](./gke-hub)
- [GKE nodepool](./gke-nodepool)
- [GCVE private cloud](./gcve-private-cloud)

## Data

<!-- - [AlloyDB instance](./alloydb-instance)-->
- [BigQuery dataset](./bigquery-dataset)
- [Bigtable instance](./bigtable-instance)
- [Dataplex](./dataplex)
- [Dataplex DataScan](./dataplex-datascan/)
- [Cloud SQL instance](./cloudsql-instance)
- [Data Catalog Policy Tag](./data-catalog-policy-tag)
- [Datafusion](./datafusion)
- [Dataproc](./dataproc)
- [GCS](./gcs)
- [Pub/Sub](./pubsub)

## Development

- [API Gateway](./api-gateway)
- [Apigee](./apigee)
- [Artifact Registry](./artifact-registry)
- [Container Registry](./container-registry)
- [Cloud Source Repository](./source-repository)

## Security

- [Binauthz](./binauthz/)
- [KMS](./kms)
- [SecretManager](./secret-manager)
- [VPC Service Control](./vpc-sc)
- [Secure Web Proxy](./net-swp)

## Serverless

- [Cloud Functions v1](./cloud-function-v1)
- [Cloud Functions v2](./cloud-function-v2)
- [Cloud Run](./cloud-run)
