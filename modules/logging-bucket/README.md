# Google Cloud Logging Buckets Module

This module manages [logging buckets](https://cloud.google.com/logging/docs/routing/overview#buckets) for a project, folder, organization or billing account.

Note that some logging buckets are automatically created for a given folder, project, organization, and billing account cannot be deleted. Creating a resource of this type will acquire and update the resource that already exists at the desired location. These buckets cannot be removed so deleting this resource will remove the bucket config from your terraform state but will leave the logging bucket unchanged. The buckets that are currently automatically created are "_Default" and "_Required".

See also the `logging_sinks` argument within the [project](../project/), [folder](../folder/) and [organization](../organization) modules.

<!-- BEGIN TOC -->
- [Custom logging bucket in a project](#custom-logging-bucket-in-a-project)
- [Custom logging bucket in a project with Log Analytics](#custom-logging-bucket-in-a-project-with-log-analytics)
- [Change retention period of a folder _Default bucket](#change-retention-period-of-a-folder-_default-bucket)
- [Organization and billing account buckets](#organization-and-billing-account-buckets)
- [Custom bucket with views](#custom-bucket-with-views)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Custom logging bucket in a project

```hcl
module "bucket" {
  source = "./fabric/modules/logging-bucket"
  parent = var.project_id
  name   = "mybucket"
}
# tftest modules=1 resources=1 inventory=project.yaml
```

## Custom logging bucket in a project with Log Analytics

```hcl
module "bucket" {
  source = "./fabric/modules/logging-bucket"
  parent = var.project_id
  name   = "mybucket"
  log_analytics = {
    enable          = true
    dataset_link_id = "log"
  }
}
# tftest modules=1 resources=2 inventory=log_analytics.yaml
```

## Change retention period of a folder _Default bucket

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = "folders/657104291943"
  name   = "my folder"
}

module "bucket-default" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "folder"
  parent      = module.folder.id
  name        = "_Default"
  retention   = 10
}
# tftest modules=2 resources=2 inventory=retention.yaml
```

## Organization and billing account buckets

```hcl
module "bucket-organization" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "organization"
  parent      = "organizations/012345"
  name        = "mybucket"
}

module "bucket-billing-account" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "billing_account"
  parent      = "012345"
  name        = "mybucket"
}
# tftest modules=2 resources=2 inventory=org-ba.yaml
```

## Custom bucket with views

Views support our standard IAM interface via the following variables:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface. IAM also supports variable interpolation for both roles and principals and for the foreign resources where the service account is the principal, via the respective attributes in the `var.context` variable. Basic usage is shown in the example below.

```hcl
module "bucket" {
  source = "./fabric/modules/logging-bucket"
  parent = var.project_id
  name   = "mybucket"
  context = {
    iam_principals = {
      myuser = "user:user@example.com"
    }
  }
  views = {
    myview = {
      filter = "LOG_ID(\"stdout\")"
      iam = {
        "roles/logging.viewAccessor" = ["$iam_principals:myuser"]
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=views.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L60) | Name of the logging bucket. | <code>string</code> | ✓ |  |
| [parent](variables.tf#L65) | ID of the parent resource containing the bucket in the format 'project_id' 'folders/folder_id', 'organizations/organization_id' or 'billing_account_id'. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L31) | Human-readable description for the logging bucket. | <code>string</code> |  | <code>null</code> |
| [kms_key_name](variables.tf#L37) | To enable CMEK for a project logging bucket, set this field to a valid name. The associated service account requires cloudkms.cryptoKeyEncrypterDecrypter roles assigned for the key. | <code>string</code> |  | <code>null</code> |
| [location](variables.tf#L43) | Location of the bucket. | <code>string</code> |  | <code>&#34;global&#34;</code> |
| [log_analytics](variables.tf#L49) | Enable and configure Analytics Log. | <code title="object&#40;&#123;&#10;  enable          &#61; optional&#40;bool, false&#41;&#10;  dataset_link_id &#61; optional&#40;string&#41;&#10;  description     &#61; optional&#40;string, &#34;Log Analytics Dataset&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [parent_type](variables.tf#L73) | Parent object type for the bucket (project, folder, organization, billing_account). | <code>string</code> |  | <code>&#34;project&#34;</code> |
| [retention](variables.tf#L80) | Retention time in days for the logging bucket. | <code>number</code> |  | <code>30</code> |
| [tag_bindings](variables.tf#L86) | Tag bindings for this bucket, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [views](variables.tf#L93) | Log views for this bucket. | <code title="map&#40;object&#40;&#123;&#10;  filter      &#61; string&#10;  location    &#61; optional&#40;string&#41;&#10;  description &#61; optional&#40;string&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified logging bucket id. |  |
| [view_ids](outputs.tf#L22) | The automatic and user-created views in this bucket. |  |
<!-- END TFDOC -->
