# Terraform Service Accounts Module

This module allows easy creation of one or more service accounts, and granting them basic roles.

The resources/services/activations/deletions that this module will create/trigger are:

- one or more service accounts
- optional non-autoritative IAM role bindings for each service account for the following resource types
  - organization
  - billing account
  - folder
  - project
- one optional service account key per service account

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| project_id | Project id where service account will be created. | `string` | ✓
| *generate_keys* | Generate keys for service accounts. | `bool` | 
| *iam_billing_roles* | Project roles applied to all service accounts, by billing account id. | `map(list(string))` | 
| *iam_folder_roles* | Project roles applied to all service accounts, by folder id. | `map(list(string))` | 
| *iam_organization_roles* | Project roles applied to all service accounts, by organization id. | `map(list(string))` | 
| *iam_project_roles* | Project roles applied to all service accounts, by project id. | `map(list(string))` | 
| *names* | Names of the service accounts to create. | `list(string)` | 
| *prefix* | Prefix applied to service account names. | `string` | 

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
