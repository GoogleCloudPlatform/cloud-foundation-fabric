# Cloud Function Module (V1)

Cloud Function management, with support for IAM roles and optional bucket creation.

The GCS object used for deployment uses a hash of the bundle zip contents in its name, which ensures change tracking and avoids recreating the function if the GCS object is deleted and needs recreating.

<!-- BEGIN TOC -->
- [TODO](#todo)
- [Examples](#examples)
  - [HTTP trigger](#http-trigger)
  - [PubSub and non-HTTP triggers](#pubsub-and-non-http-triggers)
  - [Controlling HTTP access](#controlling-http-access)
  - [GCS bucket creation](#gcs-bucket-creation)
  - [Service account management](#service-account-management)
  - [Custom bundle config](#custom-bundle-config)
  - [Private Cloud Build Pool](#private-cloud-build-pool)
  - [Multiple Cloud Functions within project](#multiple-cloud-functions-within-project)
  - [Mounting secrets from Secret Manager](#mounting-secrets-from-secret-manager)
  - [Using CMEK to encrypt function resources](#using-cmek-to-encrypt-function-resources)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## TODO

- [ ] add support for `source_repository`

## Examples

### HTTP trigger

This deploys a Cloud Function with an HTTP endpoint, using a pre-existing GCS bucket for deployment, setting the service account to the Cloud Function default one, and delegating access control to the containing project.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path        = "assets/sample-function/"
    output_path = "bundle.zip"
  }
}
# tftest modules=1 resources=2 e2e
```

### PubSub and non-HTTP triggers

Other trigger types other than HTTP are configured via the `trigger_config` variable. This example shows a PubSub trigger.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = "local.my-topic"
  }
}
# tftest modules=1 resources=2
```

### Controlling HTTP access

To allow anonymous access to the function, grant the `roles/cloudfunctions.invoker` role to the special `allUsers` identifier. Use specific identities (service accounts, groups, etc.) instead of `allUsers` to only allow selective access.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
  iam = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
}
# tftest modules=1 resources=3 inventory=iam.yaml
```

### GCS bucket creation

You can have the module auto-create the GCS bucket used for deployment via the `bucket_config` variable. Setting `bucket_config.location` to `null` will also use the function region for GCS.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  prefix      = "my-prefix"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bucket_config = {
    lifecycle_delete_age_days = 1
  }
  bundle_config = {
    path = "fabric/assets/"
  }
}
# tftest modules=1 resources=3 inventory=bucket-creation.yaml
```

### Service account management

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` value (default).

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
  service_account_create = true
}
# tftest modules=1 resources=3
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to `false` (the default).

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
  service_account = "non-existent@serice.account.email"
}
# tftest modules=1 resources=2
```

### Custom bundle config

The Cloud Function bundle can be configured via the `bundle_config` variable, so that either a `zip` archive or a source folder can be used.

If a `zip` archive is already available, simply set the archive path in `bundle_config.path`. If a dynamically generated archive is needed, set `bundle_config.path` to the source folder path, then optionally configure the path where the archive will be created, and any exclusions needed in the archive.

If you use a folder and dynamic archive bundling, be mindful that the MD5 checksum of the generated `zip` file does not change across environments (e.g. Cloud Build vs your local development environment), by ensuring that the files in the folder are always the same.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
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
  source            = "./fabric/modules/cloud-function-v1"
  project_id        = "my-project"
  region            = "europe-west1"
  name              = "test-cf-http"
  bucket_name       = "test-cf-bundles"
  build_worker_pool = "projects/my-project/locations/europe-west1/workerPools/my_build_worker_pool"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
}
# tftest modules=1 resources=2
```

### Multiple Cloud Functions within project

When deploying multiple functions do not reuse `bundle_config.output_path` between instances as the result is undefined. Default `output_path` creates file in `/tmp` folder using project Id and function name to avoid name conflicts.

```hcl
module "cf-http-one" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http-one"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path = "fabric/assets"
  }
}

module "cf-http-two" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http-two"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path = "fabric/assets"
  }
}
# tftest modules=2 resources=4 inventory=multiple_functions.yaml
```

### Mounting secrets from Secret Manager

This provides the latest value of the secret `var_secret` as `VARIABLE_SECRET` environment variable and three values of `path_secret` mounted in filesystem:

- `/app/secret/first` contains version 1
- `/app/secret/second` contains version 2
- `/app/secret/latest` contains latest version of the secret

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
  secrets = {
    VARIABLE_SECRET = {
      is_volume  = false
      project_id = 1234567890
      secret     = "var_secret"
      versions = [
        "latest"
      ]
    }
    "/app/secret" = {
      is_volume  = true
      project_id = 1234567890
      secret     = "path_secret"
      versions = [
        "1:first",
        "2:second",
        "latest:latest"
      ]
    }
  }
}
# tftest modules=1 resources=2  inventory=secrets.yaml
```

### Using CMEK to encrypt function resources

This encrypt bucket _gcf-sources-*_ with the provided kms key. The repository has to be encrypted with the same kms key.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = "my-project"
  region      = "europe-west1"
  name        = "test-cf-http"
  bucket_name = "test-cf-bundles"
  bundle_config = {
    path        = "fabric/assets/"
    output_path = "bundle.zip"
  }
  kms_key = "projects/my-project/locations/europe-west1/keyRings/mykeyring/cryptoKeys/mykey"
  repository_settings = {
    repository = "projects/my-project/locations/europe-west1/repositories/myrepo"
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [bucket_name](variables.tf#L26) | Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null. | <code>string</code> | ✓ |  |
| [bundle_config](variables.tf#L44) | Cloud function source. If path points to a .zip archive it is uploaded as-is, otherwise an archive is created on the fly. A null output path will use a unique name for the bundle in /tmp. | <code title="object&#40;&#123;&#10;  path        &#61; string&#10;  excludes    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  output_path &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L115) | Name used for cloud function and associated resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L130) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L135) | Region used for all resources. | <code>string</code> | ✓ |  |
| [bucket_config](variables.tf#L17) | Enable and configure auto-created bucket. Set fields to null to use defaults. | <code title="object&#40;&#123;&#10;  location                  &#61; optional&#40;string&#41;&#10;  lifecycle_delete_age_days &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [build_environment_variables](variables.tf#L32) | A set of key/value environment variable pairs available during build time. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [build_worker_pool](variables.tf#L38) | Build worker pool, in projects/<PROJECT-ID>/locations/<REGION>/workerPools/<POOL_NAME> format. | <code>string</code> |  | <code>null</code> |
| [description](variables.tf#L53) | Optional description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [environment_variables](variables.tf#L59) | Cloud function environment variables. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [function_config](variables.tf#L65) | Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout. | <code title="object&#40;&#123;&#10;  entry_point     &#61; optional&#40;string, &#34;main&#34;&#41;&#10;  instance_count  &#61; optional&#40;number, 1&#41;&#10;  memory_mb       &#61; optional&#40;number, 256&#41; &#35; Memory in MB&#10;  cpu             &#61; optional&#40;string, &#34;0.166&#34;&#41;&#10;  runtime         &#61; optional&#40;string, &#34;python310&#34;&#41;&#10;  timeout_seconds &#61; optional&#40;number, 180&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  entry_point     &#61; &#34;main&#34;&#10;  instance_count  &#61; 1&#10;  memory_mb       &#61; 256&#10;  cpu             &#61; &#34;0.166&#34;&#10;  runtime         &#61; &#34;python310&#34;&#10;  timeout_seconds &#61; 180&#10;&#125;">&#123;&#8230;&#125;</code> |
| [https_security_level](variables.tf#L85) | The security level for the function: Allowed values are SECURE_ALWAYS, SECURE_OPTIONAL. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L91) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_settings](variables.tf#L97) | Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL, ALLOW_INTERNAL_AND_GCLB and ALLOW_INTERNAL_ONLY . | <code>string</code> |  | <code>null</code> |
| [kms_key](variables.tf#L103) | Resource name of a KMS crypto key (managed by the user) used to encrypt/decrypt function resources in key id format. If specified, you must also provide an artifact registry repository using the docker_repository field that was created with the same KMS crypto key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L109) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L120) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [repository_settings](variables.tf#L140) | Docker Registry to use for storing the function's Docker images and specific repository. If kms_key is provided, the repository must have already been encrypted with the key. | <code title="object&#40;&#123;&#10;  registry   &#61; optional&#40;string&#41;&#10;  repository &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  registry &#61; &#34;ARTIFACT_REGISTRY&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [secrets](variables.tf#L151) | Secret Manager secrets. Key is the variable name or mountpoint, volume versions are in version:path format. | <code title="map&#40;object&#40;&#123;&#10;  is_volume  &#61; bool&#10;  project_id &#61; number&#10;  secret     &#61; string&#10;  versions   &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L163) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L169) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [trigger_config](variables.tf#L175) | Function trigger configuration. Leave null for HTTP trigger. | <code title="object&#40;&#123;&#10;  event    &#61; string&#10;  resource &#61; string&#10;  retry    &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_connector](variables.tf#L185) | VPC connector configuration. Set create to 'true' if a new connector needs to be created. | <code title="object&#40;&#123;&#10;  create          &#61; bool&#10;  name            &#61; string&#10;  egress_settings &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_connector_config](variables.tf#L195) | VPC connector network configuration. Must be provided if new VPC connector is being created. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; string&#10;  network       &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bucket](outputs.tf#L17) | Bucket resource (only if auto-created). |  |
| [bucket_name](outputs.tf#L24) | Bucket name. |  |
| [function](outputs.tf#L29) | Cloud function resources. |  |
| [function_name](outputs.tf#L34) | Cloud function name. |  |
| [id](outputs.tf#L39) | Fully qualified function id. |  |
| [service_account](outputs.tf#L44) | Service account resource. |  |
| [service_account_email](outputs.tf#L49) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L54) | Service account email. |  |
| [vpc_connector](outputs.tf#L62) | VPC connector resource if created. |  |
<!-- END TFDOC -->
