# Terraform Service Accounts Module

This module allows easy creation of one or more service accounts, and granting them basic roles.

## Example

```hcl
module "serviceprj-service-accounts" {
  source        = "./modules/iam-service-accounts"
  project_id    = module.service-project.project_id
  names         = ["vm-default", "gke-node-default"]
  generate_keys = true
  iam_project_roles = {
    "${module.service-project.project_id}" = [
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
| *iam_billing_roles* | Project roles applied to all service accounts, by billing account id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_folder_roles* | Project roles applied to all service accounts, by folder id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_organization_roles* | Project roles applied to all service accounts, by organization id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_project_roles* | Project roles applied to all service accounts, by project id. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
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

## Requirements

### IAM

Service account or user credentials with the following roles must be used to provision the resources of this module:

- Service Account Admin: `roles/iam.serviceAccountAdmin`
- (optional) Service Account Key Admin: `roles/iam.serviceAccountAdmin` when `generate_keys` is set to `true`
- (optional) roles needed to grant optional IAM roles at the project or organizational level
