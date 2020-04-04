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
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| automation_project_id | Project id used for automation service accounts. | <code title="">string</code> | ✓ |  |
| billing_account_id | Country billing account account. | <code title="">string</code> | ✓ |  |
| name | Top folder name. | <code title="">string</code> | ✓ |  |
| organization_id | Organization id in organizations/nnnnnn format. | <code title="">string</code> | ✓ |  |
| root_node | Root node in folders/folder_id or organizations/org_id format. | <code title="">string</code> | ✓ |  |
| short_name | Short name used as GCS bucket and service account prefixes, do not use capital letters or spaces. | <code title="">string</code> | ✓ |  |
| *environments* | Unit environments short names. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;non-prod &#61; &#34;Non production&#34;&#10;prod     &#61; &#34;Production&#34;&#10;&#125;">...</code> |
| *gcs_defaults* | Defaults use for the state GCS buckets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;location      &#61; &#34;EU&#34;&#10;storage_class &#61; &#34;MULTI_REGIONAL&#34;&#10;&#125;">...</code> |
| *iam_billing_config* | Grant billing user role to service accounts, defaults to granting on the billing account. | <code title="object&#40;&#123;&#10;grant      &#61; bool&#10;target_org &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;grant      &#61; true&#10;target_org &#61; false&#10;&#125;">...</code> |
| *iam_enviroment_roles* | IAM roles granted to the environment service account on the environment sub-folder. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="&#91;&#10;&#34;roles&#47;compute.networkAdmin&#34;,&#10;&#34;roles&#47;owner&#34;,&#10;&#34;roles&#47;resourcemanager.folderAdmin&#34;,&#10;&#34;roles&#47;resourcemanager.projectCreator&#34;,&#10;&#93;">...</code> |
| *iam_members* | IAM members for roles applied on the unit folder. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">null</code> |
| *iam_roles* | IAM roles applied on the unit folder. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *iam_xpn_config* | Grant Shared VPC creation roles to service accounts, defaults to granting at folder level. | <code title="object&#40;&#123;&#10;grant      &#61; bool&#10;target_org &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;grant      &#61; true&#10;target_org &#61; false&#10;&#125;">...</code> |
| *prefix* | Optional prefix used for GCS bucket names to ensure uniqueness. | <code title="">string</code> |  | <code title="">null</code> |
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
