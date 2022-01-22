# Project Module

## Examples

### Minimal example with IAM

```hcl
locals {
  gke_service_account = "my_gke_service_account"
}

module "project" {
  source          = "./modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-example"
  parent          = "folders/1234567890"
  prefix          = "foo"
  services        = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  iam = {
    "roles/container.hostServiceAgentUser" = [
      "serviceAccount:${local.gke_service_account}"
    ]
  }
}
# tftest:modules=1:resources=4
```

### Minimal example with IAM additive roles

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-example"

  iam_additive = {
    "roles/viewer"               = ["group:one@example.org", "group:two@xample.org"],
    "roles/storage.objectAdmin"  = ["group:two@example.org"],
    "roles/owner"                = ["group:three@example.org"],
  }
}
# tftest:modules=1:resources=5
```

### Organization policies

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-example"
  parent          = "folders/1234567890"
  prefix          = "foo"
  services        = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  policy_list = {
    "constraints/compute.trustedImageProjects" = {
      inherit_from_parent = null
      suggested_value = null
      status = true
      values = ["projects/my-project"]
    }
  }
}
# tftest:modules=1:resources=6
```

## Logging Sinks
```hcl
module "gcs" {
  source        = "./modules/gcs"
  project_id    = var.project_id
  name          = "gcs_sink"
  force_destroy = true
}

module "dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = var.project_id
  id         = "bq_sink"
}

module "pubsub" {
  source     = "./modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "bucket" {
  source      = "./modules/logging-bucket"
  parent_type = "project"
  parent      = "my-project"
  id          = "bucket"
}

module "project-host" {
  source          = "./modules/project"
  name            = "my-project"
  billing_account = "123456-123456-123456"
  parent          = "folders/1234567890"
  logging_sinks = {
    warnings = {
      type          = "gcs"
      destination   = module.gcs.name
      filter        = "severity=WARNING"
      iam           = false
      unique_writer = false
      exclusions    = {}
    }
    info = {
      type          = "bigquery"
      destination   = module.dataset.id
      filter        = "severity=INFO"
      iam           = false
      unique_writer = false
      exclusions    = {}
    }
    notice = {
      type          = "pubsub"
      destination   = module.pubsub.id
      filter        = "severity=NOTICE"
      iam           = true
      unique_writer = false
      exclusions    = {}
    }
    debug = {
      type          = "logging"
      destination   = module.bucket.id
      filter        = "severity=DEBUG"
      iam           = true
      unique_writer = false
      exclusions = {
        no-compute = "logName:compute"
      }
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest:modules=5:resources=12
```

## Cloud KMS encryption keys

