# GKE Jumpstart Infrastructure

This blueprint illustrates how to use GKE features to deploy a secure cluster that meets Google's best practices. The cluster deployed by this blueprint can be used to deploy specific the workloads other blueprints such as Redis, Kafka, PostgreSQL, etc.

<!-- BEGIN TOC -->
- [Design Decisions](#design-decisions)
- [Examples](#examples)
  - [Existing cluster with local fleet](#existing-cluster-with-local-fleet)
  - [New cluster with local fleet, existing VPC](#new-cluster-with-local-fleet-existing-vpc)
  - [New cluster with local fleet, existing default VPC](#new-cluster-with-local-fleet-existing-default-vpc)
  - [New cluster and VPC, implied cluster VPC](#new-cluster-and-vpc-implied-cluster-vpc)
  - [New cluster and project, default VPC (fails)](#new-cluster-and-project-default-vpc-fails)
  - [New cluster and project, implied VPC creation and cluster VPC](#new-cluster-and-project-implied-vpc-creation-and-cluster-vpc)
  - [New cluster and project, service project fails VPC check](#new-cluster-and-project-service-project-fails-vpc-check)
  - [New cluster and project, service project passes VPC check](#new-cluster-and-project-service-project-passes-vpc-check)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design Decisions

The main purpose of this blueprint is to showcase how to use  GKE features to deploy a secure Cabernet's cluster according to Google best practices.

- **No public IP addresses** both the control plane and the nodes use private IP addresses. To to simplify the deployment of workloads, we enable Connect gateway to securely access the control plane even from outside the cluster's VPC. We also use Remote Repositories to allow the download of container images by the cluster.

- We provide **reasonable but secure defaults** that the user can override. For example, we prefer GKE Autopilot by default, but it is also possible to deply a GKE Standard cluster with just a few changes.

- **Bring your own infrastructure**: we understand that larger organizations have teams dedicated to the provisioning and management of centralized infrastructure. This blueprint allows you to deploy your own supporting infrastructure (GCP project, VPC, Artifact Registry, etc), or you can leverage existing resources by setting the appropriate variables.


## Examples

### Existing cluster with local fleet

```hcl
module "jumpstart-0" {
  source       = "./fabric/blueprints/gke/jumpstart/jumpstart-0-infra/"
  project_id   = "tf-playground-svpc-gke-fleet"
  cluster_name = "test-00"
}
# tftest skip
```

### New cluster with local fleet, existing VPC

```hcl
module "jumpstart-0" {
  source       = "./fabric/blueprints/gke/jumpstart/jumpstart-0-infra/"
  project_id   = "tf-playground-svpc-gke-fleet"
  cluster_name = "test-01"
  cluster_create = {
    vpc = {
      id =        "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
      subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
    }
  }
}
# tftest skip
```

### New cluster with local fleet, existing default VPC

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-fleet"
  cluster_name   = "test-01"
  cluster_create = {}
}
# tftest skip
```

### New cluster and VPC, implied cluster VPC

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-fleet"
  cluster_name   = "test-01"
  cluster_create = {}
  vpc_create     = {}
}
# tftest skip
```

### New cluster and project, default VPC (fails)

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-j0"
  cluster_name   = "test-00"
  cluster_create = {}
  project_create = {
    billing_account = "017479-47ADAB-670295"
    parent          = "folders/210938489642"
  }
}
# tftest skip
```

### New cluster and project, implied VPC creation and cluster VPC

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-j0"
  cluster_name   = "test-00"
  cluster_create = {}
  project_create = {
    billing_account = "017479-47ADAB-670295"
    parent          = "folders/210938489642"
  }
}
# tftest skip
```

### New cluster and project, service project fails VPC check

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-j1"
  cluster_name   = "test-00"
  cluster_create = {}
  project_create = {
    billing_account = "017479-47ADAB-670295"
    parent          = "folders/210938489642"
    shared_vpc_host = "ldj-prod-net-landing-0"
  }
}
# tftest skip
```

### New cluster and project, service project passes VPC check

```hcl
module "jumpstart-0" {
  project_id   = "tf-playground-svpc-gke-j1"
  cluster_name = "test-00"
  cluster_create = {
    vpc = {
      id        = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
      subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
    }
  }
  project_create = {
    billing_account = "017479-47ADAB-670295"
    parent          = "folders/210938489642"
    shared_vpc_host = "ldj-dev-net-spoke-0"
  }
}
# tftest skip
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cluster_name](variables.tf#L71) | Name of new or existing cluster. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L91) | Project id of existing or created project. | <code>string</code> | ✓ |  |
| [cluster_create](variables.tf#L17) | Cluster configuration for newly created cluster. Set to null to use existing cluster, or create using defaults in new project. | <code title="object&#40;&#123;&#10;  labels &#61; optional&#40;map&#40;string&#41;&#41;&#10;  master_authorized_ranges &#61; optional&#40;map&#40;string&#41;, &#123;&#10;    rfc-1918-10-8 &#61; &#34;10.0.0.0&#47;8&#34;&#10;  &#125;&#41;&#10;  master_ipv4_cidr_block &#61; optional&#40;string, &#34;172.16.255.0&#47;28&#34;&#41;&#10;  vpc &#61; optional&#40;object&#40;&#123;&#10;    id        &#61; string&#10;    subnet_id &#61; string&#10;    secondary_range_names &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; optional&#40;string, &#34;pods&#34;&#41;&#10;      services &#61; optional&#40;string, &#34;services&#34;&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;  options &#61; optional&#40;object&#40;&#123;&#10;    release_channel     &#61; optional&#40;string, &#34;REGULAR&#34;&#41;&#10;    enable_backup_agent &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [fleet_project_id](variables.tf#L78) | GKE Fleet project id. If null cluster project will also be used for fleet. | <code>string</code> |  | <code>null</code> |
| [prefix](variables.tf#L84) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;jump-0&#34;</code> |
| [project_create](variables.tf#L41) | Project configuration for newly created project. Leave null to use existing project. Project creation forces VPC and cluster creation. | <code title="object&#40;&#123;&#10;  billing_account &#61; string&#10;  parent          &#61; optional&#40;string&#41;&#10;  shared_vpc_host &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [region](variables.tf#L96) | Region used for cluster and network resources. | <code>string</code> |  | <code>&#34;europe-west8&#34;</code> |
| [registry_create](variables.tf#L51) | Create remote Docker Artifact Registry. | <code>bool</code> |  | <code>true</code> |
| [vpc_create](variables.tf#L57) | Project configuration for newly created VPC. Leave null to use existing VPC, or defaults when project creation is required. | <code title="object&#40;&#123;&#10;  name                     &#61; optional&#40;string&#41;&#10;  subnet_name              &#61; optional&#40;string&#41;&#10;  primary_range_nodes      &#61; optional&#40;string, &#34;10.0.0.0&#47;24&#34;&#41;&#10;  secondary_range_pods     &#61; optional&#40;string, &#34;10.16.0.0&#47;20&#34;&#41;&#10;  secondary_range_services &#61; optional&#40;string, &#34;10.32.0.0&#47;24&#34;&#41;&#10;  enable_cloud_nat         &#61; optional&#40;bool, false&#41;&#10;  proxy_only_subnet        &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [created_resources](outputs.tf#L17) | IDs of the resources created, if any. |  |
| [fleet_host](outputs.tf#L44) | Fleet Connect Gateway host that can be used to configure the GKE provider. |  |
| [get_credentials](outputs.tf#L53) | Run one of these commands to get cluster credentials. Credentials via fleet allow reaching private clusters without no direct connectivity. |  |
<!-- END TFDOC -->
