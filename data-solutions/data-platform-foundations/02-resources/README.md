# Data Platform Foundations - Resources (Step 2)

This is the second step needed to deploy Data Platform Foundations, which creates resources needed to store and process the data, in the projects created in the [previous step](./../environment/). Please refer to the [top-level README](../README.md) for prerequisites and how to run the first step.

![Data Foundation -  Phase 2](./diagram.png "High-level diagram")

The resources that will be create in each project are:

- Common
- Landing
  - [x] GCS
  - [x] Pub/Sub
- Orchestration & Transformation
  - [x] Dataflow
- DWH
  - [x] Bigquery (L0/1/2)
  - [x] GCS
- Datamart
  - [x] Bigquery (views/table)
  - [x] GCS
  - [ ] BigTable

## Running the example

In the previous step, we created the environment (projects and service account) which we are going to use in this step.

To create the resources, copy the output of the environment step (**project_ids**) and paste it into the `terraform.tvars`:

- Specify your variables in a `terraform.tvars`, you can use the ouptu from the environment stage

```tfm
project_ids = {
  datamart       = "datamart-project_id"
  dwh            = "dwh-project_id"
  landing        = "landing-project_id"
  services       = "services-project_id"
  transformation = "transformation-project_id"
}
```

- Get a key for the service account created in the environment stage:
  - Go into services project
  - Go into IAM page
  - Go into the service account section
  - Creaet a new key for the service account created in previeous step (**service_account**)
  - Download the json key into the current folder
- make sure you have the right authentication setup: `export GOOGLE_APPLICATION_CREDENTIALS=PATH_TO_SERVICE_ACCOUT_KEY.json`
- run `terraform init` and `terraform apply`

Once done testing, you can clean up resources by running `terraform destroy`.

### CMEK configuration
You can configure GCP resources to use existing CMEK keys configuring the 'service_encryption_key_ids' variable. You need to specify a 'global' and a 'multiregional' key.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_ids | Project IDs. | <code title="object&#40;&#123;&#10;datamart       &#61; string&#10;dwh            &#61; string&#10;landing        &#61; string&#10;services       &#61; string&#10;transformation &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| *datamart_bq_datasets* | Datamart Bigquery datasets | <code title="map&#40;object&#40;&#123;&#10;iam      &#61; map&#40;list&#40;string&#41;&#41;&#10;location &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;bq_datamart_dataset &#61; &#123;&#10;location &#61; &#34;EU&#34;&#10;iam &#61; &#123;&#10;&#125;&#10;&#125;&#10;&#125;">...</code> |
| *dwh_bq_datasets* | DWH Bigquery datasets | <code title="map&#40;object&#40;&#123;&#10;location &#61; string&#10;iam      &#61; map&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;bq_raw_dataset &#61; &#123;&#10;iam      &#61; &#123;&#125;&#10;location &#61; &#34;EU&#34;&#10;&#125;&#10;&#125;">...</code> |
| *landing_buckets* | List of landing buckets to create | <code title="map&#40;object&#40;&#123;&#10;location &#61; string&#10;name     &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;raw-data &#61; &#123;&#10;location &#61; &#34;EU&#34;&#10;name     &#61; &#34;raw-data&#34;&#10;&#125;&#10;data-schema &#61; &#123;&#10;location &#61; &#34;EU&#34;&#10;name     &#61; &#34;data-schema&#34;&#10;&#125;&#10;&#125;">...</code> |
| *landing_pubsub* | List of landing pubsub topics and subscriptions to create | <code title="map&#40;map&#40;object&#40;&#123;&#10;iam    &#61; map&#40;list&#40;string&#41;&#41;&#10;labels &#61; map&#40;string&#41;&#10;options &#61; object&#40;&#123;&#10;ack_deadline_seconds       &#61; number&#10;message_retention_duration &#61; number&#10;retain_acked_messages      &#61; bool&#10;expiration_policy_ttl      &#61; number&#10;&#125;&#41;&#10;&#125;&#41;&#41;&#41;">map(map(object({...})))</code> |  | <code title="&#123;&#10;landing-1 &#61; &#123;&#10;sub1 &#61; &#123;&#10;iam &#61; &#123;&#10;&#125;&#10;labels  &#61; &#123;&#125;&#10;options &#61; null&#10;&#125;&#10;sub2 &#61; &#123;&#10;iam     &#61; &#123;&#125;&#10;labels  &#61; &#123;&#125;,&#10;options &#61; null&#10;&#125;,&#10;&#125;&#10;&#125;">...</code> |
| *landing_service_account* | landing service accounts list. | <code title="">string</code> |  | <code title="">sa-landing</code> |
| *service_account_names* | Project service accounts list. | <code title="object&#40;&#123;&#10;datamart       &#61; string&#10;dwh            &#61; string&#10;landing        &#61; string&#10;services       &#61; string&#10;transformation &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;datamart       &#61; &#34;sa-datamart&#34;&#10;dwh            &#61; &#34;sa-datawh&#34;&#10;landing        &#61; &#34;sa-landing&#34;&#10;services       &#61; &#34;sa-services&#34;&#10;transformation &#61; &#34;sa-transformation&#34;&#10;&#125;">...</code> |
| *service_encryption_key_ids* | Cloud KMS encryption key in {LOCATION => [KEY_URL]} format. Keys belong to existing project. | <code title="object&#40;&#123;&#10;multiregional &#61; string&#10;global        &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;multiregional &#61; null&#10;global        &#61; null&#10;&#125;">...</code> |
| *transformation_buckets* | List of transformation buckets to create | <code title="map&#40;object&#40;&#123;&#10;location &#61; string&#10;name     &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;temp &#61; &#123;&#10;location &#61; &#34;EU&#34;&#10;name     &#61; &#34;temp&#34;&#10;&#125;,&#10;templates &#61; &#123;&#10;location &#61; &#34;EU&#34;&#10;name     &#61; &#34;templates&#34;&#10;&#125;,&#10;&#125;">...</code> |
| *transformation_subnets* | List of subnets to create in the transformation Project. | <code title="list&#40;object&#40;&#123;&#10;ip_cidr_range      &#61; string&#10;name               &#61; string&#10;region             &#61; string&#10;secondary_ip_range &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="&#91;&#10;&#123;&#10;ip_cidr_range      &#61; &#34;10.1.0.0&#47;20&#34;&#10;name               &#61; &#34;transformation-subnet&#34;&#10;region             &#61; &#34;europe-west3&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;,&#10;&#93;">...</code> |
| *transformation_vpc_name* | Name of the VPC created in the transformation Project. | <code title="">string</code> |  | <code title="">transformation-vpc</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| datamart-datasets | List of bigquery datasets created for the datamart project. |  |
| dwh-datasets | List of bigquery datasets created for the dwh project. |  |
| landing-buckets | List of buckets created for the landing project. |  |
| landing-pubsub | List of pubsub topics and subscriptions created for the landing project. |  |
| transformation-buckets | List of buckets created for the transformation project. |  |
| transformation-vpc | Transformation VPC details |  |
<!-- END TFDOC -->
