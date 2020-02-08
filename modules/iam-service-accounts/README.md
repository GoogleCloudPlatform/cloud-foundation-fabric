# Google Service Accounts Module

This module allows simplified creation and management of one or more service accounts and their IAM bindings. Keys can optionally be generated and will be stored in Terraform state. To use them create a sensitive output in your root modules referencing the `keys` or `key` outputs, then extract the private key from the JSON formatted outputs.

## Example

```hcl
module "myproject-default-service-accounts" {
  source            = "./modules/iam-service-accounts"
  project_id        = "myproject"
  names             = ["vm-default", "gke-node-default"]
  generate_keys     = true
  # authoritative roles granted *on* the service accounts to other identities
  iam_roles         = ["roles/iam.serviceAccountUser"]
  iam_members       = {
    "roles/iam.serviceAccountUser" => ["user:foo@example.com"]
  }
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "myproject" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project id where service account will be created. | <code title="">string</code> | ✓ |  |
| *generate_keys* | Generate keys for service accounts. | <code title="">bool</code> |  | <code title="">false</code> |
| *iam_billing_roles* | Project roles granted to all service accounts, by billing account id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_folder_roles* | Project roles granted to all service accounts, by folder id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_members* | Map of member lists which are granted authoritative roles on the service accounts, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_organization_roles* | Project roles granted to all service accounts, by organization id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_project_roles* | Project roles granted to all service accounts, by project id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_roles* | List of authoritative roles granted on the service accounts. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_storage_roles* | Storage roles granted to all service accounts, by bucket name. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *names* | Names of the service accounts to create. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *prefix* | Prefix applied to service account names. | <code title="">string</code> |  | <code title=""></code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| email | Service account email (for single use). |  |
| emails | Service account emails. |  |
| emails_list | Service account emails. |  |
| iam_email | IAM-format service account email (for single use). |  |
| iam_emails | IAM-format service account emails. |  |
| iam_emails_list | IAM-format service account emails. |  |
| key | Service account key (for single use). |  |
| keys | Map of service account keys. | ✓ |
| service_account | Service account resource (for single use). |  |
| service_accounts | Service account resources. |  |
<!-- END TFDOC -->
