# MLOps with Vertex AI - Infra setup

## Introduction
This example implements the infrastructure required to deploy an end-to-end [MLOps process](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf) using [Vertex AI](https://cloud.google.com/vertex-ai) platform. 

##  GCP resources
The blueprint will deploy all the required resources to have a fully functional MLOPs environment containing:

- GCP Project  to host all the resources
- Isolated VPC network and a subnet to be used by Vertex and Dataflow (using a Shared VPC is also possible). 
- Firewall rule to allow the internal subnet communication required by Dataflow
- Cloud NAT required to reach the internet from the different computing resources (Vertex and Dataflow)
- GCS buckets to host Vertex AI and Cloud Build Artifacts. By default the buckets will be regional and should match the Vertex AI region for the different resources (i.e. Vertex Managed Dataset) and processes (i.e. Vertex trainining)
- BigQuery Dataset where the training data will be stored. This is optional, since the training data could be already hosted in an existing BigQuery dataset.
- Service account (`mlops-[env]@`) with the minimum permissions required by Vertex and Dataflow
- Service account (`github@`) to be used by Workload Identity Federation, to federate Github identity (Optional). 
- Secret to store the Github SSH key to get access the CICD code repo.

![MLOps project description](./images/mlops_projects.png "MLOps project description")

## Pre-requirements

### User groups

Assign roles relying on User groups is a way to decouple the final set of permissions from the stage where entities and resources are created, and their IAM bindings defined. These groups should be created before launching Terraform.

We use the following groups to control access to resources:

- *Data Scientits* (gcp-ml-ds@<company.org>). They create ML pipelines in the experimentation environment.
- *ML Engineers* (gcp-ml-eng@<company.org>). They manage and run the different environments, with access to all resources in order to troubleshoot possible issues with pipelines. 

These groups are not suitable for production grade environments. You can configure the group names through the `groups`variable. 

##  Instructions
###  Deploy the experimentation environment

- Create a `terraform.tfvars` file and specify the variables to match your desired configuration. You can use the provided `terraform.tfvars.sample`  as reference.
- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`

## What's next?

Once the environment is deployed, you can follow this [guide](https://github.com/javiergp/professional-services/blob/main/examples/vertex_mlops_enterprise/README.md) to setup the Vertex AI pipeline and run it on the deployed infraestructure.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L93) | Project id, references existing project if `project_create` is null. | <code>string</code> | ✓ |  |
| [bucket_name](variables.tf#L18) | GCS bucket name to store the Vertex AI artifacts. | <code>string</code> |  | <code>null</code> |
| [dataset_name](variables.tf#L24) | BigQuery Dataset to store the training data. | <code>string</code> |  | <code>null</code> |
| [group_iam](variables.tf#L31) | Authoritative IAM binding for the project, in {GROUP_EMAIL => [ROLES]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [identity_pool_claims](variables.tf#L38) | Claims to be used by Workload Identity Federation (i.e.: attribute.repository/ORGANIZATION/REPO). If a not null value is provided, then google_iam_workload_identity_pool resource will be created. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L44) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L50) | Location used for multi-regional resources. | <code>string</code> |  | <code>&#34;eu&#34;</code> |
| [network_config](variables.tf#L56) | Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_link  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [notebooks](variables.tf#L66) | Vertex AI workbenchs to be deployed. | <code title="map&#40;object&#40;&#123;&#10;  owner            &#61; string&#10;  region           &#61; string&#10;  subnet           &#61; string&#10;  internal_ip_only &#61; optional&#40;bool, false&#41;&#10;  idle_shutdown    &#61; optional&#40;bool&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L78) | Prefix used for the project id. | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L84) | Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_services](variables.tf#L98) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;aiplatform.googleapis.com&#34;,&#10;  &#34;artifactregistry.googleapis.com&#34;,&#10;  &#34;bigquery.googleapis.com&#34;,&#10;  &#34;cloudbuild.googleapis.com&#34;,&#10;  &#34;compute.googleapis.com&#34;,&#10;  &#34;datacatalog.googleapis.com&#34;,&#10;  &#34;dataflow.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;monitoring.googleapis.com&#34;,&#10;  &#34;notebooks.googleapis.com&#34;,&#10;  &#34;secretmanager.googleapis.com&#34;,&#10;  &#34;servicenetworking.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [region](variables.tf#L118) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west4&#34;</code> |
| [repo_name](variables.tf#L124) | Cloud Source Repository name. null to avoid to create it. | <code>string</code> |  | <code>null</code> |
| [sa_mlops_name](variables.tf#L130) | Name for the MLOPs Service Account. | <code>string</code> |  | <code>&#34;sa-mlops&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [github](outputs.tf#L33) | Github Configuration. |  |
| [notebook](outputs.tf#L39) | Vertex AI managed notebook details. |  |
| [project](outputs.tf#L44) | The project resource as return by the `project` module. |  |
| [project_id](outputs.tf#L49) | Project ID. |  |

<!-- END TFDOC -->
