# Google Cloud BigTable Module

This module allows managing a single BigTable instance, including access configuration and tables.

## TODO

- [ ] support bigtable_gc_policy
- [ ] support bigtable_app_profile

## Examples

### Simple instance with access configuration

```hcl

module "big-table-instance" {
  source               = "./modules/bigtable-instance"
  project_id           = "my-project"
  name                 = "instance"
  cluster_id           = "instance"
  instance_type        = "PRODUCTION"
  tables               = {
    test1 = { table_options = null },
    test2 = { table_options = {
      split_keys    = ["a", "b", "c"]
      column_family = null
      }
    }
  }
  iam_members       = {
    viewer = ["user:viewer@testdomain.com"]
  }
}
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
| *iam_members* | Authoritative for a given role. Updates the IAM policy to grant a role to a list of members. Other roles within the IAM policy for the instance are preserved. | <code title="map&#40;set&#40;string&#41;&#41;">map(set(string))</code> |  | <code title="">{}</code> |
| *instance_type* | None | <code title="">string</code> |  | <code title="">DEVELOPMENT</code> |
| *num_nodes* | The number of nodes in your Cloud Bigtable cluster. | <code title="">number</code> |  | <code title="">1</code> |
| *storage_type* | The storage type to use. | <code title="">string</code> |  | <code title="">SSD</code> |
| *table_options_defaults* | Default option of tables created in the BigTable instance. | <code title="object&#40;&#123;&#10;split_keys    &#61; list&#40;string&#41;&#10;column_family &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;split_keys    &#61; &#91;&#93;&#10;column_family &#61; null&#10;&#125;">...</code> |
| *tables* | Tables to be created in the BigTable instance. | <code title="map&#40;object&#40;&#123;&#10;table_options &#61; object&#40;&#123;&#10;split_keys    &#61; list&#40;string&#41;&#10;column_family &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | An identifier for the resource with format projects/{{project}}/instances/{{name}}. |  |
| instance | BigTable intance. |  |
| table_ids | Map of fully qualified table ids keyed by table name. |  |
| tables | Table resources. |  |
<!-- END TFDOC -->

