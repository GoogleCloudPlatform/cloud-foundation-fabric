# Google Cloud Source Repository Module

This module allows managing a single Cloud Source Repository, including IAM bindings.


## Examples

### Simple repository with IAM

```hcl
module "repo" {
  source    e = "./modules/source-repository"
  project_id = "my-project"
  name       = "my-repo"
  iam_roles  = ["roles/source.reader"]
  iam_members = {
    "roles/source.reader" = ["user:foo@example.com"]
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | PubSub topic name. | <code title="">string</code> | ✓ |  |
| project_id | Project used for resources. | <code title="">string</code> | ✓ |  |
| *iam_members* | IAM members for each topic role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_roles* | IAM roles for topic. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | Repository id. |  |
| url | Repository URL. |  |
<!-- END TFDOC -->
