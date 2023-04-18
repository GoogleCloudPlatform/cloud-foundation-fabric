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
  zone_name  = "zone"
  asset = {
    "test_gcs" = {
      bucket_name            = "test_gcs"
      cron_schedule          = "15 15 * * *"
      discovery_spec_enabled = true
      resource_spec_type     = "STORAGE_BUCKET"
    }
  }
}

# tftest modules=1 resources=3
```
## TODO

- [ ] Add IAM support
- [ ] support multiple zone definition (unspecified, raw, curated)
- [ ] support multiple asset definition and mapping to the zone
- [ ] support different type of assets
- [ ] support multi-regions
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [asset](variables.tf#L17) | Asset of the Dataplex Lake. | <code title="map&#40;object&#40;&#123;&#10;  bucket_name            &#61; string&#10;  cron_schedule          &#61; optional&#40;string, &#34;15 15 &#42; &#42; &#42;&#34;&#41;&#10;  discovery_spec_enabled &#61; optional&#40;bool, true&#41;&#10;  resource_spec_type     &#61; optional&#40;string, &#34;STORAGE_BUCKET&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [name](variables.tf#L39) | Name of Dataplex Lake. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L44) | Optional prefix used to generate Dataplex Lake. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L49) | The ID of the project where this Dataplex Lake will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L54) | Region of the Dataplax Lake. | <code>string</code> | ✓ |  |
| [zone_name](variables.tf#L59) | Zone of the Dataplex Zone. | <code>string</code> | ✓ |  |
| [enabled](variables.tf#L27) | Discovery of the Dataplex Zone. | <code>bool</code> |  | <code>false</code> |
| [location_type](variables.tf#L33) | The location type of the Dataplax Lake. | <code>string</code> |  | <code>&#34;SINGLE_REGION&#34;</code> |
| [zone_type](variables.tf#L64) | Zone type for the Dataplex lake. Either `RAW` or `CURATED`. | <code>string</code> |  | <code>&#34;RAW&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [asset](outputs.tf#L17) | The asset attached to the lake of Dataplex Lake. |  |
| [lake](outputs.tf#L22) | The lake name of Dataplex Lake. |  |
| [zone](outputs.tf#L27) | The zone name of Dataplex Lake. |  |

<!-- END TFDOC -->
