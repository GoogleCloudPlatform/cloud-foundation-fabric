# Google Cloud Logging Buckets Module

This module manages [logging buckets](https://cloud.google.com/logging/docs/routing/overview#buckets) for a project, folder, organization or billing account.

Note that some logging buckets are automatically created for a given folder, project, organization, and billing account cannot be deleted. Creating a resource of this type will acquire and update the resource that already exists at the desired location. These buckets cannot be removed so deleting this resource will remove the bucket config from your terraform state but will leave the logging bucket unchanged. The buckets that are currently automatically created are "_Default" and "_Required".

See also the `logging_sinks` argument within the [project](../project/), [folder](../folder/) and [organization](../organization) modules.

## Examples

### Create custom logging bucket in a project

```hcl
module "bucket" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "project"
  parent      = var.project_id
  id          = "mybucket"
}
# tftest modules=1 resources=1 inventory=project.yaml
```

### Create custom logging bucket in a project enabling Log Analytics and dataset link

```hcl
module "bucket" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "project"
  parent      = var.project_id
  id          = "mybucket"
  log_analytics = {
    enable          = true
    dataset_link_id = "log"
  }
}
# tftest modules=1 resources=2 inventory=log_analytics.yaml
```

### Change retention period of a folder's _Default bucket

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
  id          = "_Default"
  retention   = 10
}
# tftest modules=2 resources=2 inventory=retention.yaml
```

### Organization and billing account buckets

```hcl
module "bucket-organization" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "organization"
  parent      = "organizations/012345"
  id          = "mybucket"
}

module "bucket-billing-account" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "billing_account"
  parent      = "012345"
  id          = "mybucket"
}
# tftest modules=2 resources=2 inventory=org-ba.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [id](variables.tf#L23) | Name of the logging bucket. | <code>string</code> | ✓ |  |
| [parent](variables.tf#L51) | ID of the parentresource containing the bucket in the format 'project_id' 'folders/folder_id', 'organizations/organization_id' or 'billing_account_id'. | <code>string</code> | ✓ |  |
| [parent_type](variables.tf#L56) | Parent object type for the bucket (project, folder, organization, billing_account). | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | Human-readable description for the logging bucket. | <code>string</code> |  | <code>null</code> |
| [kms_key_name](variables.tf#L28) | To enable CMEK for a project logging bucket, set this field to a valid name. The associated service account requires cloudkms.cryptoKeyEncrypterDecrypter roles assigned for the key. | <code>string</code> |  | <code>null</code> |
| [location](variables.tf#L34) | Location of the bucket. | <code>string</code> |  | <code>&#34;global&#34;</code> |
| [log_analytics](variables.tf#L40) | Enable and configure Analytics Log. | <code title="object&#40;&#123;&#10;  enable          &#61; optional&#40;bool, false&#41;&#10;  dataset_link_id &#61; optional&#40;string&#41;&#10;  description     &#61; optional&#40;string, &#34;Log Analytics Dataset&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [retention](variables.tf#L61) | Retention time in days for the logging bucket. | <code>number</code> |  | <code>30</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified logging bucket id. |  |
<!-- END TFDOC -->
