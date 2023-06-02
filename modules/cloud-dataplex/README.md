# Cloud Dataplex instance with lake, zone & assests

This module manages the creation of Cloud Dataplex instance along with lake, zone & assets in single regions. 


## Simple example

This example shows how to setup a Cloud Dataplex instance, lake, zone & asset creation in GCP project.

```hcl

module "dataplex" {
  source     = "./fabric/modules/cloud-dataplex"
  name       = "terraform-lake"
  prefix     = "test"
  project_id = "myproject"
  region     = "europe-west2"
  zones = {
    zone_1 = {
      type      = "RAW"
      discovery = true
      assets = {
        asset_1 = {
          bucket_name            = "asset_1"
          cron_schedule          = "15 15 * * *"
          discovery_spec_enabled = true
          resource_spec_type     = "STORAGE_BUCKET"
        }
      }
    },
    zone_2 = {
      type      = "CURATED"
      discovery = true
      assets = {
        asset_2 = {
          bucket_name            = "asset_2"
          cron_schedule          = "15 15 * * *"
          discovery_spec_enabled = true
          resource_spec_type     = "STORAGE_BUCKET"
        }
      }
    }
  }
}

# tftest modules=1 resources=5
```
## TODO

- [ ] Add IAM support
- [ ] support different type of assets
- [ ] support multi-regions
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L23) | Name of Dataplex Lake. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L28) | Optional prefix used to generate Dataplex Lake. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L33) | The ID of the project where this Dataplex Lake will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L38) | Region of the Dataplax Lake. | <code>string</code> | ✓ |  |
| [zones](variables.tf#L43) | Dataplex lake zones, such as `RAW` and `CURATED`. | <code title="map&#40;object&#40;&#123;&#10;  type      &#61; string&#10;  discovery &#61; optional&#40;bool, true&#41;&#10;  assets &#61; map&#40;object&#40;&#123;&#10;    bucket_name            &#61; string&#10;    cron_schedule          &#61; optional&#40;string, &#34;15 15 &#42; &#42; &#42;&#34;&#41;&#10;    discovery_spec_enabled &#61; optional&#40;bool, true&#41;&#10;    resource_spec_type     &#61; optional&#40;string, &#34;STORAGE_BUCKET&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [location_type](variables.tf#L17) | The location type of the Dataplax Lake. | <code>string</code> |  | <code>&#34;SINGLE_REGION&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [assets](outputs.tf#L17) | Assets attached to the lake of Dataplex Lake. |  |
| [id](outputs.tf#L22) | Fully qualified Dataplex Lake id. |  |
| [lake](outputs.tf#L27) | The lake name of Dataplex Lake. |  |
| [zones](outputs.tf#L32) | The zone name of Dataplex Lake. |  |

<!-- END TFDOC -->
