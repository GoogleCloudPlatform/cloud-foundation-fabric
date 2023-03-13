# MLOps with Vertex AI

## Introduction

This example implements the infrastructure required to deploy an end-to-end [MLOps process](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf) using [Vertex AI](https://cloud.google.com/vertex-ai) platform.

## GCP resources

The blueprint will deploy all the required resources to have a fully functional MLOPs environment containing:

- Vertex Workbench (for the experimentation environment)
- GCP Project (optional) to host all the resources
- Isolated VPC network and a subnet to be used by Vertex and Dataflow. Alternatively, an external Shared VPC can be configured using the `network_config`variable.
- Firewall rule to allow the internal subnet communication required by Dataflow
- Cloud NAT required to reach the internet from the different computing resources (Vertex and Dataflow)
- GCS buckets to host Vertex AI and Cloud Build Artifacts. By default the buckets will be regional and should match the Vertex AI region for the different resources (i.e. Vertex Managed Dataset) and processes (i.e. Vertex trainining)
- BigQuery Dataset where the training data will be stored. This is optional, since the training data could be already hosted in an existing BigQuery dataset.
- Artifact Registry Docker repository to host the custom images.
- Service account (`mlops-[env]@`) with the minimum permissions required by Vertex AI and Dataflow (if this service is used inside of the Vertex AI Pipeline).
- Service account (`github@`) to be used by Workload Identity Federation, to federate Github identity (Optional).
- Secret to store the Github SSH key to get access the CICD code repo.

![MLOps project description](./images/mlops_projects.png "MLOps project description")

## Pre-requirements

### User groups

Assign roles relying on User groups is a way to decouple the final set of permissions from the stage where entities and resources are created, and their IAM bindings defined. You can configure the group names through the `groups` variable. These groups should be created before launching Terraform.

We use the following groups to control access to resources:

- *Data Scientits* (gcp-ml-ds@<company.org>). They manage notebooks and create ML pipelines.
- *ML Engineers* (gcp-ml-eng@<company.org>). They manage the different Vertex resources.
- *ML Viewer* (gcp-ml-eng@<company.org>). Group with wiewer permission for the different resources.

Please note that these groups are not suitable for production grade environments. Roles can be customized in the `main.tf`file.

## Instructions

### Deploy the experimentation environment

- Create a `terraform.tfvars` file and specify the variables to match your desired configuration. You can use the provided `terraform.tfvars.sample`  as reference.
- Run `terraform init` and `terraform apply`

## What's next?

This blueprint can be used as a building block for setting up an end2end ML Ops solution. As next step, you can follow this [guide](https://cloud.google.com/architecture/architecture-for-mlops-using-tfx-kubeflow-pipelines-and-cloud-build) to setup a Vertex AI pipeline and run it on the deployed infraestructure.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L101) | Project id, references existing project if `project_create` is null. | <code>string</code> | ✓ |  |
| [bucket_name](variables.tf#L18) | GCS bucket name to store the Vertex AI artifacts. | <code>string</code> |  | <code>null</code> |
| [dataset_name](variables.tf#L24) | BigQuery Dataset to store the training data. | <code>string</code> |  | <code>null</code> |
| [groups](variables.tf#L30) | Name of the groups (name@domain.org) to apply opinionated IAM permissions. | <code title="object&#40;&#123;&#10;  gcp-ml-ds     &#61; string&#10;  gcp-ml-eng    &#61; string&#10;  gcp-ml-viewer &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  gcp-ml-ds     &#61; null&#10;  gcp-ml-eng    &#61; null&#10;  gcp-ml-viewer &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [identity_pool_claims](variables.tf#L45) | Claims to be used by Workload Identity Federation (i.e.: attribute.repository/ORGANIZATION/REPO). If a not null value is provided, then google_iam_workload_identity_pool resource will be created. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L51) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L57) | Location used for multi-regional resources. | <code>string</code> |  | <code>&#34;eu&#34;</code> |
| [network_config](variables.tf#L63) | Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_link  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [notebooks](variables.tf#L73) | Vertex AI workbenchs to be deployed. | <code title="map&#40;object&#40;&#123;&#10;  owner            &#61; string&#10;  region           &#61; string&#10;  subnet           &#61; string&#10;  internal_ip_only &#61; optional&#40;bool, false&#41;&#10;  idle_shutdown    &#61; optional&#40;bool&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L86) | Prefix used for the project id. | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L92) | Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_services](variables.tf#L106) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;aiplatform.googleapis.com&#34;,&#10;  &#34;artifactregistry.googleapis.com&#34;,&#10;  &#34;bigquery.googleapis.com&#34;,&#10;  &#34;cloudbuild.googleapis.com&#34;,&#10;  &#34;compute.googleapis.com&#34;,&#10;  &#34;datacatalog.googleapis.com&#34;,&#10;  &#34;dataflow.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;monitoring.googleapis.com&#34;,&#10;  &#34;notebooks.googleapis.com&#34;,&#10;  &#34;secretmanager.googleapis.com&#34;,&#10;  &#34;servicenetworking.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [region](variables.tf#L126) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west4&#34;</code> |
| [repo_name](variables.tf#L132) | Cloud Source Repository name. null to avoid to create it. | <code>string</code> |  | <code>null</code> |
| [sa_mlops_name](variables.tf#L138) | Name for the MLOPs Service Account. | <code>string</code> |  | <code>&#34;sa-mlops&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [github](outputs.tf#L33) | Github Configuration. |  |
| [notebook](outputs.tf#L39) | Vertex AI managed notebook details. |  |
| [project](outputs.tf#L44) | The project resource as return by the `project` module. |  |
| [project_id](outputs.tf#L49) | Project ID. |  |

<!-- END TFDOC -->

## TODO

- Add support for User Managed Notebooks, SA permission option and non default SA for Single User mode.
- Improve default naming for local VPC and Cloud NAT

## Test

```hcl
module "test" {
  source = "./fabric/blueprints/data-solutions/vertex-mlops/"
  labels = {
    "env" : "dev",
    "team" : "ml"
  }
  bucket_name          = "test-dev"
  dataset_name         = "test"
  identity_pool_claims = "attribute.repository/ORGANIZATION/REPO"
  notebooks = {
    "myworkbench" : {
      "owner" : "user@example.com",
      "region" : "europe-west4",
      "subnet" : "default",
    }
  }
  prefix     = "pref"
  project_id = "test-dev"
  project_create = {
    billing_account_id = "000000-123456-123456"
    parent             = "folders/111111111111"
  }
}
# tftest modules=12 resources=57
```
