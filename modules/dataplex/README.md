# Dataplex instance with lake, zone & assets

This module manages the creation of a Dataplex instance along with lake, zone & assets in single regions.

<!-- BEGIN TOC -->
- [Simple example](#simple-example)
- [IAM](#iam)
- [TODO](#todo)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple example

This example shows how to setup a Dataplex instance, lake, zone & asset creation in GCP project.

```hcl

module "dataplex" {
  source     = "./fabric/modules/dataplex"
  name       = "terraform-lake"
  prefix     = "test"
  project_id = "myproject"
  region     = "europe-west2"
  zones = {
    landing = {
      type      = "RAW"
      discovery = true
      assets = {
        gcs_1 = {
          resource_name          = "gcs_bucket"
          cron_schedule          = "15 15 * * *"
          discovery_spec_enabled = true
          resource_spec_type     = "STORAGE_BUCKET"
        }
      }
    },
    curated = {
      type      = "CURATED"
      discovery = false
      assets = {
        bq_1 = {
          resource_name          = "bq_dataset"
          cron_schedule          = null
          discovery_spec_enabled = false
          resource_spec_type     = "BIGQUERY_DATASET"
        }
      }
    }
  }
}

# tftest modules=1 resources=5
```

## IAM

This example shows how to setup a Dataplex instance, lake, zone & asset creation in GCP project assigning IAM roles at lake and zone level.

```hcl

module "dataplex" {
  source     = "./fabric/modules/dataplex"
  name       = "lake"
  prefix     = "test"
  project_id = "myproject"
  region     = "europe-west2"
  iam = {
    "roles/dataplex.viewer" = [
      "group:analysts@example.com",
      "group:analysts_sensitive@example.com"
    ]
  }
  zones = {
    landing = {
      type      = "RAW"
      discovery = true
      assets = {
        gcs_1 = {
          resource_name          = "gcs_bucket"
          cron_schedule          = "15 15 * * *"
          discovery_spec_enabled = true
          resource_spec_type     = "STORAGE_BUCKET"
        }
      }
    },
    curated = {
      type      = "CURATED"
      discovery = false
      iam = {
        "roles/viewer" = [
          "group:analysts@example.com",
          "group:analysts_sensitive@example.com"
        ]
        "roles/dataplex.dataReader" = [
          "group:analysts@example.com",
          "group:analysts_sensitive@example.com"
        ]
      }
      assets = {
        bq_1 = {
          resource_name          = "bq_dataset"
          cron_schedule          = null
          discovery_spec_enabled = false
          resource_spec_type     = "BIGQUERY_DATASET"
        }
      }
    }
  }
}

# tftest modules=1 resources=8
```

## TODO

- [ ] support multi-regions
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L30) | Name of Dataplex Lake. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L41) | The ID of the project where this Dataplex Lake will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L46) | Region of the Dataplax Lake. | <code>string</code> | ✓ |  |
| [zones](variables.tf#L51) | Dataplex lake zones, such as `RAW` and `CURATED`. | <code title="map&#40;object&#40;&#123;&#10;  type      &#61; string&#10;  discovery &#61; optional&#40;bool, true&#41;&#10;  iam       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, null&#41;&#10;  assets &#61; map&#40;object&#40;&#123;&#10;    resource_name          &#61; string&#10;    resource_project       &#61; optional&#40;string&#41;&#10;    cron_schedule          &#61; optional&#40;string, &#34;15 15 &#42; &#42; &#42;&#34;&#41;&#10;    discovery_spec_enabled &#61; optional&#40;bool, true&#41;&#10;    resource_spec_type     &#61; optional&#40;string, &#34;STORAGE_BUCKET&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [iam](variables.tf#L17) | Dataplex lake IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [location_type](variables.tf#L24) | The location type of the Dataplax Lake. | <code>string</code> |  | <code>&#34;SINGLE_REGION&#34;</code> |
| [prefix](variables.tf#L35) | Optional prefix used to generate Dataplex Lake. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [assets](outputs.tf#L17) | Assets attached to the lake of Dataplex Lake. |  |
| [id](outputs.tf#L22) | Fully qualified Dataplex Lake id. |  |
| [lake](outputs.tf#L27) | The lake name of Dataplex Lake. |  |
| [zones](outputs.tf#L32) | The zone name of Dataplex Lake. |  |

<!-- END TFDOC -->
