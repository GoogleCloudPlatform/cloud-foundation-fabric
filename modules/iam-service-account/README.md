# Google Service Account Module

This module allows simplified creation and management of one a service account and its IAM bindings. A key can optionally be generated and will be stored in Terraform state. To use it create a sensitive output in your root modules referencing the `key` output, then extract the private key from the JSON formatted outputs.

## Example

```hcl
module "myproject-default-service-accounts" {
  source            = "./modules/iam-service-account"
  project_id        = "myproject"
  name              = "vm-default"
  generate_key      = true
  # authoritative roles granted *on* the service accounts to other identities
  iam       = {
    "roles/iam.serviceAccountUser" = ["user:foo@example.com"]
  }
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "myproject" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
# tftest:modules=1:resources=5
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Name of the service account to create. | <code title="">string</code> | ✓ |  |
| project_id | Project id where service account will be created. | <code title="">string</code> | ✓ |  |
| *display_name* | Display name of the service account to create. | <code title="">string</code> |  | <code title="">Terraform-managed.</code> |
| *generate_key* | Generate a key for service account. | <code title="">bool</code> |  | <code title="">false</code> |
| *iam* | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_billing_roles* | Project roles granted to the service account, by billing account id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_folder_roles* | Project roles granted to the service account, by folder id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_organization_roles* | Project roles granted to the service account, by organization id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_project_roles* | Project roles granted to the service account, by project id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_storage_roles* | Storage roles granted to the service account, by bucket name. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *prefix* | Prefix applied to service account names. | <code title="">string</code> |  | <code title="">null</code> |
| *service_account_create* | Create service account. When set to false, uses a data source to reference an existing service account. | <code title="">bool</code> |  | <code title="">true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| email | Service account email. |  |
| iam_email | IAM-format service account email. |  |
| key | Service account key. | ✓ |
| service_account | Service account resource. |  |
<!-- END TFDOC -->
