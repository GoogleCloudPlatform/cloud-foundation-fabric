# BigQuery Analytics Hub

This module allows managing [Analytics Hub](https://cloud.google.com/bigquery/docs/analytics-hub-introduction) Exchange and Listing resources.

## Examples

### Exchange

```hcl
module "analytics-hub" {
  source          = "./fabric/modules/analytics-hub"
  project_id      = "project-id"
  region          = "us-central1"
  prefix          = "test"
  name            = "exchange"
  primary_contact = "exchange-owner-group@domain.com"
  documentation   = "documentation"
}
# tftest modules=1 resources=1
```

### Listings

```hcl
module "analytics-hub" {
  source     = "./fabric/modules/analytics-hub"
  project_id = "project-id"
  region     = "us-central1"
  name       = "exchange"
  listings = {
    "listing_id" = {
      bigquery_dataset = "projects/{project}/datasets/{dataset}"
    },
    "listing_id_2" = {
      bigquery_dataset = "projects/thinhha-pso-test-project/datasets/biglake_test"
      restricted_export_config = {
        enabled               = true
        restrict_query_result = true
      }
      description     = "(Optional) Short description of the listing."
      primary_contact = "(Optional) Email or URL of the primary point of contact of the listing."
      documentation   = "(Optional) Documentation describing the listing."
      request_access  = "(Optional) Email or URL of the request access of the listing. Subscribers can use this reference to request access."
      categories      = []
      data_provider = {
        name            = "(Required) Name of the data provider."
        primary_contact = "(Optional) Email or URL of the data provider."
      }
      publisher = {
        name            = "(Required) Name of the dlisting publisher."
        primary_contact = "(Optional) Email or URL of the listing publisher."
      }
    }
  }
}
# tftest modules=1 resources=3
```

### IAM

This module supports setting IAM permissions on both the exchange and listing resources. IAM permissions on the exchange is inherited on the listings. See [this page](https://cloud.google.com/bigquery/docs/analytics-hub-grant-roles) for IAM roles that can be granted on exchange and listings.

```hcl
module "analytics-hub" {
  source     = "./fabric/modules/analytics-hub"
  project_id = "project-id"
  region     = "us-central1"
  name       = "exchange"
  iam = {
    "roles/analyticshub.viewer" = [
      "group:viewer@domain.com"
    ],
  }
  listings = {
    "listing_id" = {
      bigquery_dataset = "projects/{project}/datasets/{dataset}"
      iam = {
        "roles/analyticshub.subscriber" = [
          "group:subscriber@domain.com"
        ],
        "roles/analyticshub.subscriptionOwner" = [
          "group:subscription-owner@domain.com"
        ],
      }
    }
  }
}
# tftest modules=1 resources=5
```

### Factory

Similarly to other modules, a rules factory (see [Resource Factories](../../blueprints/factories/)) is also included here to allow managing listings inside the same exchange via descriptive configuration files.

Factory configuration is via one optional attributes in the `factory_config_path` variable specifying the path where tags files are stored.

Factory tags are merged with rules declared in code, with the latter taking precedence where both use the same key.

This is an example of a simple factory:

```hcl
module "analytics-hub" {
  source     = "./fabric/modules/analytics-hub"
  project_id = "project-id"
  region     = "us-central1"
  name       = "exchange"
  listings = {
    "listing_id" = {
      bigquery_dataset = "projects/{project}/datasets/{dataset}"
    },
  }
  factories_config = {
    listings = "listings"
  }
}
# tftest modules=1 resources=5 files=yaml
```

```yaml
# tftest-file id=yaml path=listings/listing_1.yaml
bigquery_dataset: projects/{project}/datasets/{dataset}
restricted_export_config:
  enabled: true
description: "(Optional) Short description of the listing."
primary_contact: "(Optional) Email or URL of the primary point of contact of the listing."
documentation: "(Optional) Documentation describing the listing."
request_access: "(Optional) Email or URL of the request access of the listing. Subscribers can use this reference to request access."
categories: []
data_provider:
  name: "(Required) Name of the data provider."
  primary_contact: "(Optional) Email or URL of the data provider."
publisher:
  name: "(Required) Name of the dlisting publisher."
  primary_contact: "(Optional) Email or URL of the listing publisher."
iam:
  roles/analyticshub.subscriber:
    - group:subscriber@domain.com
  roles/analyticshub.subscriptionOwner:
    - group:subscription-owner@domain.com
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L78) | The ID of the data exchange. Must contain only Unicode letters, numbers (0-9), underscores (_). Should not use characters that require URL-escaping, or characters outside of ASCII, spaces. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L95) | The ID of the project where the Analytics Hub Exchange will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L100) | Region for the data exchange | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | Resource description for data exchange | <code>string</code> |  | <code>null</code> |
| [documentation](variables.tf#L23) | Documentation describing the data exchange. | <code>string</code> |  | <code>null</code> |
| [factories_config](variables.tf#L29) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  listings &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L38) | Authoritative IAM bindings for the data exchange in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [icon](variables.tf#L45) | Base64 encoded image representing the data exchange. | <code>string</code> |  | <code>null</code> |
| [listings](variables.tf#L51) | Listings definitions in the form {LISTING_ID => LISTING_CONFIGS}. LISTING_ID must contain only Unicode letters, numbers (0-9), underscores (_). Should not use characters that require URL-escaping, or characters outside of ASCII, spaces. | <code title="map&#40;object&#40;&#123;&#10;  description      &#61; optional&#40;string&#41;&#10;  bigquery_dataset &#61; string&#10;  iam              &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  primary_contact  &#61; optional&#40;string&#41;&#10;  documentation    &#61; optional&#40;string&#41;&#10;  icon             &#61; optional&#40;string&#41;&#10;  request_access   &#61; optional&#40;string&#41;&#10;  data_provider &#61; optional&#40;object&#40;&#123;&#10;    name            &#61; string&#10;    primary_contact &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  publisher &#61; optional&#40;object&#40;&#123;&#10;    name            &#61; string&#10;    primary_contact &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  categories &#61; optional&#40;list&#40;string&#41;&#41;&#10;  restricted_export_config &#61; optional&#40;object&#40;&#123;&#10;    enabled               &#61; optional&#40;bool&#41;&#10;    restrict_query_result &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L83) | Optional prefix for Analytics Hub Exchange ID. | <code>string</code> |  | <code>null</code> |
| [primary_contact](variables.tf#L89) | Email or URL of the primary point of contact of the data exchange.. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [data_exchange_id](outputs.tf#L17) | Data exchange id. |  |
| [data_listings](outputs.tf#L26) | Data listings and corresponding configs. |  |
<!-- END TFDOC -->
