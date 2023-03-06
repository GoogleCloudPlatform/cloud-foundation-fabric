# GCP Workload Identity Provider for Terraform Cloud Dynamic Credentials

This terraform code is a part of [GCP Workload Identity Federation for Terraform Cloud](../) blueprint.

The codebase provisions the following list of resources:

- (optional) GCP Project
- IAM Service Account
- Workload Identity Pool
- Workload Identity Provider
- IAM Permissins
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account](variables.tf#L16) | Billing account id used as default for new projects. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L43) | Existing project id. | <code>string</code> | ✓ |  |
| [tfc_organization_id](variables.tf#L48) | TFC organization id. | <code>string</code> | ✓ |  |
| [tfc_workspace_id](variables.tf#L53) | TFC workspace id. | <code>string</code> | ✓ |  |
| [issuer_uri](variables.tf#L21) | Terraform Cloud/Enterprise uri. Replace the uri if a self hosted instance is used. | <code>string</code> |  | <code>&#34;https:&#47;&#47;app.terraform.io&#47;&#34;</code> |
| [parent](variables.tf#L27) | Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format. | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L37) | Create project instead of using an existing one. | <code>bool</code> |  | <code>true</code> |
| [workload_identity_pool_id](variables.tf#L58) | Workload identity pool id. | <code>string</code> |  | <code>&#34;tfc-pool&#34;</code> |
| [workload_identity_pool_provider_id](variables.tf#L64) | Workload identity pool provider id. | <code>string</code> |  | <code>&#34;tfc-provider&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [project_id](outputs.tf#L15) | GCP Project ID. |  |
| [tfc_workspace_wariables](outputs.tf#L20) | Variables to be set on the TFC workspace. |  |

<!-- END TFDOC -->

## Test

```hcl
module "test" {
  source                             = "./fabric/blueprints/cloud-operations/terraform-cloud-dynamic-credentials/gcp-workload-identity-provider"
  billing_account                    = "1234-ABCD-1234"
  project_create                     = true
  project_id                         = "project-1"
  parent                             = "folders/12345"
  tfc_organization_id                = "org-123"
  tfc_workspace_id                   = "ws-123"
  workload_identity_pool_id          = "tfe-pool"
  workload_identity_pool_provider_id = "tf-provider"
  issuer_uri                         = "https://app.terraform.io/"
}

# tftest modules=3 resources=12
```
