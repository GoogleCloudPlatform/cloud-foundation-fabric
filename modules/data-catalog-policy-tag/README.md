# Data Catalog Module

This module simplifies the creation of [Data Catalog](https://cloud.google.com/data-catalog) Policy Tags. Policy Tags can be used to configure [Bigquery column-level access](https://cloud.google.com/bigquery/docs/best-practices-policy-tags).

Note: Data Catalog is still in beta, hence this module currently uses the beta provider.

<!-- BEGIN TOC -->
- [IAM](#iam)
- [Examples](#examples)
  - [Simple Taxonomy with policy tags](#simple-taxonomy-with-policy-tags)
  - [Taxonomy with IAM binding](#taxonomy-with-iam-binding)
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
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L29) | Data Catalog Taxonomy location. | <code>string</code> | ✓ |  |
| [name](variables.tf#L34) | Name of this taxonomy. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L49) | GCP project id. | <code>string</code> | ✓ |  |
| [activated_policy_types](variables.tf#L17) | A list of policy types that are activated for this taxonomy. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;FINE_GRAINED_ACCESS_CONTROL&#34;&#93;</code> |
| [description](variables.tf#L23) | Description of this taxonomy. | <code>string</code> |  | <code>&#34;Taxonomy - Terraform managed&#34;</code> |
| [iam](variables-iam.tf#L23) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L29) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L44) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L17) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L39) | Optional prefix used to generate project id and name. | <code>string</code> |  | <code>null</code> |
| [tags](variables.tf#L54) | List of Data Catalog Policy tags to be created with optional IAM binging configuration in {tag => {ROLE => [MEMBERS]}} format. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified taxonomy id. |  |
| [tags](outputs.tf#L22) | Policy Tags. |  |
<!-- END TFDOC -->
## TODO

- Support IAM at tag level.
- Support Child policy tags
