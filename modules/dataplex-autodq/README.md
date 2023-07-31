# Dataplex AutoDQ

This module manages the creation of Dataplex AutoDQ DataScan resources.

## Data Profiling

This example shows how to create a Data Profiling scan using AutoDQ. To create an AutoDQ Data Profiling scan, do not provide any input to the `rules` variable.

```hcl
module "dataplex-autodq" {
  source     = "./fabric/modules/dataplex-autodq"
  name       = "autodq"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  labels = {
    billing_id = "a"
  }
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  sampling_percent  = 100
  row_filter        = "station_id > 1000"
  incremental_field = "modified_date"
}
# tftest modules=1 resources=1 inventory=datascan_profiling.yaml
```

## Data Quality

This example shows how to create a Data Quality scan using AutoDQ. Please refer to [this page](https://cloud.example.com/dataplex/docs/reference/rest/v1/DataQualityRule) for the rule types and specifications. You need to convert any variable names in the linked page from `CamelCase` to `snake_case`.

```hcl
module "dataplex-autodq" {
  source     = "./fabric/modules/dataplex-autodq"
  name       = "autodq"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  labels = {
    billing_id = "a"
  }
  execution_schedule = "TZ=America/New_York 0 1 * * *"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  sampling_percent  = 100
  row_filter        = "station_id > 1000"
  incremental_field = "modified_date"
  rules = [
    {
      dimension            = "VALIDITY"
      non_null_expectation = {}
      column               = "address"
      threshold            = 0.99
    },
    {
      column      = "council_district"
      dimension   = "VALIDITY"
      ignore_null = true
      threshold   = 0.9
      range_expectation = {
        min_value          = 1
        max_value          = 10
        strict_min_enabled = true
        strict_max_enabled = false
      }
    },
    {
      column    = "council_district"
      dimension = "VALIDITY"
      threshold = 0.8
      range_expectation = {
        min_value = 3
        max_value = 9
      }
    },
    {
      column      = "power_type"
      dimension   = "VALIDITY"
      ignore_null = false
      regex_expectation = {
        regex = ".*solar.*"
      }
    },
    {
      column      = "property_type"
      dimension   = "VALIDITY"
      ignore_null = false
      set_expectation = {
        values = ["sidewalk", "parkland"]
      }
    },
    {
      column                 = "address"
      dimension              = "UNIQUENESS"
      uniqueness_expectation = {}
    },
    {
      column    = "number_of_docks"
      dimension = "VALIDITY"
      statistic_range_expectation = {
        statistic          = "MEAN"
        min_value          = 5
        max_value          = 15
        strict_min_enabled = true
        strict_max_enabled = true
      }
    },
    {
      column    = "footprint_length"
      dimension = "VALIDITY"
      row_condition_expectation = {
        sql_expression = "footprint_length > 0 AND footprint_length <= 10"
      }
    },
    {
      dimension = "VALIDITY"
      table_condition_expectation = {
        sql_expression = "COUNT(*) > 0"
      }
    }
  ]
}
# tftest modules=1 resources=1 inventory=datascan_dq.yaml
```

This example shows how you can pass the rules configurations as a separate YAML file into the module.

```hcl
module "dataplex-autodq" {
  source     = "./fabric/modules/dataplex-autodq"
  name       = "autodq"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  labels = {
    billing_id = "a"
  }
  execution_schedule = "TZ=America/New_York 0 1 * * *"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  sampling_percent  = 100
  row_filter        = "station_id > 1000"
  incremental_field = "modified_date"
  rules             = yamldecode(file("config/rules.yaml"))
}
# tftest modules=1 resources=1 files=rules inventory=datascan_dq.yaml
```

The content of the `config/rules.yaml` files is as follows:

```yaml
# tftest-file id=rules path=config/rules.yaml
- column: address
  dimension: VALIDITY
  ignore_null: null
  non_null_expectation: {}
  threshold: 0.99
- column: council_district
  dimension: VALIDITY
  ignore_null: true
  threshold: 0.9
  range_expectation:
    max_value: '10'
    min_value: '1'
    strict_max_enabled: false
    strict_min_enabled: true
- column: council_district
  dimension: VALIDITY
  range_expectation:
    max_value: '9'
    min_value: '3'
  threshold: 0.8
- column: power_type
  dimension: VALIDITY
  ignore_null: false
  regex_expectation:
    regex: .*solar.*
- column: property_type
  dimension: VALIDITY
  ignore_null: false
  set_expectation:
    values:
    - sidewalk
    - parkland
- column: address
  dimension: UNIQUENESS
  uniqueness_expectation: {}
- column: number_of_docks
  dimension: VALIDITY
  statistic_range_expectation:
    max_value: '15'
    min_value: '5'
    statistic: MEAN
    strict_max_enabled: true
    strict_min_enabled: true
- column: footprint_length
  dimension: VALIDITY
  row_condition_expectation:
    sql_expression: footprint_length > 0 AND footprint_length <= 10
- dimension: VALIDITY
  table_condition_expectation:
    sql_expression: COUNT(*) > 0
```

## Data Source

The input variable 'data' is required to create a DataScan. This value is immutable. Once it is set, you cannot change the DataScan to another sources.

The input variable 'data' should be an object containing a single key-value pair that can be one of:
* `entity`: The Dataplex entity that represents the data source (e.g. BigQuery table) for DataScan, of the form: `projects/{project_number}/locations/{locationId}/lakes/{lakeId}/zones/{zoneId}/entities/{entityId}`.
* `resource`: The service-qualified full resource name of the cloud resource for a DataScan job to scan against. The field could be: BigQuery table of type "TABLE" for DataProfileScan/DataQualityScan format, e.g: `//bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET_ID/tables/TABLE_ID`.

The example below shows how to specify the data source for DataScan of type `resource`:

```hcl
module "dataplex-autodq" {
  source     = "./fabric/modules/dataplex-autodq"
  name       = "autodq"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
}
# tftest modules=1 resources=1
```

The example below shows how to specify the data source for DataScan of type `entity`:

```hcl
module "dataplex-autodq" {
  source     = "./fabric/modules/dataplex-autodq"
  name       = "autodq"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  data = {
    entity = "projects/<project_number>/locations/<locationId>/lakes/<lakeId>/zones/<zoneId>/entities/<entityId>"
  }
}
# tftest modules=1 resources=1 inventory=datascan_entity.yaml
```

## Execution Schedule

The input variable 'execution_schedule' specifies when a scan should be triggered, based on a cron schedule expression.

If not specified, the default is `on_demand`, which means the scan will not run until the user calls `dataScans.run` API.

The following example shows how to schedule the DataScan at 1AM everyday using 'America/New_York' timezone.

```hcl
module "dataplex-autodq" {
  source             = "./fabric/modules/dataplex-autodq"
  name               = "autodq"
  prefix             = "test"
  project_id         = "my-project-name"
  region             = "us-central1"
  execution_schedule = "TZ=America/New_York 0 1 * * *"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
}

# tftest modules=1 resources=1 inventory=datascan_cron.yaml
```

## IAM


There are three mutually exclusive ways of managing IAM in this module

- non-authoritative via the `iam_additive` and `iam_additive_members` variables, where bindings created outside this module will coexist with those managed here
- authoritative via the `group_iam` and `iam` variables, where bindings created outside this module (eg in the console) will be removed at each `terraform apply` cycle if the same role is also managed here
- authoritative policy via the `iam_policy` variable, where any binding created outside this module (eg in the console) will be removed at each `terraform apply` cycle regardless of the role

The authoritative and additive approaches can be used together, provided different roles are managed by each. The IAM policy is incompatible with the other approaches, and must be used with extreme care.

Some care must also be taken with the `group_iam` variable (and in some situations with the additive variables) to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

An example is provided beow for using `group_iam` and `iam` variables.

```hcl
module "dataplex-autodq" {
  source     = "./fabric/modules/dataplex-autodq"
  name       = "autodq"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  iam = {
    "roles/dataplex.dataScanAdmin" = [
      "serviceAccount:svc-1@project-id.iam.gserviceaccount.com"
    ],
    "roles/dataplex.dataScanEditor" = [
      "user:admin-user@example.com"
    ]
  }
  group_iam = {
    "user-group@example.com" = [
      "roles/dataplex.dataScanViewer"
    ]
  }
}
# tftest modules=1 resources=4 inventory=datascan_iam.yaml
```

## TODO

- [ ] enable custom descriptions
- [ ] enable yaml rules input
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [data](variables.tf#L17) | The data source for DataScan. The source can be either a Dataplex `entity` or a BigQuery `resource`. | <code title="object&#40;&#123;&#10;  entity   &#61; optional&#40;string&#41;&#10;  resource &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L81) | Name of Dataplex AutoDQ Scan. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L92) | The ID of the project where the Dataplex AutoDQ Scans will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L97) | Region for the Dataplex AutoDQ Scan. | <code>string</code> | ✓ |  |
| [execution_schedule](variables.tf#L29) | Schedule DataScan to run periodically based on a cron schedule expression. If not specified, the DataScan is created with `on_demand` schedule, which means it will not run until the user calls `dataScans.run` API. | <code>string</code> |  | <code>null</code> |
| [group_iam](variables.tf#L35) | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L42) | Dataplex AutoDQ  IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_additive](variables.tf#L49) | IAM additive bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_additive_members](variables.tf#L56) | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_policy](variables.tf#L62) | IAM authoritative policy in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared, use with extreme caution. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>null</code> |
| [incremental_field](variables.tf#L68) | The unnested field (of type Date or Timestamp) that contains values which monotonically increase over time. If not specified, a data scan will run for all data in the table. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L74) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L86) | Optional prefix used to generate Dataplex AutoDQ DataScan ID. | <code>string</code> |  | <code>null</code> |
| [row_filter](variables.tf#L102) | A filter applied to all rows in a single DataScan job. The filter needs to be a valid SQL expression for a WHERE clause in BigQuery standard SQL syntax. Example: col1 >= 0 AND col2 < 10. | <code>string</code> |  | <code>null</code> |
| [rules](variables.tf#L108) | Data Quality validation rules. If not provided, the DataScan will be created as a Data Profiling scan instead of a Data Quality scan. | <code title="list&#40;object&#40;&#123;&#10;  column               &#61; optional&#40;string&#41;&#10;  ignore_null          &#61; optional&#40;bool, null&#41;&#10;  dimension            &#61; string&#10;  threshold            &#61; optional&#40;number&#41;&#10;  non_null_expectation &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  range_expectation &#61; optional&#40;object&#40;&#123;&#10;    min_value          &#61; optional&#40;number&#41;&#10;    max_value          &#61; optional&#40;number&#41;&#10;    strict_min_enabled &#61; optional&#40;bool&#41;&#10;    strict_max_enabled &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  regex_expectation &#61; optional&#40;object&#40;&#123;&#10;    regex &#61; string&#10;  &#125;&#41;&#41;&#10;  set_expectation &#61; optional&#40;object&#40;&#123;&#10;    values &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  uniqueness_expectation &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  statistic_range_expectation &#61; optional&#40;object&#40;&#123;&#10;    statistic          &#61; string&#10;    min_value          &#61; optional&#40;number&#41;&#10;    max_value          &#61; optional&#40;number&#41;&#10;    strict_min_enabled &#61; optional&#40;bool&#41;&#10;    strict_max_enabled &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  row_condition_expectation &#61; optional&#40;object&#40;&#123;&#10;    sql_expression &#61; string&#10;  &#125;&#41;&#41;&#10;  table_condition_expectation &#61; optional&#40;object&#40;&#123;&#10;    sql_expression &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [sampling_percent](variables.tf#L161) | The percentage of the records to be selected from the dataset for DataScan. Value can range between 0.0 and 100.0 with up to 3 significant decimal digits. Sampling is not applied if samplingPercent is not specified, 0 or 100. | <code>number</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [data_scan_id](outputs.tf#L17) | Dataplex AutoDQ DataScan ID. |  |
| [id](outputs.tf#L22) | A fully qualified Dataplex AutoDQ DataScan identifier for the resource with format projects/{{project}}/locations/{{location}}/dataScans/{{data_scan_id}}. |  |
| [name](outputs.tf#L27) | The relative resource name of the scan, of the form: projects/{project}/locations/{locationId}/dataScans/{datascan_id}, where project refers to a project_id or project_number and locationId refers to a GCP region. |  |
| [type](outputs.tf#L32) | The type of DataScan. |  |
<!-- END TFDOC -->
