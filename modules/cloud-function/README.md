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
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
}
# tftest modules=1 resources=2
```

Analogous example using 2nd generation Cloud Functions
```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  v2            = true
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
}
# tftest modules=1 resources=2
```

### PubSub and non-HTTP triggers

Other trigger types other than HTTP are configured via the `trigger_config` variable. This example shows a PubSub trigger.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function"
  project_id  = "my-project"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
  trigger_config = {
    v1 = {
      event    = "google.pubsub.topic.publish"
      resource = "local.my-topic"
    }
  }
}
# tftest modules=1 resources=2
```

Cloud Functions 2nd gen support only [Eventarc](https://cloud.google.com/eventarc/docs) and uses separate structure
to configure:
```hcl
module "trigger-service-account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = "my-project"
  name       = "sa-cloudfunction"
  iam_project_roles = {
    "my-project" = [
      "roles/run.invoker"
    ]
  }
}

module "cf-http" {
  source      = "./fabric/modules/cloud-function"
  project_id  = "my-project"
  v2          = true
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
  trigger_config = {
    v2 = {
      event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
      pubsub_topic          = "local.my-topic"
      service_account_email = module.trigger-service-account.email
    }
  }
}
# tftest modules=2 resources=4
```
Ensure that pubsub robo-account `service-%s@gcp-sa-pubsub.iam.gserviceaccount.com` has `roles/iam.serviceAccountTokenCreatator` 
as documented [here](https://cloud.google.com/eventarc/docs/roles-permissions#pubsub-topic)

### Controlling HTTP access

To allow anonymous access to the function, grant the `roles/cloudfunctions.invoker` role to the special `allUsers` identifier. Use specific identities (service accounts, groups, etc.) instead of `allUsers` to only allow selective access.

```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
  iam   = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
}
# tftest modules=1 resources=3
```

### GCS bucket creation

You can have the module auto-create the GCS bucket used for deployment via the `bucket_config` variable. Setting `bucket_config.location` to `null` will also use the function region for GCS.

```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bucket_config = {
    lifecycle_delete_age_days = 1
  }
  bundle_config = {
    source_dir  = "fabric/assets/"
  }
}
# tftest modules=1 resources=3
```

### Service account management

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` value (default).

```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
  service_account_create = true
}
# tftest modules=1 resources=3
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to `false` (the default).

```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets/"
    output_path = "bundle.zip"
  }
  service_account = "non-existent@serice.account.email"
}
# tftest modules=1 resources=2
```

### Custom bundle config

In order to help prevent `archive_zip.output_md5` from changing cross platform (e.g. Cloud Build vs your local development environment), you'll have to make sure that the files included in the zip are always the same.

```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  bundle_config = {
    source_dir  = "fabric/assets"
    output_path = "bundle.zip"
    excludes    = ["__pycache__"]
  }
}
# tftest modules=1 resources=2
```

### Private Cloud Build Pool

This deploys a Cloud Function with an HTTP endpoint, using a pre-existing GCS bucket for deployment using a pre existing private Cloud Build worker pool. 

```hcl
module "cf-http" {
  source        = "./fabric/modules/cloud-function"
  project_id    = "my-project"
  name          = "test-cf-http"
  bucket_name   = "test-cf-bundles"
  build_worker_pool = "projects/my-project/locations/europe-west1/workerPools/my_build_worker_pool"
  bundle_config = {
    source_dir  = "fabric/assets"
    output_path = "bundle.zip"
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [bucket_name](variables.tf#L26) | Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null. | <code>string</code> | ✓ |  |
| [bundle_config](variables.tf#L37) | Cloud function source folder and generated zip bundle paths. Output path defaults to '/tmp/bundle.zip' if null. | <code title="object&#40;&#123;&#10;  source_dir  &#61; string&#10;  output_path &#61; optional&#40;string, &#34;&#47;tmp&#47;bundle.zip&#34;&#41;&#10;  excludes    &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L94) | Name used for cloud function and associated resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L109) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [bucket_config](variables.tf#L17) | Enable and configure auto-created bucket. Set fields to null to use defaults. | <code title="object&#40;&#123;&#10;  location                  &#61; optional&#40;string&#41;&#10;  lifecycle_delete_age_days &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [build_worker_pool](variables.tf#L31) | Build worker pool, in projects/<PROJECT-ID>/locations/<REGION>/workerPools/<POOL_NAME> format | <code>string</code> |  | <code>null</code> |
| [description](variables.tf#L46) | Optional description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [environment_variables](variables.tf#L52) | Cloud function environment variables. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [function_config](variables.tf#L58) | Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout | <code title="object&#40;&#123;&#10;  entry_point     &#61; optional&#40;string, &#34;main&#34;&#41;&#10;  instance_count  &#61; optional&#40;number, 1&#41;&#10;  memory_mb       &#61; optional&#40;number, 256&#41; &#35; Memory in MB&#10;  runtime         &#61; optional&#40;string, &#34;python310&#34;&#41;&#10;  timeout_seconds &#61; optional&#40;number, 180&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  entry_point     &#61; &#34;main&#34;&#10;  instance_count  &#61; 1&#10;  memory_mb       &#61; 256&#10;  runtime         &#61; &#34;python310&#34;&#10;  timeout_seconds &#61; 180&#10;&#125;">&#123;&#8230;&#125;</code> |
| [iam](variables.tf#L76) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_settings](variables.tf#L82) | Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL, ALLOW_INTERNAL_AND_GCLB and ALLOW_INTERNAL_ONLY . | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L88) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L99) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [region](variables.tf#L114) | Region used for all resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |
| [secrets](variables.tf#L120) | Secret Manager secrets. Key is the variable name or mountpoint, volume versions are in version:path format. | <code title="map&#40;object&#40;&#123;&#10;  is_volume  &#61; bool&#10;  project_id &#61; number&#10;  secret     &#61; string&#10;  versions   &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L132) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L138) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [trigger_config](variables.tf#L144) | Function trigger configuration. Leave null for HTTP trigger. | <code title="object&#40;&#123;&#10;  v1 &#61; optional&#40;object&#40;&#123;&#10;    event    &#61; string&#10;    resource &#61; string&#10;    retry    &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;,&#10;  v2 &#61; optional&#40;object&#40;&#123;&#10;    region       &#61; optional&#40;string&#41;&#10;    event_type   &#61; optional&#40;string&#41;&#10;    pubsub_topic &#61; optional&#40;string&#41;&#10;    event_filters &#61; optional&#40;list&#40;object&#40;&#123;&#10;      attribute &#61; string&#10;      value     &#61; string&#10;      operator  &#61; string&#10;    &#125;&#41;&#41;&#41;&#10;    service_account_email  &#61; optional&#40;string&#41;&#10;    service_account_create &#61; optional&#40;bool&#41;&#10;    retry_policy           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123; v1 &#61; null, v2 &#61; null &#125;</code> |
| [v2](variables.tf#L192) | Whether to use Cloud Function version 2nd Gen or 1st Gen. | <code>bool</code> |  | <code>false</code> |
| [vpc_connector](variables.tf#L173) | VPC connector configuration. Set create to 'true' if a new connector needs to be created. | <code title="object&#40;&#123;&#10;  create          &#61; bool&#10;  name            &#61; string&#10;  egress_settings &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_connector_config](variables.tf#L183) | VPC connector network configuration. Must be provided if new VPC connector is being created. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; string&#10;  network       &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bucket](outputs.tf#L17) | Bucket resource (only if auto-created). |  |
| [bucket_name](outputs.tf#L24) | Bucket name. |  |
| [function](outputs.tf#L29) | Cloud function resources. |  |
| [function_name](outputs.tf#L34) | Cloud function name. |  |
| [service_account](outputs.tf#L42) | Service account resource. |  |
| [service_account_email](outputs.tf#L47) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L52) | Service account email. |  |
| [trigger_service_account](outputs.tf#L60) | Service account resource. |  |
| [trigger_service_account_email](outputs.tf#L65) | Service account email. |  |
| [trigger_service_account_iam_email](outputs.tf#L70) | Service account email. |  |
| [uri](outputs.tf#L38) | Cloud function service uri. |  |
| [vpc_connector](outputs.tf#L78) | VPC connector resource if created. |  |

<!-- END TFDOC -->
