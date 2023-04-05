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
| [name](variables.tf#L30) | Name of dataplex lake instance. | <code>string</code> |  | <code>&#34;terraform-lake&#34;</code> |
| [prefix](variables.tf#L36) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>&#34;test&#34;</code> |
| [project_id](variables.tf#L42) | The ID of the project where this instances will be created. | <code>string</code> |  | <code>&#34;myproject&#34;</code> |
| [region](variables.tf#L48) | Region of the Dataplax Lake. | <code>string</code> |  | <code>&#34;europe-west2&#34;</code> |
| [zone_name](variables.tf#L54) | Zone of the Dataplex Zone. | <code>string</code> |  | <code>&#34;zone&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [asset](outputs.tf#L17) | The assest attached to the lake of dataplex. |  |
| [lake](outputs.tf#L22) | The lake name of dataplex. |  |

<!-- END TFDOC -->
