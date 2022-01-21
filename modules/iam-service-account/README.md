# Google Service Account Module

This module allows simplified creation and management of one a service account and its IAM bindings. A key can optionally be generated and will be stored in Terraform state. To use it create a sensitive output in your root modules referencing the `key` output, then extract the private key from the JSON formatted outputs. Alternatively, the `key` can be generated with `openssl` library and only public part uploaded to the Service Account, for more refer to the [Onprem SA Key Management](../../examples/cloud-operations/onprem-sa-key-management/) example.

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
|---|---|:---:|:---:|:---:|
| name | Name of the service account to create. | <code>string</code> | ✓ |  |
| project_id | Project id where service account will be created. | <code>string</code> | ✓ |  |
| description | Optional description. | <code>string</code> |  | <code>null</code> |
| display_name | Display name of the service account to create. | <code>string</code> |  | <code>&#34;Terraform-managed.&#34;</code> |
| generate_key | Generate a key for service account. | <code>bool</code> |  | <code>false</code> |
| iam | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_billing_roles | Billing account roles granted to the service account, by billing account id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_folder_roles | Folder roles granted to the service account, by folder id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_organization_roles | Organization roles granted to the service account, by organization id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_project_roles | Project roles granted to the service account, by project id. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam_storage_roles | Storage roles granted to the service account, by bucket name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| prefix | Prefix applied to service account names. | <code>string</code> |  | <code>null</code> |
| public_keys_directory | Path to public keys data files to upload to the service account (should have `.pem` extension). | <code>string</code> |  | <code>&#34;&#34;</code> |
| service_account_create | Create service account. When set to false, uses a data source to reference an existing service account. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| email | Service account email. |  |
| iam_email | IAM-format service account email. |  |
| key | Service account key. | ✓ |
| service_account | Service account resource. |  |
| service_account_credentials | Service account json credential templates for uploaded public keys data. |  |

<!-- END TFDOC -->
