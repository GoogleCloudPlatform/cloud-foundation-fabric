# Google Cloud Container Registry Module

This module simplifies the creation of GCS buckets used by Google Container Registry.

## Example

```hcl
module "container_registry" {
  source     = "./modules/container-registry"
  project_id = "myproject"
  location   = "EU"
  iam = {
    "roles/storage.admin" = ["group:cicd@example.com"]
  }
}
# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Registry project id. | <code title="">string</code> | ✓ |  |
| *iam* | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *location* | Registry location. Can be US, EU, ASIA or empty | <code title="">string</code> |  | <code title=""></code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket_id | ID of the GCS bucket created |  |
<!-- END TFDOC -->
