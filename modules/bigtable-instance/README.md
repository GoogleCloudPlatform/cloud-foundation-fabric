# Google Cloud BigTable Module

This module allows managing a single BigTable instance, including access configuration and tables.

## TODO

- [ ] support bigtable_gc_policy
- [ ] support bigtable_app_profile

## Examples

### Simple instance with access configuration

```hcl

module "bigtable-instance" {
  source               = "./modules/bigtable-instance"
  project_id           = "my-project"
  name                 = "instance"
  cluster_id           = "instance"
  zone                 = "europe-west1-b"
  tables               = {
    test1 = null,
    test2 = {
      split_keys    = ["a", "b", "c"]
      column_family = null
    }
  }
  iam       = {
    "roles/bigtable.user" = ["user:viewer@testdomain.com"]
  }
}
# tftest:modules=1:resources=4
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | The name of the Cloud Bigtable instance. | <code title="">string</code> | ✓ |  |
| project_id | Id of the project where datasets will be created. | <code title="">string</code> | ✓ |  |
| zone | The zone to create the Cloud Bigtable cluster in. | <code title="">string</code> | ✓ |  |
| *cluster_id* | The ID of the Cloud Bigtable cluster. | <code title="">string</code> |  | <code title="">europe-west1</code> |
| *deletion_protection* | Whether or not to allow Terraform to destroy the instance. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the instance will fail. | <code title=""></code> |  | <code title="">true</code> |
| *display_name* | The human-readable display name of the Bigtable instance. | <code title=""></code> |  | <code title="">null</code> |
| *iam* | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *instance_type* | (deprecated) The instance type to create. One of 'DEVELOPMENT' or 'PRODUCTION'. | <code title="">string</code> |  | <code title="">null</code> |
| *num_nodes* | The number of nodes in your Cloud Bigtable cluster. | <code title="">number</code> |  | <code title="">1</code> |
| *storage_type* | The storage type to use. | <code title="">string</code> |  | <code title="">SSD</code> |
| *table_options_defaults* | Default option of tables created in the BigTable instance. | <code title="object&#40;&#123;&#10;split_keys    &#61; list&#40;string&#41;&#10;column_family &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;split_keys    &#61; &#91;&#93;&#10;column_family &#61; null&#10;&#125;">...</code> |
| *tables* | Tables to be created in the BigTable instance, options can be null. | <code title="map&#40;object&#40;&#123;&#10;split_keys    &#61; list&#40;string&#41;&#10;column_family &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | An identifier for the resource with format projects/{{project}}/instances/{{name}}. |  |
| instance | BigTable intance. |  |
| table_ids | Map of fully qualified table ids keyed by table name. |  |
| tables | Table resources. |  |
<!-- END TFDOC -->

