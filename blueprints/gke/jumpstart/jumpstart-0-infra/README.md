# GKE Jumpstart Infrastructure

<!-- BEGIN TOC -->
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
  create_cluster = {
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
  create_cluster = {}
}
# tftest skip
```

### New cluster and VPC, implied cluster VPC

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-fleet"
  cluster_name   = "test-01"
  create_cluster = {}
  create_vpc     = {}
}
# tftest skip
```

### New cluster and project, default VPC (fails)

```hcl
module "jumpstart-0" {
  project_id     = "tf-playground-svpc-gke-j0"
  cluster_name   = "test-00"
  create_cluster = {}
  create_project = {
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
  create_cluster = {}
  create_project = {
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
  create_cluster = {}
  create_project = {
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
  create_cluster = {
    vpc = {
      id        = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
      subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
    }
  }
  create_project = {
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
| [cluster_name](variables.tf#L65) | Name of new or existing cluster. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L85) | Project id of existing or created project. | <code>string</code> | ✓ |  |
| [create_cluster](variables.tf#L17) | Cluster configuration for newly created cluster. Set to null to use existing cluster, or create using defaults in new project. | <code title="object&#40;&#123;&#10;  labels &#61; optional&#40;map&#40;string&#41;&#41;&#10;  master_authorized_ranges &#61; optional&#40;map&#40;string&#41;, &#123;&#10;    rfc-1918-10-8 &#61; &#34;10.0.0.0&#47;8&#34;&#10;  &#125;&#41;&#10;  master_ipv4_cidr_block &#61; optional&#40;string, &#34;172.16.255.0&#47;28&#34;&#41;&#10;  vpc &#61; optional&#40;object&#40;&#123;&#10;    id        &#61; string&#10;    subnet_id &#61; string&#10;    secondary_range_names &#61; optional&#40;object&#40;&#123;&#10;      pods     &#61; optional&#40;string, &#34;pods&#34;&#41;&#10;      services &#61; optional&#40;string, &#34;services&#34;&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [create_project](variables.tf#L37) | Project configuration for newly created project. Leave null to use existing project. Project creation forces VPC and cluster creation. | <code title="object&#40;&#123;&#10;  billing_account &#61; string&#10;  parent          &#61; optional&#40;string&#41;&#10;  shared_vpc_host &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [create_registry](variables.tf#L47) | Create remote Docker Artifact Registry. | <code>bool</code> |  | <code>true</code> |
| [create_vpc](variables.tf#L53) | Project configuration for newly created VPC. Leave null to use existing VPC, or defaults when project creation is required. | <code title="object&#40;&#123;&#10;  name                     &#61; optional&#40;string&#41;&#10;  subnet_name              &#61; optional&#40;string&#41;&#10;  primary_range_nodes      &#61; optional&#40;string, &#34;10.0.0.0&#47;24&#34;&#41;&#10;  secondary_range_pods     &#61; optional&#40;string, &#34;10.16.0.0&#47;20&#34;&#41;&#10;  secondary_range_services &#61; optional&#40;string, &#34;10.32.0.0&#47;24&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [fleet_project_id](variables.tf#L72) | GKE Fleet project id. If null cluster project will also be used for fleet. | <code>string</code> |  | <code>null</code> |
| [prefix](variables.tf#L78) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;jump-0&#34;</code> |
| [region](variables.tf#L90) | Region used for cluster and network resources. | <code>string</code> |  | <code>&#34;europe-west8&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cmd_get_credentials](outputs.tf#L17) | Run this command to get cluster credentials via fleet. |  |
| [foo](outputs.tf#L25) |  |  |
<!-- END TFDOC -->
