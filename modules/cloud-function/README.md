# Cloud Function Module

Cloud Function management, with support for IAM roles and optional bucket creation.

The GCS object used for deployment uses a hash of the bundle zip contents in its name, which ensures change tracking and avoids recreating the function if the GCS object is deleted and needs recreating.

## TODO

- [ ] add support for `source_repository`

## Examples

### HTTP trigger

This deploys a Cloud Function with an HTTP endpoint, using a pre-existing GCS bucket for deployment, setting the service account to the Cloud Function default one, and delegating access control to the containing project.

```hcl
module "cf-http" {
  source        = "./modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir = "my-cf-source-folder"
    output_path = "bundle.zip"
  }
}
# tftest:skip
```

### PubSub and non-HTTP triggers

Other trigger types other than HTTP are configured via the `trigger_config` variable. This example shows a PubSub trigger.

```hcl
module "cf-http" {
  source        = "./modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir = "my-cf-source-folder"
    output_path = "bundle.zip"
  }
  trigger_config = {
    event = "google.pubsub.topic.publish"
    resource = local.my-topic
    retry = null
  }
}
# tftest:skip
```

### Controlling HTTP access

To allow anonymous access to the function, grant the `roles/cloudfunctions.invoker` role to the special `allUsers` identifier. Use specific identities (service accounts, groups, etc.) instead of `allUsers` to only allow selective access.

```hcl
module "cf-http" {
  source        = "./modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir = "my-cf-source-folder"
    output_path = "bundle.zip"
  }
  iam   = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
}
# tftest:skip
```

### GCS bucket creation

You can have the module auto-create the GCS bucket used for deployment via the `bucket_config` variable. Setting `bucket_config.location` to `null` will also use the function region for GCS.

```hcl
module "cf-http" {
  source        = "./modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bucket_config = {
    location             = null
    lifecycle_delete_age = 1
  }
  bundle_config = {
    source_dir = "my-cf-source-folder"
    output_path = "bundle.zip"
  }
}
# tftest:skip
```

### Service account management

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` value (default).

```hcl
module "cf-http" {
  source        = "./modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir = "my-cf-source-folder"
    output_path = "bundle.zip"
  }
  service_account_create = true
}
# tftest:skip
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to `false` (the default).

```hcl
module "cf-http" {
  source        = "./modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir = "my-cf-source-folder"
    output_path = "bundle.zip"
  }
  service_account = local.service_account_email
}
# tftest:skip
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| bucket_name | Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null. | <code title="">string</code> | ✓ |  |
| bundle_config | Cloud function source folder and generated zip bundle paths. Output path defaults to '/tmp/bundle.zip' if null. | <code title="object&#40;&#123;&#10;source_dir  &#61; string&#10;output_path &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| name | Name used for cloud function and associated resources. | <code title="">string</code> | ✓ |  |
| project_id | Project id used for all resources. | <code title="">string</code> | ✓ |  |
| *bucket_config* | Enable and configure auto-created bucket. Set fields to null to use defaults. | <code title="object&#40;&#123;&#10;location             &#61; string&#10;lifecycle_delete_age &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *environment_variables* | Cloud function environment variables. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *function_config* | Cloud function configuration. | <code title="object&#40;&#123;&#10;entry_point      &#61; string&#10;ingress_settings &#61; string&#10;instances        &#61; number&#10;memory           &#61; number&#10;runtime          &#61; string&#10;timeout          &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;entry_point      &#61; &#34;main&#34;&#10;ingress_settings &#61; null&#10;instances        &#61; 1&#10;memory           &#61; 256&#10;runtime          &#61; &#34;python37&#34;&#10;timeout          &#61; 180&#10;&#125;">...</code> |
| *iam* | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *ingress_settings* | Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL and ALLOW_INTERNAL_ONLY. | <code title="">string</code> |  | <code title="">null</code> |
| *labels* | Resource labels | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *prefix* | Optional prefix used for resource names. | <code title="">string</code> |  | <code title="">null</code> |
| *region* | Region used for all resources. | <code title="">string</code> |  | <code title="">europe-west1</code> |
| *service_account* | Service account email. Unused if service account is auto-created. | <code title="">string</code> |  | <code title="">null</code> |
| *service_account_create* | Auto-create service account. | <code title="">bool</code> |  | <code title="">false</code> |
| *trigger_config* | Function trigger configuration. Leave null for HTTP trigger. | <code title="object&#40;&#123;&#10;event    &#61; string&#10;resource &#61; string&#10;retry    &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *vpc_connector_config* | VPC connector configuration. Set `create_config` attributes to trigger creation. | <code title="object&#40;&#123;&#10;egress_settings &#61; string&#10;name            &#61; string&#10;create_config &#61; object&#40;&#123;&#10;ip_cidr_range &#61; string&#10;network       &#61; string&#10;&#125;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket | Bucket resource (only if auto-created). |  |
| bucket_name | Bucket name. |  |
| function | Cloud function resources. |  |
| function_name | Cloud function name. |  |
| service_account | Service account resource. |  |
| service_account_email | Service account email. |  |
| service_account_iam_email | Service account email. |  |
| vpc_connector | VPC connector resource if created. |  |
<!-- END TFDOC -->
