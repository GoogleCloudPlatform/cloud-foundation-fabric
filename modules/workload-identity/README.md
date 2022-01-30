# Workload identity federation module

This module module allows creating a workload identity pool and its associated providers.

The following role is required to create the above mentioned resources:

* IAM Workload Identity Pool Admin

## Examples

### IAM workload identity pool provider OIDC

This creates a workload identity pool with an associated workload identity pool provider for Azure AD

```hcl
module "workload-identity" {
  source                    = "./modules/workload-identity"
  project_id                = var.project_id
  display_name              = "example-pool"
  description               = "This is an example workload identity pool"
  workload_identity_pool_id = "example-pool"
  workload_identity_pool_providers = {
    example-provider = {
      attribute_condition = null
      attribute_mapping = {
        "google.subject" = "assertion.arn"
      }
      description  = "This is an example workload identity pool provider"
      disabled     = false
      display_name = "example-provider"
      aws          = null
      oidc = {
        allowed_audiences = null
        issuer_uri        = "https://sts.windows.net/7d49e473-7f59-49c5-b485-84fafaff49a8"
      }
    }
  }
}
# tftest modules=1 resources=2
```

### IAM Workload Identity Pool Provider AWS

This creates a workload identity pool with an assocaited workload identity pool provider for Azure AD

```hcl
module "workload-identity" {
  source                    = "./modules/workload-identity"
  project_id                = var.project_id
  display_name              = "example-pool"
  description               = "This is an example workload identity pool"
  workload_identity_pool_id = "example-pool"
  workload_identity_pool_providers = {
    example-provider = {
      attribute_condition = "attribute.aws_role==\"arn:aws:sts::999999999999:assumed-role/stack-eu-central-1-lambdaRole\""
      attribute_mapping = {
        "google.subject"        = "assertion.arn"
        "attribute.aws_account" = "assertion.account"
        "attribute.environment" = "assertion.arn.contains(\":instance-profile/Production\") ? \"prod\" : \"test\""
      }
      description  = "This is an example workload identity pool provider"
      disabled     = false
      display_name = "example-provider"
      aws = {
        account_id = "999999999999"
      }
      oidc = null
    }
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L35) | Project identifier | <code>string</code> | ✓ |  |
| [workload_identity_pool_id](variables.tf#L40) | Workload identity pool identifier | <code>string</code> | ✓ |  |
| [workload_identity_pool_providers](variables.tf#L45) | Map with the workload identity pool providers | <code title="map&#40;object&#40;&#123;&#10;  attribute_condition &#61; string&#10;  attribute_mapping   &#61; map&#40;string&#41;&#10;  aws &#61; object&#40;&#123;&#10;    account_id &#61; string&#10;  &#125;&#41;&#10;  description  &#61; string&#10;  display_name &#61; string&#10;  disabled     &#61; bool&#10;  oidc &#61; object&#40;&#123;&#10;    allowed_audiences &#61; list&#40;string&#41;&#10;    issuer_uri        &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [description](variables.tf#L17) | Optional description | <code>string</code> |  | <code>null</code> |
| [disabled](variables.tf#L23) | Flag indicating whether the workload identity pool is disabled | <code>bool</code> |  | <code>false</code> |
| [display_name](variables.tf#L29) | Optional display name | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [pool](outputs.tf#L17) | Workload identity pool |  |
| [providers](outputs.tf#L22) | Workload identity pool providers |  |

<!-- END TFDOC -->
