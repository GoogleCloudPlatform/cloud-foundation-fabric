# Google Cloud Unit Folders Module

This module allow creation and management of a set of folders (environments) and a common parent folder (unit), their environment specific Service Accounts, IAM bindings, GCS buckets.

## Example

```hcl
module "folders-unit" {
  source = "../../modules/folders-unit"

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
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| automation_project_id | Project id used for automation service accounts. | <code title="">string</code> | ✓ |  |
| billing_account_id | Country billing account account. | <code title="">string</code> | ✓ |  |
| iam_members | IAM members for roles applied on the unit folder. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> | ✓ |  |
| iam_roles | IAM roles applied on the unit folder. | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| name | Top folder name. | <code title="">string</code> | ✓ |  |
| organization_id | Organization id. | <code title="">string</code> | ✓ |  |
| prefix | Prefix used for GCS bucket names. | <code title="">string</code> | ✓ |  |
| root_node | Root node in folders/folder_id or organizations/org_id format. | <code title="">string</code> | ✓ |  |
| short_name | Short name. | <code title="">string</code> | ✓ |  |
| *environments* | Unit environments short names. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;dev  &#61; &#34;development&#34;,&#10;test &#61; &#34;Testing&#34;,&#10;prod &#61; &#34;Production&#34;&#10;&#125;">...</code> |
| *gcs_defaults* | Defaults use for the state GCS buckets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;location      &#61; &#34;EU&#34;&#10;storage_class &#61; &#34;MULTI_REGIONAL&#34;&#10;&#125;">...</code> |
| *iam_billing_config* | Control granting billing user role to service accounts. Target the billing account by default. | <code title="object&#40;&#123;&#10;grant      &#61; bool&#10;target_org &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;grant      &#61; true&#10;target_org &#61; false&#10;&#125;">...</code> |
| *iam_enviroment_roles* | IAM roles granted to service accounts on the environment sub-folders. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;roles&#47;compute.networkAdmin&#34;,&#10;&#34;roles&#47;owner&#34;,&#10;&#34;roles&#47;resourcemanager.folderAdmin&#34;,&#10;&#34;roles&#47;resourcemanager.projectCreator&#34;,&#10;&#93;">...</code> |
| *iam_xpn_config* | Control granting Shared VPC creation roles to service accounts. Target the root node by default. | <code title="object&#40;&#123;&#10;grant      &#61; bool&#10;target_org &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;grant      &#61; true&#10;target_org &#61; false&#10;&#125;">...</code> |
| *service_account_keys* | Generate and store service account keys in the state file. | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| env_folders | Unit environments folders. |  |
| env_gcs_buckets | Unit environments tfstate gcs buckets. |  |
| env_sa_keys | Unit environments service account keys. | ✓ |
| env_service_accounts | Unit environments service accounts. |  |
| unit_folder | Unit top level folder. |  |
<!-- END TFDOC -->
