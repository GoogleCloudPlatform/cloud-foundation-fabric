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
# tftest modules=1 resources=5
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L71) | Name of the service account to create. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L82) | Project id where service account will be created. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | Optional description. | <code>string</code> |  | <code>null</code> |
| [display_name](variables.tf#L23) | Display name of the service account to create. | <code>string</code> |  | <code>&#34;Terraform-managed.&#34;</code> |
| [generate_key](variables.tf#L29) | Generate a key for service account. | <code>bool</code> |  | <code>false</code> |
| [iam](variables.tf#L35) | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_billing_roles](variables.tf#L41) | Billing account roles granted to the service account, by billing account id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_folder_roles](variables.tf#L47) | Folder roles granted to the service account, by folder id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_organization_roles](variables.tf#L53) | Organization roles granted to the service account, by organization id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_project_roles](variables.tf#L59) | Project roles granted to the service account, by project id. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_storage_roles](variables.tf#L65) | Storage roles granted to the service account, by bucket name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L76) | Prefix applied to service account names. | <code>string</code> |  | <code>null</code> |
| [public_keys_directory](variables.tf#L87) | Path to public keys data files to upload to the service account (should have `.pem` extension). | <code>string</code> |  | <code>&#34;&#34;</code> |
| [service_account_create](variables.tf#L93) | Create service account. When set to false, uses a data source to reference an existing service account. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [email](outputs.tf#L17) | Service account email. |  |
| [iam_email](outputs.tf#L25) | IAM-format service account email. |  |
| [key](outputs.tf#L33) | Service account key. | ✓ |
| [service_account](outputs.tf#L39) | Service account resource. |  |
| [service_account_credentials](outputs.tf#L44) | Service account json credential templates for uploaded public keys data. |  |

<!-- END TFDOC -->
