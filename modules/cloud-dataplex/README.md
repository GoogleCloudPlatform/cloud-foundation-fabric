# Cloud Dataplex instance with lake, zone & assests

This module manages the creation of Cloud Dataplex instance along with lake, zone & assets in single regions. 


## Simple example

This example shows how to setup a Cloud Dataplex instance, lake, zone & asset creation in GCP project.

```hcl

module "dataplex" {
  source      = "./fabric/modules/cloud-dataplex"
  name        = "terraform-lake"
  prefix      = "test"
  project_id  = "myproject"
  region      = "europe-west2"
  zone_name   = "zone"
  asset_name  = "test_gcs"
  bucket_name = "test_gcs"
}

# tftest modules=1 resources=3
```
## TODO

- Add IAM support
- support multiple zone definition (unspecified, raw, curated)
- support multiple asset definition and mapping to the zone
- support different type of assets
- support multi-regions
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [asset_name](variables.tf#L18) | Asset of the Dataplex Asset. | <code>string</code> |  | <code>&#34;test_gcs&#34;</code> |
| [bucket_name](variables.tf#L24) | Bucket name of the Dataplex asset. | <code>string</code> |  | <code>&#34;test_gcs&#34;</code> |
| [cron_schedule](variables.tf#L30) | The schedule of data discovery of the Dataplax Lake. | <code>string</code> |  | <code>&#34;15 15 &#42; &#42; &#42;&#34;</code> |
| [discovery_spec_enabled](variables.tf#L36) | Bucket name of the Dataplex asset. | <code>string</code> |  | <code>&#34;true&#34;</code> |
| [enabled](variables.tf#L42) | Bucket name of the Dataplex asset. | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [location_type](variables.tf#L48) | The location type of the Dataplax Lake. | <code>string</code> |  | <code>&#34;SINGLE_REGION&#34;</code> |
| [name](variables.tf#L54) | Name of dataplex lake instance. | <code>string</code> |  | <code>&#34;terraform-lake&#34;</code> |
| [prefix](variables.tf#L60) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>&#34;test&#34;</code> |
| [project_id](variables.tf#L66) | The ID of the project where this instances will be created. | <code>string</code> |  | <code>&#34;myproject&#34;</code> |
| [region](variables.tf#L72) | Region of the Dataplax Lake. | <code>string</code> |  | <code>&#34;europe-west2&#34;</code> |
| [resource_spec_type](variables.tf#L78) | Resource specification type of the Dataplax Asset. | <code>string</code> |  | <code>&#34;STORAGE_BUCKET&#34;</code> |
| [zone_name](variables.tf#L84) | Zone of the Dataplex Zone. | <code>string</code> |  | <code>&#34;zone&#34;</code> |
| [zone_type](variables.tf#L90) | Zone type for the Dataplex lake. Either `RAW` or `CURATED`. | <code>string</code> |  | <code>&#34;RAW&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [asset](outputs.tf#L17) | The assest attached to the lake of dataplex. |  |
| [lake](outputs.tf#L22) | The lake name of dataplex. |  |

<!-- END TFDOC -->
