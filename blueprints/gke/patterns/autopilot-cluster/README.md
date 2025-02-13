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
- Create a custom mode VPC: this blueprint can optionally deploy a new custom VPC with a single subnet. Otherwise, an existing VPC and subnet can be used.
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
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L42) | Name of new or existing cluster. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L70) | Project id of existing or created project. | <code>string</code> | ✓ |  |
| [region](variables.tf#L75) | Region used for cluster and network resources. | <code>string</code> | ✓ |  |
| [cluster_create](variables.tf#L17) | Cluster configuration for newly created cluster. Set to null to use existing cluster, or create using defaults in new project. | <code title="object&#40;&#123;&#10;  deletion_protection &#61; optional&#40;bool, true&#41;&#10;  labels              &#61; optional&#40;map&#40;string&#41;&#41;&#10;  master_authorized_ranges &#61; optional&#40;map&#40;string&#41;, &#123;&#10;    rfc-1918-10-8 &#61; &#34;10.0.0.0&#47;8&#34;&#10;  &#125;&#41;&#10;  master_ipv4_cidr_block &#61; optional&#40;string, &#34;172.16.255.0&#47;28&#34;&#41;&#10;  vpc &#61; optional&#40;object&#40;&#123;&#10;    id        &#61; string&#10;    subnet_id &#61; string&#10;    secondary_range_names &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; optional&#40;string, &#34;pods&#34;&#41;&#10;      services &#61; optional&#40;string, &#34;services&#34;&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  options &#61; optional&#40;object&#40;&#123;&#10;    release_channel     &#61; optional&#40;string, &#34;REGULAR&#34;&#41;&#10;    enable_backup_agent &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [fleet_project_id](variables.tf#L47) | GKE Fleet project id. If null cluster project will also be used for fleet. | <code>string</code> |  | <code>null</code> |
| [prefix](variables.tf#L53) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;jump-0&#34;</code> |
| [project_create](variables.tf#L60) | Project configuration for newly created project. Leave null to use existing project. Project creation forces VPC and cluster creation. | <code title="object&#40;&#123;&#10;  billing_account &#61; string&#10;  parent          &#61; optional&#40;string&#41;&#10;  shared_vpc_host &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [registry_create](variables.tf#L80) | Create remote Docker Artifact Registry. | <code>bool</code> |  | <code>true</code> |
| [vpc_create](variables.tf#L86) | Project configuration for newly created VPC. Leave null to use existing VPC, or defaults when project creation is required. | <code title="object&#40;&#123;&#10;  name                     &#61; optional&#40;string&#41;&#10;  subnet_name              &#61; optional&#40;string&#41;&#10;  primary_range_nodes      &#61; optional&#40;string, &#34;10.0.0.0&#47;24&#34;&#41;&#10;  secondary_range_pods     &#61; optional&#40;string, &#34;10.16.0.0&#47;20&#34;&#41;&#10;  secondary_range_services &#61; optional&#40;string, &#34;10.32.0.0&#47;24&#34;&#41;&#10;  enable_cloud_nat         &#61; optional&#40;bool, false&#41;&#10;  proxy_only_subnet        &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [created_resources](outputs.tf#L17) | IDs of the resources created, if any. |  |
| [credentials_config](outputs.tf#L44) | Configure how Terraform authenticates to the cluster. |  |
| [fleet_host](outputs.tf#L51) | Fleet Connect Gateway host that can be used to configure the GKE provider. |  |
| [get_credentials](outputs.tf#L56) | Run one of these commands to get cluster credentials. Credentials via fleet allow reaching private clusters without no direct connectivity. |  |
| [region](outputs.tf#L70) | Region used for cluster and network resources. |  |
<!-- END TFDOC -->