```hcl
module "project" {
  source          = "./modules/project"
  name            = "my-project"
  billing_account = "123456-123456-123456"
  prefix          = "foo"
  services = [
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]
  service_encryption_key_ids = {
    compute = [
      "projects/kms-central-prj/locations/europe-west3/keyRings/my-keyring/cryptoKeys/europe3-gce",
      "projects/kms-central-prj/locations/europe-west4/keyRings/my-keyring/cryptoKeys/europe4-gce"
    ]
    storage = [
      "projects/kms-central-prj/locations/europe/keyRings/my-keyring/cryptoKeys/europe-gcs"
    ]
  }
}
# tftest:modules=1:resources=7
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | modules | resources |
|---|---|---|---|
| [iam.tf](./iam.tf) | Generic and OSLogin-specific IAM bindings and roles. |  | <code>google_project_iam_binding</code> · <code>google_project_iam_custom_role</code> · <code>google_project_iam_member</code> |
| [logging.tf](./logging.tf) | Log sinks and supporting resources. |  | <code>google_bigquery_dataset_iam_member</code> · <code>google_logging_project_exclusion</code> · <code>google_logging_project_sink</code> · <code>google_project_iam_member</code> · <code>google_pubsub_topic_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. |  | <code>google_compute_project_metadata_item</code> · <code>google_essential_contacts_contact</code> · <code>google_monitoring_monitored_project</code> · <code>google_project</code> · <code>google_project_service</code> · <code>google_resource_manager_lien</code> |
| [organization-policies.tf](./organization-policies.tf) | Project-level organization policies. |  | <code>google_project_organization_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [service_accounts.tf](./service_accounts.tf) | Service identities and supporting resources. |  | <code>google_kms_crypto_key_iam_member</code> · <code>google_project_service_identity</code> |
| [shared_vpc.tf](./shared_vpc.tf) | Shared VPC project-level configuration. |  | <code>google_compute_shared_vpc_host_project</code> · <code>google_compute_shared_vpc_service_project</code> |
| [variables.tf](./variables.tf) | Module variables. |  |  |
| [versions.tf](./versions.tf) | Version pins. |  |  |
| [vpc-sc.tf](./vpc-sc.tf) | VPC-SC project-level perimeter configuration. |  | <code>google_access_context_manager_service_perimeter_resource</code> |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| name | Project name and id suffix. | <code>string</code> | ✓ |  |
| auto_create_network | Whether to create the default network for the project | <code>bool</code> |  | <code>false</code> |
| billing_account | Billing account id. | <code>string</code> |  | <code>null</code> |
| contacts | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| custom_roles | Map of role name => list of permissions to create in this project. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| descriptive_name | Name of the project name. Used for project name instead of `name` variable | <code>string</code> |  | <code>null</code> |
| group_iam | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_additive | IAM additive bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_additive_members | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| labels | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| lien_reason | If non-empty, creates a project lien with this description. | <code>string</code> |  | <code>&#34;&#34;</code> |
| logging_exclusions | Logging exclusions for this project in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| logging_sinks | Logging sinks to create for this project. | <code title="map&#40;object&#40;&#123;&#10;  destination   &#61; string&#10;  type          &#61; string&#10;  filter        &#61; string&#10;  iam           &#61; bool&#10;  unique_writer &#61; bool&#10;  exclusions &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| metric_scopes | List of projects that will act as metric scopes for this project. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| oslogin | Enable OS Login. | <code>bool</code> |  | <code>false</code> |
| oslogin_admins | List of IAM-style identities that will be granted roles necessary for OS Login administrators. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| oslogin_users | List of IAM-style identities that will be granted roles necessary for OS Login users. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| parent | Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format. | <code>string</code> |  | <code>null</code> |
| policy_boolean | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code>map&#40;bool&#41;</code> |  | <code>&#123;&#125;</code> |
| policy_list | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; bool&#10;  suggested_value     &#61; string&#10;  status              &#61; bool&#10;  values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| prefix | Prefix used to generate project id and name. | <code>string</code> |  | <code>null</code> |
| project_create | Create project. When set to false, uses a data source to reference existing project. | <code>bool</code> |  | <code>true</code> |
| service_config | Configure service API activation. | <code title="object&#40;&#123;&#10;  disable_on_destroy         &#61; bool&#10;  disable_dependent_services &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  disable_on_destroy         &#61; true&#10;  disable_dependent_services &#61; true&#10;&#125;">&#123;&#8230;&#125;</code> |
| service_encryption_key_ids | Cloud KMS encryption key in {SERVICE => [KEY_URL]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| service_perimeter_bridges | Name of VPC-SC Bridge perimeters to add project into. Specify the name in the form of 'accessPolicies/ACCESS_POLICY_NAME/servicePerimeters/PERIMETER_NAME'. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| service_perimeter_standard | Name of VPC-SC Standard perimeter to add project into. Specify the name in the form of 'accessPolicies/ACCESS_POLICY_NAME/servicePerimeters/PERIMETER_NAME'. | <code>string</code> |  | <code>null</code> |
| services | Service APIs to enable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| shared_vpc_host_config | Configures this project as a Shared VPC host project (mutually exclusive with shared_vpc_service_project). | <code title="object&#40;&#123;&#10;  enabled          &#61; bool&#10;  service_projects &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled          &#61; false&#10;  service_projects &#61; &#91;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |
| shared_vpc_service_config | Configures this project as a Shared VPC service project (mutually exclusive with shared_vpc_host_config). | <code title="object&#40;&#123;&#10;  attach       &#61; bool&#10;  host_project &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  attach       &#61; false&#10;  host_project &#61; &#34;&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| skip_delete | Allows the underlying resources to be destroyed without destroying the project itself. | <code>bool</code> |  | <code>false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| custom_roles | Ids of the created custom roles. |  |
| name | Project name. |  |
| number | Project number. |  |
| project_id | Project id. |  |
| service_accounts | Product robot service accounts in project. |  |
| sink_writer_identities | Writer identities created for each sink. |  |

<!-- END TFDOC -->
