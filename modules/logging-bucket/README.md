# Google Cloud Logging Buckets Module

This module manages [logging buckets](https://cloud.google.com/logging/docs/storage#logs-buckets) for a project, folder, organization or billing account.

Note that some logging buckets are automatically created for a given folder, project, organization, and billing account cannot be deleted. Creating a resource of this type will acquire and update the resource that already exists at the desired location. These buckets cannot be removed so deleting this resource will remove the bucket config from your terraform state but will leave the logging bucket unchanged. The buckets that are currently automatically created are "_Default" and "_Required".

See also the `logging_sinks` argument within the [project](../project/), [folder](../folder/) and [organization](../organization) modules.

## Examples

### Create custom logging bucket in a project

```hcl
module "bucket" {
  source      = "./modules/logging-bucket"
  parent_type = "project"
  parent      = var.project_id
  id          = "mybucket"
}
# tftest:modules=1:resources=1
```


### Change retention period of a folder's _Default bucket

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "folders/657104291943"
  name   = "my folder"
}

module "bucket-default" {
  source      = "./modules/logging-bucket"
  parent_type = "folder"
  parent      = module.folder.id
  id          = "_Default"
  retention   = 10
}
# tftest:modules=2:resources=2
```


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| id | Name of the logging bucket. | <code title="">string</code> | ✓ |  |
| parent | ID of the parentresource containing the bucket in the format 'project_id' 'folders/folder_id', 'organizations/organization_id' or 'billing_account_id'. | <code title="">string</code> | ✓ |  |
| parent_type | Parent object type for the bucket (project, folder, organization, billing_account). | <code title="">string</code> | ✓ |  |
| *description* | Human-readable description for the logging bucket. | <code title="">string</code> |  | <code title="">null</code> |
| *location* | Location of the bucket. | <code title="">string</code> |  | <code title="">global</code> |
| *retention* | Retention time in days for the logging bucket. | <code title="">number</code> |  | <code title="">30</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | None |  |
<!-- END TFDOC -->
