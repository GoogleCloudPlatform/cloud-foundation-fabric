# GKE Autopilot Cluster Pattern

This blueprint illustrates how to use GKE features to deploy a secure cluster that meets Google's best practices. The cluster deployed by this blueprint can be used to deploy other blueprints such as [Redis](../redis-cluster), [Kafka](../kafka), [Kueue](../batch).

<!-- BEGIN TOC -->
- [Design Decisions](#design-decisions)
- [GKE Onboarding Best Practices](#gke-onboarding-best-practices)
  - [Environment setup](#environment-setup)
  - [Cluster configuration](#cluster-configuration)
  - [Security](#security)
  - [Networking](#networking)
  - [Multitenancy](#multitenancy)
  - [Monitoring](#monitoring)
  - [Maintenance](#maintenance)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design Decisions

The main purpose of this blueprint is to showcase how to use  GKE features to deploy a secure Kubernetes cluster according to Google best practices, including:

- **No public IP addresses** both the control plane and the nodes use private IP addresses. To to simplify the deployment of workloads, we enable [Connect Gateway](https://cloud.google.com/anthos/multicluster-management/gateway) to securely access the control plane even from outside the cluster's VPC. We also use [Remote Repositories](https://cloud.google.com/artifact-registry/docs/repositories/remote-overview) to allow the download of container images by the cluster without requiring Internet egress configured in the clusters's VPC.

- We provide **reasonable but secure defaults** that the user can override. For example, by default we avoid deploying a Cloud NAT gatewayt, but it is possible to enable it with just a few changes to the configuration.

- **Bring your own infrastructure**: that larger organizations might have teams dedicated to the provisioning and management of centralized infrastructure. This blueprint can be deployed to create any required infrastructure (GCP project, VPC, Artifact Registry, etc), or you can leverage existing resources by setting the appropriate variables.

## GKE Onboarding Best Practices

This Terraform blueprint helps you quickly implement most of the [GKE oboarding best practices](https://cloud.google.com/kubernetes-engine/docs/best-practices/onboarding#set-up-terraform) as outlined in the official GKE documentation. In this section we describe the relevant the decisions this blueprint simplifies


### Environment setup
- Set up Terraform: you'll need to install Terraform to use this blueprint. Instructions are [available here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started).
- Terraform state storage: this blueprint doesn't automate this step but can easily be done by specifying a [backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs).
- Create a metrics scope using Terraform: if you're creating a new project with this blueprint, you can enable metrics scope using the `metrics_scope` variable in the `project` module. Otherwise, metrics scope setup occurs outside this blueprint's scope.
- Set up Artifact Registry: by default a remote repository is created to allow downloading container images

### Cluster configuration
This blueprint by default deploys an Autopilot cluster with private nodes and private control plane. By using Autopilot, Google automatically handles node configuration, scaling, and security

- Choose a mode of operation: this blueprint uses Autopilot clusters
- Isolate your cluster: this blueprint deploys a private cluster, with private control plane
- Configure backup for GKE: not configured but can easily be enabled through the `backup_configs` in the `gke-cluster-autopilot` module.
- Use Container-Optimized OS node images: Autopilot cluster always user COS
- Enable node auto-provisioning: automatically managed by Autopilot
- Separate kube-system Pods: automatically managed by Autopilot

### Security
- Use the security posture dashboard: enabled by default in new clusters
- Use group authentication: not needed by this blueprint but can be enabled through the `enable_features.groups_for_rbac` variable of the `gke-cluster-autopilot` module.
- Use RBAC to restrict access to cluster resources: this blueprint deploys the underlying infrastructure, RBAC configuration is out of scope.
- Enable Shielded GKE Nodes: automatically managed by Autopilot
- Enable Workload Identity: automatically managed by Autopilot
- Enable security bulletin notifications: out of scope for this blueprint
- Use least privilege Google service accounts: this blueprint creates a new service account for the cluster
- Restrict network access to the control plane and nodes: this blueprint deploys a private cluster
- Use namespaces to restrict access to cluster resources: this blueprint deploys the underlying infrastructure, namespace handling is left to applications.

### Networking
- Create a custom mode VPC: this blueprint can optinally deploy a new custom VPC with a single subnet. Otherwise, an existing VPC and subnet can be used.
- Create a proxy-only subnet: the `vpc_create` variable allows the creation of proxy only subnet, if needed.
- Configure Shared VPC: by default a new VPC is created within the project, but a Shared VPC can be used when the blueprint handles project creation.
- Connect the cluster's VPC network to an on-premises network: skipped, out of scope for this blueprint
- Enable Cloud NAT: the `vpc_create` variable allows the creation of Cloud NAT, if needed.
- Configure Cloud DNS for GKE: not needed by this blueprint but can be enabled through the `enable_features.dns` variable of the `gke-cluster-autopilot` module.
- Configure NodeLocal DNSCache: not needed by this blueprint
- Create firewall rules: only the default rules created by GKE

### Multitenancy
For simplicity, multi-tenancy is not used in this blueprint.

### Monitoring
- Configure GKE alert policies: out of scope for this blueprint
- Enable Google Cloud Managed Service for Prometheus: automatically managed by Autopilot
- Configure control plane metrics: enabled by default
- Enable metrics packages: out of scope for this blueprint

### Maintenance
- Create environments: out of scope for this blueprint
- Subscribe to Pub/Sub events: out of scope for this blueprint
- Enroll in release channels: the REGULAR channel is used by default
- Configure maintenance windows: not configured but can be enabled through the `maintenance_config` in the `gke-cluster-autopilot` module.
- Set Compute Engine quotas: out of scope for this blueprint
- Configure cost controls: TBD
- Configure billing alerts: out of scope for this blueprint


<!-- ## Usage Examples -->

<!-- ### Existing cluster with local fleet -->

<!-- ```hcl -->
<!-- module "jumpstart-0" { -->
<!--   source       = "./fabric/blueprints/gke/patterns/autopilot-cluster" -->
<!--   project_id   = "tf-playground-svpc-gke-fleet" -->
<!--   cluster_name = "test-00" -->
<!-- } -->
<!-- # tftest skip -->
<!-- ``` -->

<!-- ### New cluster with local fleet, existing VPC -->

<!-- ```hcl -->
<!-- module "jumpstart-0" { -->
<!--   source       = "./fabric/blueprints/gke/patterns/autopilot-cluster" -->
<!--   project_id   = "tf-playground-svpc-gke-fleet" -->
<!--   cluster_name = "test-01" -->
<!--   cluster_create = { -->
<!--     vpc = { -->
<!--       id =        "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0" -->
<!--       subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke" -->
<!--     } -->
<!--   } -->
<!-- } -->
<!-- # tftest skip -->
<!-- ``` -->

<!-- ### New cluster with local fleet, existing default VPC -->

<!-- ```hcl -->
<!-- module "jumpstart-0" { -->
<!--   project_id     = "tf-playground-svpc-gke-fleet" -->
<!--   cluster_name   = "test-01" -->
<!--   cluster_create = {} -->
<!-- } -->
<!-- # tftest skip -->
<!-- ``` -->

<!-- ### New cluster and VPC, implied cluster VPC -->

<!-- ```hcl -->
<!-- module "jumpstart-0" { -->
<!--   source       = "./fabric/blueprints/gke/patterns/autopilot-cluster" -->
<!--   project_id     = "tf-playground-svpc-gke-fleet" -->
<!--   cluster_name   = "test-01" -->
<!--   cluster_create = {} -->
<!--   vpc_create     = {} -->
<!-- } -->
<!-- # tftest skip -->
<!-- ``` -->

<!-- ### New cluster and project, default VPC (fails) -->

<!-- ```hcl -->
<!-- module "jumpstart-0" { -->
<!--   source       = "./fabric/blueprints/gke/patterns/autopilot-cluster" -->
<!--   project_id     = "tf-playground-svpc-gke-j0" -->
<!--   cluster_name   = "test-00" -->
<!--   cluster_create = {} -->
<!--   project_create = { -->
<!--     billing_account = "017479-47ADAB-670295" -->
<!--     parent-gke-j1" -->
<!--   cluster_name   = "test-00" -->
<!--   cluster_create = {} -->
<!--   project_create = { -->
<!--     billing_account = "017479-47ADAB-670295" -->
<!--     parent          = "folders/210938489642" -->
<!--     shared_vpc_host = "ldj-prod-net-landing-0" -->
<!--   } -->
<!-- } -->
<!-- # tftest skip -->
<!-- ``` -->

<!-- ### New cluster and project, service project passes VPC check -->

<!-- ```hcl -->
<!-- module "jumpstart-0" { -->
<!--   source       = "./fabric/blueprints/gke/patterns/autopilot-cluster" -->
<!--   project_id   = "tf-playground-svpc-gke-j1" -->
<!--   cluster_name = "test-00" -->
<!--   cluster_create = { -->
<!--     vpc = { -->
<!--       id        = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0" -->
<!--       subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke" -->
<!--     } -->
<!--   } -->
<!--   project_create = { -->
<!--     billing_account = "017479-47ADAB-670295" -->
<!--     parent          = "folders/210938489642" -->
<!--     shared_vpc_host = "ldj-dev-net-spoke-0" -->
<!--   } -->
<!-- } -->
<!-- # tftest skip -->
<!-- ``` -->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L# GKE Autopilot Cluster Pattern

This blueprint illustrates how to use GKE features to deploy a secure cluster that meets Google's best practices. The cluster deployed by this blueprint can be used to deploy other blueprints such as [Redis](../redis-cluster), [Kafka](../kafka), [MySQL](../mysql), [Kueue](../batch).

<!-- BEGIN TOC -->
- [Design Decisions](#design-decisions)
- [GKE Onboarding Best Practices](#gke-onboarding-best-practices)
  - [Environment setup](#environment-setup)
  - [Cluster configuration](#cluster-configuration)
  - [Security](#security)
  - [Networking](#networking)
  - [Multitenancy](#multitenancy)
  - [Monitoring](#monitoring)
  - [Maintenance](#maintenance)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design Decisions

The main purpose of this blueprint is to showcase how to use  GKE features to deploy a secure Kubernetes cluster according to Google best practices, including:

- **No public IP addresses** both the control plane and the nodes use private IP addresses. To to simplify the deployment of workloads, we enable [Connect Gateway](https://cloud.google.com/anthos/multicluster-management/gateway) to securely access the control plane even from outside the cluster's VPC. We also use [Remote Repositories](https://cloud.google.com/artifact-registry/docs/repositories/remote-overview) to allow the download of container images by the cluster without requiring Internet egress configured in the clusters's VPC.

- We provide **reasonable but secure defaults** that the user can override. For example, by default we avoid deploying a Cloud NAT gatewayt, but it is possible to enable it with just a few changes to the configuration.

- **Bring your own infrastructure**: that larger organizations might have teams dedicated to the provisioning and management of centralized infrastructure. This blueprint can be deployed to create any required infrastructure (GCP project, VPC, Artifact Registry, etc), or you can leverage existing resources by setting the appropriate variables.

## GKE Onboarding Best Practices

This Terraform blueprint helps you quickly implement most of the [GKE oboarding best practices](https://cloud.google.com/kubernetes-engine/docs/best-practices/onboarding#set-up-terraform) as outlined in the official GKE documentation. In this section we describe the relevant the decisions this blueprint simplifies


### Environment setup
- Set up Terraform: you'll need to install Terraform to use this blueprint. Instructions are [available here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started).
- Terraform state storage: this blueprint doesn't automate this step but can easily be done by specifying a [backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs).
- Create a metrics scope using Terraform: if you're creating a new project with this blueprint, you can enable metrics scope using the `metrics_scope` variable in the `project` module. Otherwise, metrics scope setup occurs outside this blueprint's scope.
- Set up Artifact Registry: by default a remote repository is created to allow downloading container images

### Cluster configuration
This blueprint by default deploys an Autopilot cluster with private nodes and private control plane. By using Autopilot, Google automatically handles node configuration, scaling, and security

- Choose a mode of operation: this blueprint uses Autopilot clusters
- Isolate your cluster: this blueprint deploys a private cluster, with private control plane
- Configure backup for GKE: not configured but can easily be enabled through the `backup_configs` in the `gke-cluster-autopilot` module.
- Use Container-Optimized OS node images: Autopilot cluster always user COS
- Enable node auto-provisioning: aut. |  |
<!-- END TFDOC -->
