# Workload Identity Module

This module manages Google Cloud Workload Identity Federation (WIF) pools,
identity providers (OIDC, AWS, SAML), and optional Service Account
impersonation bindings (`roles/iam.workloadIdentityUser`) for external
workloads such as GitHub Actions, GitLab CI, or AWS.

<!-- BEGIN TOC -->
- [GitHub Actions OIDC Provider](#github-actions-oidc-provider)
- [AWS Provider](#aws-provider)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## GitHub Actions OIDC Provider

```hcl
module "wif" {
  source      = "./fabric/modules/iam-workload-identity"
  project_id  = var.project_id
  prefix      = "dev"
  name        = "github-pool"
  description = "Workload Identity Pool for GitHub Actions"
  identity_providers = {
    github = {
      description = "GitHub Actions OIDC provider"
      attribute_mapping = {
        "google.subject"             = "assertion.sub"
        "attribute.actor"            = "assertion.actor"
        "attribute.repository"       = "assertion.repository"
        "attribute.repository_owner" = "assertion.repository_owner"
      }
      attribute_condition = "assertion.repository_owner == 'my-org'"
      oidc = {
        issuer_uri = "https://token.actions.githubusercontent.com"
      }
    }
  }
  service_account_impersonation = {
    ci_runner = {
      service_account_id = "my-ci-runner@${var.project_id}.iam.gserviceaccount.com"
      attribute_members  = ["attribute.repository/my-org/my-repo"]
    }
  }
}
# tftest modules=1 resources=3
```

## AWS Provider

```hcl
module "wif" {
  source      = "./fabric/modules/iam-workload-identity"
  project_id  = var.project_id
  name        = "aws-pool"
  description = "Workload Identity Pool for AWS"
  iam = {
    "roles/iam.workloadIdentityPoolViewer" = ["group:devops@example.com"]
  }
  identity_providers = {
    aws-provider = {
      description = "AWS provider"
      attribute_mapping = {
        "google.subject"        = "assertion.arn"
        "attribute.aws_account" = "assertion.account"
      }
      aws = {
        account_id = "123456789012"
      }
    }
  }
}
# tftest modules=1 resources=3
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L81) | The ID of the workload identity pool. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L96) | The project in which the workload identity pool belongs. | <code>string</code> | ✓ |  |
| [context](variables.tf#L15) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L25) | A description of the pool. | <code>string</code> |  | <code>&#34;Managed by Terraform.&#34;</code> |
| [disabled](variables.tf#L31) | Whether the workload identity pool is disabled. | <code>bool</code> |  | <code>false</code> |
| [display_name](variables.tf#L37) | A display name for the pool. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L43) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables.tf#L50) | IAM bindings in {PRINCIPAL => [ROLES]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [identity_providers](variables.tf#L57) | Workload identity pool identity providers. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L86) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [service_account_impersonation](variables.tf#L101) | Service account impersonation bindings for the pool. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L15) | The workload identity pool ID. |  |
| [name](outputs.tf#L24) | The resource name of the workload identity pool. |  |
| [pool](outputs.tf#L29) | The workload identity pool resource. |  |
| [provider_ids](outputs.tf#L34) | Map of provider IDs. |  |
| [provider_names](outputs.tf#L41) | Map of provider resource names. |  |
| [providers](outputs.tf#L49) | Map of provider resources. |  |
<!-- END TFDOC -->
