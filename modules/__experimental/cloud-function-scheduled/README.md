# Scheduled Google Cloud Function Module

This module manages a background Cloud Function scheduled via a recurring Cloud Scheduler job. It also manages the required dependencies: a service account for the cloud function with optional IAM bindings, the PubSub topic used for the function trigger, and optionally the GCS bucket used for the code bundle.

## Example

```hcl
module "function" {
  source     = "./modules/cloud-function-scheduled"
  project_id = "myproject"
  name       = "myfunction"
  bundle_config = {
    source_dir  = "../cf"
    output_path = "../bundle.zip"
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| bundle_config | Cloud function code bundle configuration, output path is a zip file. | <code title="object&#40;&#123;&#10;source_dir  &#61; string&#10;output_path &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| name | Name used for resources (schedule, topic, etc.). | <code title="">string</code> | ✓ |  |
| project_id | Project id used for all resources. | <code title="">string</code> | ✓ |  |
| *bucket_name* | Name of the bucket that will be used for the function code, leave null to create one. | <code title="">string</code> |  | <code title="">null</code> |
| *function_config* | Cloud function configuration. | <code title="object&#40;&#123;&#10;entry_point &#61; string&#10;instances   &#61; number&#10;memory      &#61; number&#10;runtime     &#61; string&#10;timeout     &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;entry_point &#61; &#34;main&#34;&#10;instances   &#61; 1&#10;memory      &#61; 256&#10;runtime     &#61; &#34;python37&#34;&#10;timeout     &#61; 180&#10;&#125;">...</code> |
| *prefixes* | Optional prefixes for resource ids, null prefixes will be ignored. | <code title="object&#40;&#123;&#10;bucket          &#61; string&#10;function        &#61; string&#10;job             &#61; string&#10;service_account &#61; string&#10;topic           &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *region* | Region used for all resources. | <code title="">string</code> |  | <code title="">us-central1</code> |
| *schedule_config* | Cloud function scheduler job configuration, leave data null to pass the name variable, set schedule to null to disable schedule. | <code title="object&#40;&#123;&#10;pubsub_data &#61; string&#10;schedule    &#61; string&#10;time_zone   &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;schedule    &#61; &#34;&#42;&#47;10 &#42; &#42; &#42; &#42;&#34;&#10;pubsub_data &#61; null&#10;time_zone   &#61; &#34;UTC&#34;&#10;&#125;">...</code> |
| *service_account_iam_roles* | IAM roles assigned to the service account at the project level. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket_name | Bucket name. |  |
| function_name | Cloud function name. |  |
| service_account_email | Service account email. |  |
| topic_id | PubSub topic id. |  |
<!-- END TFDOC -->
