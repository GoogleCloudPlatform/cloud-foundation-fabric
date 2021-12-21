# Google Cloud Source Repository Module

This module allows managing a single Cloud Source Repository, including IAM bindings.


## Examples

### Simple repository with IAM

```hcl
module "repo" {
  source     = "./modules/source-repository"
  project_id = "my-project"
  name       = "my-repo"
  iam = {
    "roles/source.reader" = ["user:foo@example.com"]
  }
}
# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| name | Repository name. | <code>string</code> | ✓ |  |
| project_id | Project used for resources. | <code>string</code> | ✓ |  |
| iam | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | Repository id. |  |
| url | Repository URL. |  |


<!-- END TFDOC -->
