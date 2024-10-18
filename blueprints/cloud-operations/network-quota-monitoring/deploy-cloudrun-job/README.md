# Network Quota Monitoring via Cloud Run Job

This simple Terraform setup allows deploying the [discovery tool for the Network Dashboard](../src/) to a Cloud Run Job triggered by Cloud Scheduler.

For service configuration refer to the [Cloud Function deployment](../deploy-cloud-function/) as the underlying monitoring scraper is the same.

## Creating and uploading the Docker container

To build the container run `docker build` in the parent folder, then tag and push it to the URL printed in outputs.

## Example configuration

This is an example of a working configuration, where the discovery root is set at the org level, but resources used to compute timeseries need to be part of the hierarchy of two specific folders:

```tfvars
discovery_config = {
  discovery_root     = "organizations/1234567890"
  monitored_folders  = ["3456789012", "7890123456"]
}
grant_discovery_iam_roles = true
project_create_config = {
  billing_account_id = "12345-ABCDEF-12345"
  parent_id          = "folders/2345678901"
}
project_id = "my-project"

# tftest modules=5 resources=27
```

## Monitoring dashboard

A monitoring dashboard can be optionally be deployed int the same project by setting the `dashboard_json_path` variable to the path of a dashboard JSON file. A sample dashboard is in included, and can be deployed with this variable configuration:

```tfvars
dashboard_json_path = "../dashboards/quotas-utilization.json"
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [discovery_config](variables.tf#L23) | Discovery configuration. Discovery root is the organization or a folder. If monitored folders and projects are empty, every project under the discovery root node will be monitored. | <code title="object&#40;&#123;&#10;  discovery_root     &#61; string&#10;  monitored_folders  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  monitored_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L69) | Project id where the tool will be deployed. | <code>string</code> | ✓ |  |
| [dashboard_json_path](variables.tf#L17) | Optional monitoring dashboard to deploy. | <code>string</code> |  | <code>null</code> |
| [grant_discovery_iam_roles](variables.tf#L41) | Optionally grant required IAM roles to the monitoring tool service account. | <code>bool</code> |  | <code>false</code> |
| [monitoring_project](variables.tf#L48) | Project where generated metrics will be written. Default is to use the same project where the Cloud Function is deployed. | <code>string</code> |  | <code>null</code> |
| [name](variables.tf#L54) | Name used to create resources. | <code>string</code> |  | <code>&#34;netmon&#34;</code> |
| [project_create_config](variables.tf#L60) | Optional configuration if project creation is required. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent_id          &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [region](variables.tf#L74) | Compute region where Cloud Run will be deployed. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |
| [schedule_config](variables.tf#L80) | Scheduler configuration. Region is only used if different from the one used for Cloud Run. | <code title="object&#40;&#123;&#10;  crontab &#61; optional&#40;string, &#34;&#42;&#47;30 &#42; &#42; &#42; &#42;&#34;&#41;&#10;  region  &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [docker_tag](outputs.tf#L17) | Docker tag for the container image. |  |
| [project_id](outputs.tf#L22) | Project id. |  |
| [service_account](outputs.tf#L27) | Cloud Run Job service account. |  |
<!-- END TFDOC -->
