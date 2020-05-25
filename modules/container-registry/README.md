# Google Cloud Container Registry Module

This module simplifies the creation of GCS buckets used by Google Container Registry.

## Example

```hcl
module "container_registry" {
  source     = "../../modules/container-registry"
  project_id = "myproject"
  location   = "EU"
  iam_roles  = ["roles/storage.admin"]
  iam_members = {
    "roles/storage.admin" = ["group:cicd@example.com"]
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Registry project id. | <code title="">string</code> | ✓ |  |
| *iam_members* | Map of member lists used to set authoritative bindings, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">null</code> |
| *iam_roles* | List of roles used to set authoritative bindings. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *location* | Bucket location. Can be US, EU, ASIA or empty | <code title="">string</code> |  | <code title=""></code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket_id | ID of the GCS bucket created |  |
<!-- END TFDOC -->
