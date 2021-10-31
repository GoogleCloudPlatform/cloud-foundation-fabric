# Cloud Run Module

Cloud Run management, with support for IAM roles and optional Eventarc trigger creation.

## Examples

### Traffic split

This deploys a Cloud Run service with traffic split between two revisions.

```hcl
module "cloud_run" {
  source     = "../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  revision_name = "green"
  containers = [{
    image   = "us-docker.pkg.dev/cloudrun/container/hello"
    command = null
    args    = null
    env     = null
    env_from = null
    ports = null
    resources = null
    volume_mounts = null
  }]
  traffic = {
    "blue" = 25
    "green" = 75
  }
}
# tftest:skip
```

### Eventarc trigger (Pub/Sub)

This deploys a Cloud Run service that will be triggered when messages are published to Pub/Sub topics.

```hcl
module "cloud_run" {
  source     = "../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  containers = [{
    image   = "us-docker.pkg.dev/cloudrun/container/hello"
    command = null
    args    = null
    env     = null
    env_from = null
    ports = null
    resources = null
    volume_mounts = null
  }]
  pub_sub_triggers = [
    "topic1",
    "topic2"
  ]
}
# tftest:skip
```

### Eventarc trigger (Audit logs)

This deploys a Cloud Run service that will be triggered when specific log events are written to Google Cloud audit logs.

module "cloud_run" {
  source     = "../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  containers = [{
    image   = "us-docker.pkg.dev/cloudrun/container/hello"
    command = null
    args    = null
    env     = null
    env_from = null
    ports = null
    resources = null
    volume_mounts = null
  }]
  audit_log_triggers = [
    {
      service_name = "cloudresourcemanager.googleapis.com"
      method_name = "SetIamPolicy"
    }
  ]
}

### Service account management

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` value (default).

```hcl
module "cloud_run" {
  source     = "../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  containers = [{
    image   = "us-docker.pkg.dev/cloudrun/container/hello"
    command = null
    args    = null
    env     = null
    env_from = null
    ports = null
    resources = null
    volume_mounts = null
  }]
  service_account_create = true
}
# tftest:skip
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to `false` (the default).

```hcl
module "cloud_run" {
  source     = "../../modules/cloud-run"
  project_id = "my-project"
  name       = "hello"
  containers = [{
    image   = "us-docker.pkg.dev/cloudrun/container/hello"
    command = null
    args    = null
    env     = null
    env_from = null
    ports = null
    resources = null
    volume_mounts = null
  }]
  service_account = local.service_account_email
}
# tftest:skip
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| containers | Containers | <code title="list&#40;object&#40;&#123;&#10;image   &#61; string&#10;command &#61; list&#40;string&#41;&#10;args    &#61; list&#40;string&#41;&#10;env     &#61; map&#40;string&#41;&#10;env_from &#61; map&#40;object&#40;&#123;&#10;key  &#61; string&#10;name &#61; string&#10;&#125;&#41;&#41;&#10;resources &#61; object&#40;&#123;&#10;limits &#61; object&#40;&#123;&#10;cpu    &#61; string&#10;memory &#61; string&#10;&#125;&#41;&#10;requests &#61; object&#40;&#123;&#10;cpu    &#61; string&#10;memory &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#10;ports &#61; list&#40;object&#40;&#123;&#10;name           &#61; string&#10;protocol       &#61; string&#10;container_port &#61; string&#10;&#125;&#41;&#41;&#10;volume_mounts &#61; list&#40;object&#40;&#123;&#10;name       &#61; string&#10;mount_path &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| name | Name used for cloud run service | <code title="">string</code> | ✓ |  |
| project_id | Project id used for all resources. | <code title="">string</code> | ✓ |  |
| *audit_log_triggers* | Event arc triggers (Audit log) | <code title="list&#40;object&#40;&#123;&#10;service_name &#61; string&#10;method_name  &#61; string&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">null</code> |
| *iam* | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *ingress_settings* | Ingress settings | <code title="">string</code> |  | <code title="">null</code> |
| *labels* | Resource labels | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *prefix* | Optional prefix used for resource names. | <code title="">string</code> |  | <code title="">null</code> |
| *pubsub_triggers* | Eventarc triggers (Pub/Sub) | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *region* | Region used for all resources. | <code title="">string</code> |  | <code title="">europe-west1</code> |
| *revision_name* | Revision name | <code title="">string</code> |  | <code title="">null</code> |
| *service_account* | Service account email. Unused if service account is auto-created. | <code title="">string</code> |  | <code title="">null</code> |
| *service_account_create* | Auto-create service account. | <code title="">bool</code> |  | <code title="">false</code> |
| *traffic* | Traffic | <code title="map&#40;number&#41;">map(number)</code> |  | <code title="">null</code> |
| *volumes* | Volumes | <code title="list&#40;object&#40;&#123;&#10;name        &#61; string&#10;secret_name &#61; string&#10;items &#61; list&#40;object&#40;&#123;&#10;key  &#61; string&#10;path &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">null</code> |
| *vpc_connector_config* | VPC connector configuration. Set `create_config` attributes to trigger creation. | <code title="object&#40;&#123;&#10;egress_settings &#61; string&#10;name            &#61; string&#10;ip_cidr_range   &#61; string&#10;network         &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| service | Cloud Run service |  |
| service_account | Service account resource. |  |
| service_account_email | Service account email. |  |
| service_account_iam_email | Service account email. |  |
| service_name | Cloud Run service name |  |
| vpc_connector | VPC connector resource if created. |  |
<!-- END TFDOC -->
