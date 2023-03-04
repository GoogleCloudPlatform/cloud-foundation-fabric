# BigQuery ML and Vertex AI Pipeline

This blueprint creates the infrastructure needed to deploy and run a Vertex AI environment to develop and deploy a machine learning model to be used from Vertex AI endpoint or in BigQuery.

This is the high-level diagram:

![High-level diagram](diagram.png "High-level diagram")

It also includes the IAM wiring needed to make such scenarios work. Regional resources are used in this example, but the same logic applies to 'dual regional', 'multi regional', or 'global' resources.

The example is designed to match real-world use cases with a minimum amount of resources and be used as a starting point for your scenario.

## Managed resources and services

This sample creates several distinct groups of resources:

- Networking
  - VPC network
  - Subnet
  - Firewall rules for SSH access via IAP and open communication within the VPC
  - Cloud Nat
- IAM
  - Vertex AI workbench service account
  - Vertex AI pipeline service account
- Storage
  - GCS bucket
  - Bigquery dataset

## Customization

### Virtual Private Cloud (VPC) design

As is often the case in real-world configurations, this blueprint accepts an existing Shared-VPC via the `network_config` variable as input.

### Customer Managed Encryption Key

As is often the case in real-world configurations, this blueprint accepts as input existing Cloud KMS keys to encrypt resources via the `service_encryption_keys` variable.

## Demo

In the repository [`demo`](./demo/) folder, you can find an example of creating a Vertex AI pipeline from a publically available dataset and deploying the model to be used from a Vertex AI managed endpoint or from within Bigquery.

To run the demo:

- Connect to the Vertex AI workbench instance
- Clone this repository
- Run the and run [`demo/bmql_pipeline.ipynb`](demo/bmql_pipeline.ipynb) Jupyter Notebook.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [prefix](variables.tf#L33) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L51) | Project id references existing project if `project_create` is null. | <code>string</code> | ✓ |  |
| [location](variables.tf#L17) | The location where resources will be deployed. | <code>string</code> |  | <code>&#34;US&#34;</code> |
| [network_config](variables.tf#L23) | Shared VPC network configurations to use. If null networks will be created in projects with pre-configured values. | <code title="object&#40;&#123;&#10;  host_project      &#61; string&#10;  network_self_link &#61; string&#10;  subnet_self_link  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [project_create](variables.tf#L42) | Provide values if project creation is needed, use existing project if null. Parent format:  folders/folder_id or organizations/org_id. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [region](variables.tf#L56) | The region where resources will be deployed. | <code>string</code> |  | <code>&#34;us-central1&#34;</code> |
| [service_encryption_keys](variables.tf#L62) | Cloud KMS to use to encrypt different services. The key location should match the service region. | <code title="object&#40;&#123;&#10;  bq      &#61; string&#10;  compute &#61; string&#10;  storage &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bucket](outputs.tf#L17) | GCS Bucket URL. |  |
| [dataset](outputs.tf#L22) | GCS Bucket URL. |  |
| [notebook](outputs.tf#L27) | Vertex AI notebook details. |  |
| [project](outputs.tf#L35) | Project id. |  |
| [service-account-vertex](outputs.tf#L40) | Service account to be used for Vertex AI pipelines. |  |
| [vertex-ai-metadata-store](outputs.tf#L45) | Vertex AI Metadata Store ID. |  |
| [vpc](outputs.tf#L50) | VPC Network. |  |

<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source = "./fabric/blueprints/data-solutions/bq-ml/"
  project_create = {
    billing_account_id = "123456-123456-123456"
    parent             = "folders/12345678"
  }
  project_id = "project-1"
  prefix     = "prefix"
}
# tftest modules=9 resources=46
```
