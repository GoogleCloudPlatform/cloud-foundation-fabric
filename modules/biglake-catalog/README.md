# Biglake Catalog

This module allows to create a BigLake Metastore with databases and corresponding tables in each database.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Basic example](#basic-example)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Basic example

```hcl
module "biglake_catalog" {
  source     = "./fabric/modules/biglake-catalog"
  project_id = var.project_id
  name       = "my_catalog"
  location   = "US"
  databases = {
    my_database = {
      type = "HIVE"
      hive_options = {
        location_uri = "gs://my-bucket/my-database-folder"
        parameters = {
          "owner" : "John Doe"
        }
      }
      tables = {
        my_table = {
          type = "HIVE"
          hive_options = {
            table_type    = "MANAGED_TABLE"
            location_uri  = "gs://my-bucket/my-table-folder"
            input_format  = "org.apache.hadoop.mapred.SequenceFileInputFormat"
            output_format = "org.apache.hadoop.hive.ql.io.HiveSequenceFileOutputFormat"
            parameters = {
              "spark.sql.create.version"          = "3.1.3"
              "spark.sql.sources.schema.numParts" = "1"
              "transient_lastDdlTime"             = "1680894197"
              "spark.sql.partitionProvider"       = "catalog"
              "owner"                             = "John Doe"
              "spark.sql.sources.schema.part.0" = jsonencode({
                type = "struct"
                fields = [
                  {
                    name     = "id"
                    type     = "integer"
                    nullable = true
                    metadata = {}
                  },
                  {
                    name     = "name"
                    type     = "string"
                    nullable = true
                    metadata = {}
                  },
                  {
                    name     = "age"
                    type     = "integer"
                    nullable = true
                    metadata = {}
                  }
                ]
              })
              "spark.sql.sources.provider" = "iceberg"
              "provider"                   = "iceberg"
            }
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=basic.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [databases](variables.tf#L17) | Databases. | <code title="map&#40;object&#40;&#123;&#10;  type &#61; string&#10;  hive_options &#61; object&#40;&#123;&#10;    location_uri &#61; string&#10;    parameters   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#10;  tables &#61; map&#40;object&#40;&#123;&#10;    type &#61; string&#10;    hive_options &#61; object&#40;&#123;&#10;      table_type    &#61; string&#10;      location_uri  &#61; string&#10;      input_format  &#61; string&#10;      output_format &#61; string&#10;      parameters    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [location](variables.tf#L38) | Location. | <code>string</code> | ✓ |  |
| [name](variables.tf#L43) | Name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L48) | Project ID. | <code>string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [catalog](outputs.tf#L17) | Catalog. |  |
| [catalog_id](outputs.tf#L22) | Catalog ID. |  |
| [database_ids](outputs.tf#L27) | Database IDs. |  |
| [databases](outputs.tf#L32) | Databases. |  |
| [table_ids](outputs.tf#L37) | Table ids. |  |
| [tables](outputs.tf#L42) | Tables. |  |
<!-- END TFDOC -->
