# Google Service Account Module

This module allows simplified creation and management of one a service account and its IAM bindings.

Note that outputs have no dependencies on IAM bindings to prevent resource cycles.

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Simple Example](#simple-example)
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
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L118) | Name of the service account to create. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L133) | Project id where service account will be created. | <code>string</code> | ✓ |  |
| [create_ignore_already_exists](variables.tf#L17) | If set to true, skip service account creation if a service account with the same email already exists. | <code>bool</code> |  | <code>null</code> |
| [description](variables.tf#L27) | Optional description. | <code>string</code> |  | <code>null</code> |
| [display_name](variables.tf#L33) | Display name of the service account to create. | <code>string</code> |  | <code>&#34;Terraform-managed.&#34;</code> |
| [iam](variables.tf#L39) | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_billing_roles](variables.tf#L46) | Billing account roles granted to this service account, by billing account id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L53) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L68) | Individual additive IAM bindings on the service account. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_folder_roles](variables.tf#L83) | Folder roles granted to this service account, by folder id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_organization_roles](variables.tf#L90) | Organization roles granted to this service account, by organization id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_project_roles](variables.tf#L97) | Project roles granted to this service account, by project id. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_sa_roles](variables.tf#L104) | Service account roles granted to this service account, by service account name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_storage_roles](variables.tf#L111) | Storage roles granted to this service account, by bucket name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L123) | Prefix applied to service account names. | <code>string</code> |  | <code>null</code> |
| [project_number](variables.tf#L138) | Project number of var.project_id. Set this to avoid permadiffs when creating tag bindings. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L144) | Create service account. When set to false, uses a data source to reference an existing service account. | <code>bool</code> |  | <code>true</code> |
| [tag_bindings](variables.tf#L151) | Tag bindings for this service accounts, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [email](outputs.tf#L17) | Service account email. |  |
| [iam_email](outputs.tf#L25) | IAM-format service account email. |  |
| [id](outputs.tf#L33) | Fully qualified service account id. |  |
| [name](outputs.tf#L41) | Service account name. |  |
| [service_account](outputs.tf#L49) | Service account resource. |  |
<!-- END TFDOC -->
