# MLOps with Vertex AI - Infra setup

## Introduction
This example implements the infrastructure required to deploy an end-to-end [MLOps process](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf) using [Vertex AI](https://cloud.google.com/vertex-ai) platform.


##  GCP resources
A terraform script is provided to setup all the required resources:

- GCP Project  to host all the resources
- Isolated VPC network and a subnet to be used by Vertex and Dataflow (using a Shared VPC is also possible). 
- Firewall rule to allow the internal subnet communication required by Dataflow
- Cloud NAT required to reach the internet from the different computing resources (Vertex and Dataflow)
- GCS bucket to host Vertex and Cloud Build Artifacts.
- BigQuery Dataset to store the training data
- Service account `mlops-env@` with the minimum permissions required by Vertex and Dataflow
- Service account `github` to be used by Workload Identity Federation, to federate Github identity.
- Secret to store Github SSH key

![MLOps project description](./images/mlops_projects.png "MLOps project description")

## Pre-requirements

### User groups

User groups provide a stable frame of reference that allows decoupling the final set of permissions from the stage where entities and resources are created, and their IAM bindings defined. These groups should be created before launching Terraform.

We use the following groups to control access to resources:

- *Data Scientits* (gcp-ml-ds@<company.org>). They create ML pipelines in the experimentation environment.
- *ML Engineers* (gcp-ml-eng@<company.org>). They handle and run the different environments, with access to all resources in order to troubleshoot possible issues with pipelines. 

These groups are not suitable for production grade environments. You can configure the group names through the `groups`variable. 

### Git environment for the ML Pipelines

Make sure you have ready a Github repo with the ML pipeline code. 
You can clone the following example for setting up the repo: https://github.com/pbalm/professional-services/tree/vertex-mlops/examples/vertex_mlops_enterprise
This repo should have at least one of the following branches: `dev`, `staging`, `prod`

You will need to configure the Github organization and repo name in the `identity_pool_claims` variable.

##  Instructions
###  Deploy the experimentation environment

- Create a `terraform.tfvars` file and specify the required variables. You can use the `terraform.tfvars.sample` an an starting point

```tfm
folder_id          = "folders/111111111111"
billing_account_id = "000000-123456-123456"
bucket_name          = "creditcards-dev"
dataset_name         = "creditcards"
identity_pool_claims = "attribute.repository/ORGANIZATION/REPO"
organization_domain = "example.com"
prefix              = "pref"
project_id          = "creditcards-dev"
```
- Make sure you fill in the following parameters:
  - `folder_id `: Parent folder where the project will be created.
  - `organization_domain`: Domain name to be used as a suffix for the group names
  - `notebooks`: Configuration data for creating Vertex Managed Workbenchs
  - `prefix`: Prefix to append to the project id and GCS bucket name. 
- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L18) | Billing account id. | <code>string</code> | ✓ |  |
| [folder_id](variables.tf#L41) | Folder ID for the folder where the project will be created. | <code>string</code> | ✓ |  |
| [organization_domain](variables.tf#L126) | Organization domain. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L143) | Project id. | <code>string</code> | ✓ |  |
| [bucket_name](variables.tf#L23) | Create GCS Bucket. | <code>string</code> |  | <code>null</code> |
| [dataset_name](variables.tf#L29) | Create BigQuery Datasets. | <code>string</code> |  | <code>null</code> |
| [env](variables.tf#L35) | Environment (dev,stg,prd). | <code>string</code> |  | <code>&#34;dev&#34;</code> |
| [groups](variables.tf#L46) | User groups. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  data-scientists &#61; &#34;gcp-ml-ds&#34;&#10;  ml-engineers    &#61; &#34;gcp-ml-eng&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [identity_pool_claims](variables.tf#L55) | Claims to be used by Workload Identity Federation (i.e.: attribute.repository/ORGANIZATION/REPO). | <code>string</code> |  | <code>null</code> |
| [kms_service_agents](variables.tf#L61) | KMS IAM configuration in as service => [key]. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L67) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [notebooks](variables.tf#L74) | Vertex AI workbenchs to be deployed. | <code title="map&#40;object&#40;&#123;&#10;  owner                 &#61; string&#10;  region                &#61; string&#10;  subnet                &#61; string&#10;  internal_ip_only      &#61; bool&#10;  idle_shutdown_timeout &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [org_policies](variables.tf#L86) | Org-policy overrides at project level. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  allow &#61; optional&#40;object&#40;&#123;&#10;    all    &#61; optional&#40;bool&#41;&#10;    values &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  deny &#61; optional&#40;object&#40;&#123;&#10;    all    &#61; optional&#40;bool&#41;&#10;    values &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  enforce &#61; optional&#40;bool, true&#41; &#35; for boolean policies only.&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool, true&#41; &#35; for boolean policies only.&#10;    condition &#61; object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L131) | Prefix used for the project id. | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L137) | Create project. When set to false, uses a data source to reference existing project. | <code>bool</code> |  | <code>true</code> |
| [project_services](variables.tf#L147) | List of core services enabled on all projects. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;aiplatform.googleapis.com&#34;,&#10;  &#34;artifactregistry.googleapis.com&#34;,&#10;  &#34;bigquery.googleapis.com&#34;,&#10;  &#34;cloudbuild.googleapis.com&#34;,&#10;  &#34;compute.googleapis.com&#34;,&#10;  &#34;datacatalog.googleapis.com&#34;,&#10;  &#34;dataflow.googleapis.com&#34;,&#10;  &#34;iam.googleapis.com&#34;,&#10;  &#34;monitoring.googleapis.com&#34;,&#10;  &#34;notebooks.googleapis.com&#34;,&#10;  &#34;secretmanager.googleapis.com&#34;,&#10;  &#34;servicenetworking.googleapis.com&#34;,&#10;  &#34;serviceusage.googleapis.com&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [region](variables.tf#L167) | Region used for regional resources. | <code>string</code> |  | <code>&#34;europe-west4&#34;</code> |
| [repo_name](variables.tf#L173) | Cloud Source Repository name. null to avoid to create it. | <code>string</code> |  | <code>null</code> |
| [vpc](variables.tf#L179) | Shared VPC configuration for the project. | <code title="object&#40;&#123;&#10;  host_project &#61; string&#10;  gke_setup &#61; object&#40;&#123;&#10;    enable_security_admin     &#61; bool&#10;    enable_host_service_agent &#61; bool&#10;  &#125;&#41;&#10;  subnets_iam &#61; map&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_local](variables.tf#L192) | Local VPC configuration for the project. | <code title="object&#40;&#123;&#10;  name              &#61; string&#10;  psa_config_ranges &#61; map&#40;string&#41;&#10;  subnets &#61; list&#40;object&#40;&#123;&#10;    name               &#61; string&#10;    region             &#61; string&#10;    ip_cidr_range      &#61; string&#10;    secondary_ip_range &#61; map&#40;string&#41;&#10;    &#125;&#10;  &#41;&#41;&#10;  &#125;&#10;&#41;">object&#40;&#123;&#8230;&#41;</code> |  | <code title="&#123;&#10;  &#34;name&#34; : &#34;default&#34;,&#10;  &#34;subnets&#34; : &#91;&#10;    &#123;&#10;      &#34;name&#34; : &#34;default&#34;,&#10;      &#34;region&#34; : &#34;europe-west1&#34;,&#10;      &#34;ip_cidr_range&#34; : &#34;10.1.0.0&#47;24&#34;,&#10;      &#34;secondary_ip_range&#34; : null&#10;    &#125;,&#10;    &#123;&#10;      &#34;name&#34; : &#34;default&#34;,&#10;      &#34;region&#34; : &#34;europe-west4&#34;,&#10;      &#34;ip_cidr_range&#34; : &#34;10.4.0.0&#47;24&#34;,&#10;      &#34;secondary_ip_range&#34; : null&#10;    &#125;&#10;  &#93;,&#10;  &#34;psa_config_ranges&#34; : &#123;&#10;    &#34;vertex&#34; : &#34;10.13.0.0&#47;18&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [github](outputs.tf#L31) | Github Configuration. |  |
| [google_iam_workload_identity_pool_provider](outputs.tf#L37) | Id for the Workload Identity Pool Provider. |  |
| [project](outputs.tf#L42) | The project resource as return by the `project` module. |  |
| [project_id](outputs.tf#L51) | Project ID. |  |
| [workload_identity_pool_name](outputs.tf#L59) | Resource name for the Workload Identity Pool. |  |

<!-- END TFDOC -->
