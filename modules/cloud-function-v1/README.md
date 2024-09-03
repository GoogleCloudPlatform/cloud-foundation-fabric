# Cloud Function Module (V1)

Cloud Function management, with support for IAM roles, optional bucket creation and bundle via GCS URI, local zip, or local source folder.

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
- [Fixtures](#fixtures)
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
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest modules=1 resources=5 fixtures=fixtures/functions-default-sa-iam-grants.tf e2e
```

### PubSub and non-HTTP triggers

Other trigger types other than HTTP are configured via the `trigger_config` variable. This example shows a PubSub trigger.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  trigger_config = {
    event    = "google.pubsub.topic.publish"
    resource = module.pubsub.topic.name
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]

}
# tftest modules=2 resources=7 fixtures=fixtures/pubsub.tf,fixtures/functions-default-sa-iam-grants.tf e2e
```

### Controlling HTTP access

To allow anonymous access to the function, grant the `roles/cloudfunctions.invoker` role to the special `allUsers` identifier. Use specific identities (service accounts, groups, etc.) instead of `allUsers` to only allow selective access.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  iam = {
    "roles/cloudfunctions.invoker" = ["allUsers"]
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest fixtures=fixtures/functions-default-sa-iam-grants.tf inventory=iam.yaml e2e
```

### GCS bucket creation

You can have the module auto-create the GCS bucket used for deployment via the `bucket_config` variable. Setting `bucket_config.location` to `null` will also use the function region for GCS.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  prefix      = var.prefix
  name        = "test-cf-http"
  bucket_name = var.bucket
  bucket_config = {
    force_destroy             = true
    lifecycle_delete_age_days = 1
  }
  bundle_config = {
    path = "assets/sample-function/"
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest fixtures=fixtures/functions-default-sa-iam-grants.tf inventory=bucket-creation.yaml e2e
```

### Service account management

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` value (default).

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  service_account_create = true
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest modules=1 resources=6 fixtures=fixtures/functions-default-sa-iam-grants.tf e2e
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to `false` (the default).

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  service_account = var.service_account.email
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest modules=1 resources=5 fixtures=fixtures/functions-default-sa-iam-grants.tf e2e
```

### Custom bundle config

The Cloud Function bundle can be configured via the `bundle_config` variable. The only mandatory argument is `bundle_config.path` which can point to:

- a GCS URI of a ZIP archive
- a local path to a ZIP archive
- a local path to a source folder

When a GCS URI or a local zip file are used, a change in their names will trigger redeployment. When a local source folder is used a ZIP archive will be automatically generated and its internally derived checksum will drive redeployment. You can optionally control its name and exclusions via the attributes in `bundle_config.folder_options`.

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
    folder_options = {
      archive_path = "bundle.zip"
      excludes     = ["__pycache__"]
    }
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest modules=1 resources=5 fixtures=fixtures/functions-default-sa-iam-grants.tf  e2e
```

### Private Cloud Build Pool

This deploys a Cloud Function with an HTTP endpoint, using a pre-existing GCS bucket for deployment using a pre existing private Cloud Build worker pool.

```hcl
module "cf-http" {
  source            = "./fabric/modules/cloud-function-v1"
  project_id        = var.project_id
  region            = var.regions.secondary
  name              = "test-cf-http"
  bucket_name       = var.bucket
  build_worker_pool = google_cloudbuild_worker_pool.pool.id
  bundle_config = {
    path = "assets/sample-function/"
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest modules=1 resources=6 fixtures=fixtures/cloudbuild-custom-pool.tf,fixtures/functions-default-sa-iam-grants.tf e2e
```

### Multiple Cloud Functions within project

When deploying multiple functions do not reuse `bundle_config.archive_path` between instances as the result is undefined. Default `archive_path` creates file in `/tmp` folder using project Id and function name to avoid name conflicts.

```hcl
module "cf-http-one" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http-one"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
}

module "cf-http-two" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http-two"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest fixtures=fixtures/functions-default-sa-iam-grants.tf inventory=multiple_functions.yaml e2e
```

### Mounting secrets from Secret Manager

This provides the latest value of the secret `var_secret` as `VARIABLE_SECRET` environment variable and three values of `path_secret` mounted in filesystem:

- `/app/secret/ver1` contains version referenced by `module.secret-manager.version_versions["credentials:v1"]`

```hcl
module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = var.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  secrets = {
    VARIABLE_SECRET = {
      is_volume  = false
      project_id = var.project_number # use project_number  to avoid perm-diff
      secret     = reverse(split("/", module.secret-manager.secrets["credentials"].name))[0]
      versions = [
        "latest"
      ]
    }
    "/app/secret" = {
      is_volume  = true
      project_id = var.project_number # use project_number  to avoid perm-diff
      secret     = reverse(split("/", module.secret-manager.secrets["credentials"].name))[0]
      versions = [
        "${module.secret-manager.version_versions["credentials:v1"]}:/ver1"
      ]
    }
  }
  depends_on = [
    google_project_iam_member.bucket_default_compute_account_grant,
  ]
}
# tftest fixtures=fixtures/secret-credentials.tf,fixtures/functions-default-sa-iam-grants.tf  inventory=secrets.yaml e2e
```

### Using CMEK to encrypt function resources

This encrypt bucket _gcf-sources-*_ with the provided kms key. The repository has to be encrypted with the same kms key.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "cf-v1"
  billing_account = var.billing_account_id
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
  ]
  iam = {
    # grant compute default service account that is used by Cloud Founction
    # permission to read from the buckets so it can function sources
    "roles/storage.objectViewer" = [
      "serviceAccount:${module.project.default_service_accounts.compute}"
    ]
  }
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.regions.secondary
    name     = "keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents["artifactregistry"].iam_email,
      module.project.service_agents["cloudfunctions"].iam_email,
      module.project.service_agents["storage"].iam_email,
    ]
  }
}

module "artifact-registry" {
  source         = "./fabric/modules/artifact-registry"
  project_id     = module.project.project_id
  location       = var.regions.secondary
  name           = "registry"
  format         = { docker = { standard = {} } }
  encryption_key = module.kms.key_ids["key-regional"]
  iam = {
    "roles/artifactregistry.createOnPushWriter" = [
      # grant compute default service account that is used by Cloud Build
      # permission to push compiled container into Artifact Registry
      "serviceAccount:${module.project.default_service_accounts.compute}",
    ]
  }
}

module "cf-http" {
  source      = "./fabric/modules/cloud-function-v1"
  project_id  = module.project.project_id
  region      = var.regions.secondary
  name        = "test-cf-http"
  bucket_name = var.bucket
  bundle_config = {
    path = "assets/sample-function/"
  }
  kms_key = module.kms.key_ids["key-regional"]
  repository_settings = {
    repository = module.artifact-registry.id
  }
}
# tftest modules=4 resources=25
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [bucket_name](variables.tf#L27) | Name of the bucket that will be used for the function code. It will be created with prefix prepended if bucket_config is not null. | <code>string</code> | ✓ |  |
| [bundle_config](variables.tf#L45) | Cloud function source. Path can point to a GCS object URI, or a local path. A local path to a zip archive will generate a GCS object using its basename, a folder will be zipped and the GCS object name inferred when not specified. | <code title="object&#40;&#123;&#10;  path &#61; string&#10;  folder_options &#61; optional&#40;object&#40;&#123;&#10;    archive_path &#61; optional&#40;string&#41;&#10;    excludes     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L140) | Name used for cloud function and associated resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L155) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L160) | Region used for all resources. | <code>string</code> | ✓ |  |
| [bucket_config](variables.tf#L17) | Enable and configure auto-created bucket. Set fields to null to use defaults. | <code title="object&#40;&#123;&#10;  force_destroy             &#61; optional&#40;bool&#41;&#10;  lifecycle_delete_age_days &#61; optional&#40;number&#41;&#10;  location                  &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [build_environment_variables](variables.tf#L33) | A set of key/value environment variable pairs available during build time. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [build_worker_pool](variables.tf#L39) | Build worker pool, in projects/<PROJECT-ID>/locations/<REGION>/workerPools/<POOL_NAME> format. | <code>string</code> |  | <code>null</code> |
| [description](variables.tf#L78) | Optional description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [environment_variables](variables.tf#L84) | Cloud function environment variables. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [function_config](variables.tf#L90) | Cloud function configuration. Defaults to using main as entrypoint, 1 instance with 256MiB of memory, and 180 second timeout. | <code title="object&#40;&#123;&#10;  entry_point     &#61; optional&#40;string, &#34;main&#34;&#41;&#10;  instance_count  &#61; optional&#40;number, 1&#41;&#10;  memory_mb       &#61; optional&#40;number, 256&#41; &#35; Memory in MB&#10;  cpu             &#61; optional&#40;string, &#34;0.166&#34;&#41;&#10;  runtime         &#61; optional&#40;string, &#34;python310&#34;&#41;&#10;  timeout_seconds &#61; optional&#40;number, 180&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  entry_point     &#61; &#34;main&#34;&#10;  instance_count  &#61; 1&#10;  memory_mb       &#61; 256&#10;  cpu             &#61; &#34;0.166&#34;&#10;  runtime         &#61; &#34;python310&#34;&#10;  timeout_seconds &#61; 180&#10;&#125;">&#123;&#8230;&#125;</code> |
| [https_security_level](variables.tf#L110) | The security level for the function: Allowed values are SECURE_ALWAYS, SECURE_OPTIONAL. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L116) | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_settings](variables.tf#L122) | Control traffic that reaches the cloud function. Allowed values are ALLOW_ALL, ALLOW_INTERNAL_AND_GCLB and ALLOW_INTERNAL_ONLY . | <code>string</code> |  | <code>null</code> |
| [kms_key](variables.tf#L128) | Resource name of a KMS crypto key (managed by the user) used to encrypt/decrypt function resources in key id format. If specified, you must also provide an artifact registry repository using the docker_repository field that was created with the same KMS crypto key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L134) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L145) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [repository_settings](variables.tf#L165) | Docker Registry to use for storing the function's Docker images and specific repository. If kms_key is provided, the repository must have already been encrypted with the key. | <code title="object&#40;&#123;&#10;  registry   &#61; optional&#40;string&#41;&#10;  repository &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  registry &#61; &#34;ARTIFACT_REGISTRY&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [secrets](variables.tf#L176) | Secret Manager secrets. Key is the variable name or mountpoint, volume versions are in version:path format. | <code title="map&#40;object&#40;&#123;&#10;  is_volume  &#61; bool&#10;  project_id &#61; string&#10;  secret     &#61; string&#10;  versions   &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L188) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L194) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [trigger_config](variables.tf#L200) | Function trigger configuration. Leave null for HTTP trigger. | <code title="object&#40;&#123;&#10;  event    &#61; string&#10;  resource &#61; string&#10;  retry    &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_connector](variables.tf#L210) | VPC connector configuration. Set create to 'true' if a new connector needs to be created. | <code title="object&#40;&#123;&#10;  create          &#61; bool&#10;  name            &#61; string&#10;  egress_settings &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [vpc_connector_config](variables.tf#L220) | VPC connector network configuration. Must be provided if new VPC connector is being created. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; string&#10;  network       &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

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

## Fixtures

- [cloudbuild-custom-pool.tf](../../tests/fixtures/cloudbuild-custom-pool.tf)
- [functions-default-sa-iam-grants.tf](../../tests/fixtures/functions-default-sa-iam-grants.tf)
- [pubsub.tf](../../tests/fixtures/pubsub.tf)
- [secret-credentials.tf](../../tests/fixtures/secret-credentials.tf)
<!-- END TFDOC -->
