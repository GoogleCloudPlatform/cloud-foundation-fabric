# Terraform Service Accounts Module

This module allows easy creation of one or more service accounts, and granting them basic roles.

The resources/services/activations/deletions that this module will create/trigger are:

- one or more service accounts
- optional project-level IAM role bindings for each service account
- one optional billing IAM role binding per service account, at the organization or billing account level
- two optional organization-level IAM bindings per service account, to enable the service accounts to create and manage Shared VPC networks
- one optional service account key per service account

## Compatibility

 This module is meant for use with Terraform 0.12. If you haven't [upgraded](https://www.terraform.io/upgrade-guides/0-12.html)
  and need a Terraform 0.11.x-compatible version of this module, the last released version intended for
  Terraform 0.11.x is [0.1.1](https://registry.terraform.io/modules/terraform-google-modules/service-accounts/google/0.1.1).

## Usage

Basic usage of this module is as follows:

```hcl
module "service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 2.0"
  project_id    = "<PROJECT ID>"
  prefix        = "test-sa"
  names         = ["first", "second"]
  project_roles = [
    "project-foo=>roles/viewer",
    "project-spam=>roles/storage.objectViewer",
  ]
}
```

Functional examples are included in the
[examples](./examples/) directory.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account\_id | If assigning billing role, specificy a billing account (default is to assign at the organizational level). | string | `""` | no |
| generate\_keys | Generate keys for service accounts. | bool | `"false"` | no |
| grant\_billing\_role | Grant billing user role. | bool | `"false"` | no |
| grant\_xpn\_roles | Grant roles for shared VPC management. | bool | `"true"` | no |
| names | Names of the service accounts to create. | list(string) | `<list>` | no |
| org\_id | Id of the organization for org-level roles. | string | `""` | no |
| prefix | Prefix applied to service account names. | string | `""` | no |
| project\_id | Project id where service account will be created. | string | n/a | yes |
| project\_roles | Common roles to apply to all service accounts, project=>role as elements. | list(string) | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| email | Service account email (for single use). |
| emails | Service account emails. |
| emails\_list | Service account emails. |
| iam\_email | IAM-format service account email (for single use). |
| iam\_emails | IAM-format service account emails. |
| iam\_emails\_list | IAM-format service account emails. |
| key | Service account key (for single use). |
| keys | Map of service account keys. |
| service\_account | Service account resource (for single use). |
| service\_accounts | Service account resources. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform][terraform] v0.12
- [Terraform Provider for GCP][terraform-provider-gcp] plugin >= v2.0

### IAM

Service account or user credentials with the following roles must be used to provision the resources of this module:

- Service Account Admin: `roles/iam.serviceAccountAdmin`
- (optional) Service Account Key Admin: `roles/iam.serviceAccountAdmin` when `generate_keys` is set to `true`
- (optional) roles needed to grant optional IAM roles at the project or organizational level

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

[iam-module]: https://registry.terraform.io/modules/terraform-google-modules/iam/google
[project-factory-module]: https://registry.terraform.io/modules/terraform-google-modules/project-factory/google
[terraform-provider-gcp]: https://www.terraform.io/docs/providers/google/index.html
[terraform]: https://www.terraform.io/downloads.html
