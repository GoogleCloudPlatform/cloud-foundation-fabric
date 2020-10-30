# Google Cloud Source Repository Module

This module allows managing a single Cloud Source Repository, including IAM bindings.


## Examples

### Simple repository with IAM

```hcl
module "repo" {
  source    e = "./modules/source-repository"
  project_id = "my-project"
  name       = "my-repo"
  iam_members = {
    "roles/source.reader" = ["user:foo@example.com"]
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Repository topic name. | <code title="">string</code> | ✓ |  |
| project_id | Project used for resources. | <code title="">string</code> | ✓ |  |
| *iam_members* | IAM members for each topic role. | <code title="map&#40;set&#40;string&#41;&#41;">map(set(string))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | Repository id. |  |
| url | Repository URL. |  |
<!-- END TFDOC -->
