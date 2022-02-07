# Google Cloud Unit Folders Module

This module allows creation and management of an organizational hierarchy "unit" composed of a parent folder (usually mapped to a business unit or team), and a set of child folders (usually mapped to environments) each with a corresponding set of service accounts, IAM bindings and GCS buckets.

## Example

```hcl
module "folders-unit" {
  source                = "./modules/folders-unit"
  name                  = "Business Intelligence"
  short_name            = "bi"
  automation_project_id = "automation-project-394yr923811"
  billing_account_id    = "015617-16GHBC-AF02D9"
  organization_id       = "506128240800"
  root_node             = "folders/93469270123701"
  prefix                = "unique-prefix"
  environments          = {
    dev = "Development",
    test = "Testing",
    prod = "Production"
  }
  service_account_keys  = true
}
# tftest modules=1 resources=37
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [automation_project_id](variables.tf#L17) | Project id used for automation service accounts. | <code>string</code> | ✓ |  |
| [billing_account_id](variables.tf#L22) | Country billing account account. | <code>string</code> | ✓ |  |
| [name](variables.tf#L86) | Top folder name. | <code>string</code> | ✓ |  |
| [organization_id](variables.tf#L91) | Organization id in organizations/nnnnnn format. | <code>string</code> | ✓ |  |
| [root_node](variables.tf#L102) | Root node in folders/folder_id or organizations/org_id format. | <code>string</code> | ✓ |  |
| [short_name](variables.tf#L113) | Short name used as GCS bucket and service account prefixes, do not use capital letters or spaces. | <code>string</code> | ✓ |  |
| [environments](variables.tf#L27) | Unit environments short names. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  non-prod &#61; &#34;Non production&#34;&#10;  prod     &#61; &#34;Production&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [gcs_defaults](variables.tf#L36) | Defaults use for the state GCS buckets. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  location      &#61; &#34;EU&#34;&#10;  storage_class &#61; &#34;MULTI_REGIONAL&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [iam](variables.tf#L45) | IAM bindings for the top-level folder in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_billing_config](variables.tf#L51) | Grant billing user role to service accounts, defaults to granting on the billing account. | <code title="object&#40;&#123;&#10;  grant      &#61; bool&#10;  target_org &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  grant      &#61; true&#10;  target_org &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [iam_enviroment_roles](variables.tf#L63) | IAM roles granted to the environment service account on the environment sub-folder. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;roles&#47;compute.networkAdmin&#34;,&#10;  &#34;roles&#47;owner&#34;,&#10;  &#34;roles&#47;resourcemanager.folderAdmin&#34;,&#10;  &#34;roles&#47;resourcemanager.projectCreator&#34;,&#10;&#93;">&#91;&#8230;&#93;</code> |
| [iam_xpn_config](variables.tf#L74) | Grant Shared VPC creation roles to service accounts, defaults to granting at folder level. | <code title="object&#40;&#123;&#10;  grant      &#61; bool&#10;  target_org &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  grant      &#61; true&#10;  target_org &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [prefix](variables.tf#L96) | Optional prefix used for GCS bucket names to ensure uniqueness. | <code>string</code> |  | <code>null</code> |
| [service_account_keys](variables.tf#L107) | Generate and store service account keys in the state file. | <code>bool</code> |  | <code>false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [env_folders](outputs.tf#L17) | Unit environments folders. |  |
| [env_gcs_buckets](outputs.tf#L28) | Unit environments tfstate gcs buckets. |  |
| [env_sa_keys](outputs.tf#L36) | Unit environments service account keys. | ✓ |
| [env_service_accounts](outputs.tf#L45) | Unit environments service accounts. |  |
| [unit_folder](outputs.tf#L53) | Unit top level folder. |  |

<!-- END TFDOC -->
