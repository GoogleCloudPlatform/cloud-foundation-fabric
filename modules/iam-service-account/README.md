# Google Service Account Module

This module allows simplified creation and management of one a service account and its IAM bindings.

Note that outputs have no dependencies on IAM bindings to prevent resource cycles.

<!-- BEGIN TOC -->
- [Simple Example](#simple-example)
- [IAM](#iam)
- [Reusing Existing Service Accounts](#reusing-existing-service-accounts)
- [Tag Bindings](#tag-bindings)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple Example

```hcl
module "myproject-default-service-accounts" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "vm-default"
  # authoritative roles granted *on* the service accounts to other identities
  iam = {
    "roles/iam.serviceAccountUser" = ["group:${var.group_email}"]
  }
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
# tftest modules=1 resources=4 inventory=basic.yaml e2e
```

## IAM

IAM is managed via several variables that implement different features and levels of control.

The following variables control IAM bindings where this module's managed service account is the resource, and they conform to the standard interface adopted across all other modules:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph. Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

The following variables control **additive** IAM bindings on external resources where this module's managed service account is the principal:

- `iam_billing_roles`
- `iam_folder_roles`
- `iam_organization_roles`
- `iam_project_roles`
- `iam_sa_roles`
- `iam_storage_roles`

IAM also supports variable interpolation for both roles and principals and for the foreign resources where the service account is the principal, via the respective attributes in the `var.context` variable. Basic usage is shown in the example below.

```hcl
module "service-account-with-tags" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "test-service-account"
  context = {
    folder_ids = {
      test = "folders/1234567890"
    }
  }
  iam_billing_roles = {
    "ABCDE-12345-ABCDE" = [
      "roles/billing.user"
    ]
  }
  iam_folder_roles = {
    "$folder_ids:test" = [
      "roles/resourcemanager.folderAdmin"
    ]
  }
}
# tftest modules=1 resources=3 inventory=iam.yaml
```

## Reusing Existing Service Accounts

Like other modules in this repository, this module allows reusing existing service accounts where only IAM or tag bindings management is needed, via the `service_account_reuse` variable.

When reusing service accounts, the `name` variable can be set to the fully fledged service account email. In such cases the `project_id` variable can be ignored as the project id is derived from the email.

The `service_account_reuse.use_data_source` flag also allows to skip the data source used to fetch the service account unique id (numeric), which is only used when setting tag bindings. If those are needed while still skipping the data source, populate the additional attributes `service_account_reuse.attributes`.

```hcl
module "service-account" {
  source = "./fabric/modules/iam-service-account"
  name   = "test-0@myproject.iam.gserviceaccount.com"
  context = {
    folder_ids = {
      test = "folders/1234567890"
    }
  }
  iam_billing_roles = {
    "ABCDE-12345-ABCDE" = [
      "roles/billing.user"
    ]
  }
  iam_folder_roles = {
    "$folder_ids:test" = [
      "roles/resourcemanager.folderAdmin"
    ]
  }
  service_account_reuse = {
    use_data_source = false
  }
}
# tftest modules=1 resources=2 inventory=reuse-0.yaml
```

## Tag Bindings

Use the `tag_bindings` variable to attach tags to the service account. Provide `project_number` to prevent potential permadiffs with the tag binding resource.

```hcl
module "service-account-with-tags" {
  source         = "./fabric/modules/iam-service-account"
  project_id     = var.project_id
  name           = "test-service-account"
  project_number = var.project_number
  tag_bindings = {
    foo = "tagValues/123456789"
  }
}
# tftest modules=1 resources=2 inventory=tags.yaml
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [iam.tf](./iam.tf) | IAM bindings. | <code>google_billing_account_iam_member</code> · <code>google_folder_iam_member</code> · <code>google_organization_iam_member</code> · <code>google_project_iam_member</code> · <code>google_service_account_iam_binding</code> · <code>google_service_account_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_service_account</code> · <code>google_tags_tag_binding</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables-iam.tf](./variables-iam.tf) | None |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L58) | Name of the service account to create. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | External context used in replacements. | <code title="object&#40;&#123;&#10;  condition_vars      &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids         &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_account_ids &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  storage_buckets     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [create_ignore_already_exists](variables.tf#L33) | If set to true, skip service account creation if a service account with the same email already exists. | <code>bool</code> |  | <code>null</code> |
| [description](variables.tf#L44) | Optional description. | <code>string</code> |  | <code>null</code> |
| [display_name](variables.tf#L51) | Display name of the service account to create. | <code>string</code> |  | <code>&#34;Terraform-managed.&#34;</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_billing_roles](variables-iam.tf#L24) | Billing account roles granted to this service account, by billing account id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L31) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L46) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L68) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals_additive](variables-iam.tf#L61) | Additive IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam_bindings_additive` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_folder_roles](variables-iam.tf#L75) | Folder roles granted to this service account, by folder id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_organization_roles](variables-iam.tf#L82) | Organization roles granted to this service account, by organization id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_project_roles](variables-iam.tf#L89) | Project roles granted to this service account, by project id. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_sa_roles](variables-iam.tf#L96) | Service account roles granted to this service account, by service account name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_storage_roles](variables-iam.tf#L103) | Storage roles granted to this service account, by bucket name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L64) | Prefix applied to service account names. | <code>string</code> |  | <code>null</code> |
| [project_id](variables.tf#L75) | Project id where service account will be created. This can be left null when reusing service accounts. | <code>string</code> |  | <code>null</code> |
| [project_number](variables.tf#L89) | Project number of var.project_id. Set this to avoid permadiffs when creating tag bindings. This can be left null when reusing service accounts and tags are not used. | <code>string</code> |  | <code>null</code> |
| [service_account_reuse](variables.tf#L96) | Reuse existing service account if not null. Data source can be forced disabled if tag bindings are not used, or unique id is set. | <code title="object&#40;&#123;&#10;  use_data_source &#61; optional&#40;bool, true&#41;&#10;  attributes &#61; optional&#40;object&#40;&#123;&#10;    project_number &#61; number&#10;    unique_id      &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [tag_bindings](variables.tf#L109) | Tag bindings for this service accounts, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [email](outputs.tf#L17) | Service account email. |  |
| [iam_email](outputs.tf#L25) | IAM-format service account email. |  |
| [id](outputs.tf#L33) | Fully qualified service account id. |  |
| [name](outputs.tf#L41) | Service account name. |  |
| [service_account](outputs.tf#L49) | Service account resource. |  |
| [unique_id](outputs.tf#L54) | Fully qualified service account id. |  |
<!-- END TFDOC -->
