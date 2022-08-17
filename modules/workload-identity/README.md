# Google Cloud Workload Identity Federation Module

This module allows managing a single Workload Identity Federation, creating configuration for an external identity provider.


## Examples

### Provider OIDC Basic (GitHub)

```hcl
module "workload_identity_github" {
  source     = "./modules/workload-identity"
  project_id = "my-project"
  pool_id    = "my-pool-id"

  provider_id = "my-provider-id"
  provider_attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  provider_config = {
    oidc = {
      allowed_audiences = []
      issuer_uri        = "https://token.actions.githubusercontent.com"
    },
    aws = null
  }
}
# tftest modules=1 resources=2
```

### Provider AWS Basic

```hcl
module "workload_identity_aws" {
  source     = "./modules/workload-identity"
  project_id = "my-project"
  pool_id    = "my-pool-id"

  provider_id = "my-provider-id"
  provider_attribute_mapping = {
    "google.subject"        = "assertion.arn"
    "attribute.aws_account" = "assertion.account"
    "attribute.environment" = "assertion.arn.contains(\":instance-profile/Production\") ? \"prod\" : \"test\""
  }
  provider_config = {
    oidc = null,
    aws = {
      account_id = "999999999999"
    }
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [pool_id](variables.tf#L29) | Pool ID. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L34) | Project used for resources. | <code>string</code> | ✓ |  |
| [provider_config](variables.tf#L66) | OIDC or AWS support | <code>map&#40;any&#41;</code> | ✓ |  |
| [provider_id](variables.tf#L39) | Pool provider ID. | <code>string</code> | ✓ |  |
| [disabled](variables.tf#L23) | Disable pool usage. | <code>bool</code> |  | <code>false</code> |
| [display_name](variables.tf#L17) | Display name for the pool. | <code>string</code> |  | <code>&#34;&#34;</code> |
| [provider_attribute_condition](variables.tf#L53) | Conditions provider won't allow. | <code>string</code> |  | <code>null</code> |
| [provider_attribute_mapping](variables.tf#L58) | Mapping to an external provider. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  &#34;google.subject&#34; &#61; &#34;assertion.sub&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [provider_disabled](variables.tf#L48) | Disable provider usage. | <code>bool</code> |  | <code>false</code> |
| [provider_display_name](variables.tf#L43) | Display name for the provider. | <code>string</code> |  | <code>&#34;&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [pool_id](outputs.tf#L23) | Pool ID. |  |
| [pool_name](outputs.tf#L18) | Pool name. |  |
| [pool_state](outputs.tf#L28) | Pool State. |  |
| [principal](outputs.tf#L33) | Pool provider principal. |  |

<!-- END TFDOC -->
