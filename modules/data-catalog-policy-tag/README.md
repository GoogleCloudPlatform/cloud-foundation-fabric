# Data Catalog Module

This module simplifies the creation of [Data Catalog](https://cloud.google.com/data-catalog) Policy Tags. Policy Tags can be used to configure [Bigquery column-level access](https://cloud.google.com/bigquery/docs/best-practices-policy-tags).

Note: Data Catalog is still in beta, hence this module currently uses the beta provider.

<!-- BEGIN TOC -->
- [IAM](#iam)
- [Examples](#examples)
  - [Simple Taxonomy with policy tags](#simple-taxonomy-with-policy-tags)
  - [Taxonomy with IAM binding](#taxonomy-with-iam-binding)
  - [Factory](#factory)
- [Variables](#variables)
- [Outputs](#outputs)
- [TODO](#todo)
<!-- END TOC -->

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

## Examples

### Simple Taxonomy with policy tags

```hcl
module "cmn-dc" {
  source     = "./fabric/modules/data-catalog-policy-tag"
  name       = "my-datacatalog-policy-tags"
  project_id = "my-project"
  location   = "eu"
  tags = {
    low    = {}
    medium = {}
    high   = {}
  }
}
# tftest modules=1 resources=4
```

### Taxonomy with IAM binding

```hcl
module "cmn-dc" {
  source     = "./fabric/modules/data-catalog-policy-tag"
  name       = "my-datacatalog-policy-tags"
  project_id = "my-project"
  location   = "eu"
  tags = {
    low    = {}
    medium = {}
    high = {
      iam = {
        "roles/datacatalog.categoryFineGrainedReader" = [
          "group:GROUP_NAME@example.com"
        ]
      }
    }
  }
  iam = {
    "roles/datacatalog.categoryAdmin" = ["group:GROUP_NAME@example.com"]
  }
  iam_bindings_additive = {
    am1-admin = {
      member = "user:am1@example.com"
      role   = "roles/datacatalog.categoryAdmin"
    }
  }
}
# tftest modules=1 resources=7
```
### Factory

```hcl
module "taxonomy" {
  source     = "./fabric/modules/data-catalog-policy-tag"
  project_id = "my-project"
  name       = "taxonomy"
  location   = "europe-west1"
  context = {
    iam_principals = {
      user-a = "user:a@example.org"
      user-b = "user:b@example.org"
    }
  }
  factories_config = {
    taxonomy = "data-catalog/taxonomy.yaml"
  }
}
# tftest modules=1 resources=6 files=factory
```

```yaml
description: taxonomy description
activated_policy_types:
  - FINE_GRAINED_ACCESS_CONTROL
iam:
  roles/viewer:
    - $iam_principals:user-a
tags:
  tag-a:
    description: tag a description
    iam:
      roles/viewer:
        - $iam_principals:user-b
  tag-b:
    description: tag b description
    iam_bindings:
      viewer:
        role: roles/viewer
        members:
          - user:c@example.org
# tftest-file id=factory path=data-catalog/taxonomy.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L61) | Data Catalog Taxonomy location. | <code>string</code> | ✓ |  |
| [name](variables.tf#L67) | Name of this taxonomy. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L73) | GCP project id. | <code>string</code> | ✓ |  |
| [activated_policy_types](variables.tf#L17) | A list of policy types that are activated for this taxonomy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;FINE_GRAINED_ACCESS_CONTROL&#34;&#93;</code> |
| [context](variables.tf#L32) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L45) | Description of this taxonomy. | <code>string</code> |  | <code>&#34;Taxonomy - Terraform managed&#34;</code> |
| [factories_config](variables.tf#L52) | Paths to folders and files for the optional factories. | <code title="object&#40;&#123;&#10;  taxonomy &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L23) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L29) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L44) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L17) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tags](variables.tf#L79) | List of Data Catalog Policy tags to be created with optional IAM binging configuration in {tag => {ROLE => [MEMBERS]}} format. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified taxonomy id. |  |
| [tags](outputs.tf#L22) | Policy Tags. |  |
<!-- END TFDOC -->
## TODO

- Support IAM at tag level.
- Support Child policy tags
