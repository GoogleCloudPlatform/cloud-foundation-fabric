# Dataplex DataScan

This module manages the creation of Dataplex DataScan resources.

<!-- BEGIN TOC -->
- [Data Profiling](#data-profiling)
- [Data Quality](#data-quality)
- [Data Source](#data-source)
- [Execution Schedule](#execution-schedule)
- [IAM](#iam)
- [TODO](#todo)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Data Profiling

This example shows how to create a Data Profiling scan. To create an Data Profiling scan, provide the `data_profile_spec` input arguments as documented in <https://cloud.google.com/dataplex/docs/reference/rest/v1/DataProfileSpec>.

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  labels = {
    billing_id = "a"
  }
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  data_profile_spec = {
    sampling_percent = 100
    row_filter       = "station_id > 1000"
  }
  incremental_field = "modified_date"
}
# tftest modules=1 resources=1 inventory=datascan_profiling.yaml
```

## Data Quality

To create an Data Quality scan, provide the `data_quality_spec` input arguments as documented in <https://cloud.google.com/dataplex/docs/reference/rest/v1/DataQualitySpec>.

Documentation for the supported rule types and rule specifications can be found in <https://cloud.google.com/dataplex/docs/reference/rest/v1/DataQualityRule>.

This example shows how to create a Data Quality scan.

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
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
  incremental_field = "modified_date"
  data_quality_spec = {
    sampling_percent = 100
    row_filter       = "station_id > 1000"
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
      },
      {
        dimension = "VALIDITY"
        sql_assertion = {
          sql_statement = <<-EOT
            SELECT
              city_asset_number, council_district
            FROM $${data()}
            WHERE city_asset_number IS NOT NULL
            GROUP BY 1,2
            HAVING COUNT(*) > 1
          EOT
        }
      }
    ]
  }
}
# tftest modules=1 resources=1 inventory=datascan_dq.yaml
```

This example shows how you can pass the rules configurations as a separate YAML file into the module. This should produce the same DataScan configuration as the previous example.

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
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
  incremental_field = "modified_date"
  factories_config = {
    data_quality_spec = "config/data_quality_spec.yaml"
  }
}
# tftest modules=1 resources=1 files=data_quality_spec inventory=datascan_dq.yaml
```

The content of the `config/data_quality_spec.yaml` files is as follows:

```yaml
# tftest-file id=data_quality_spec path=config/data_quality_spec.yaml
sampling_percent: 100
row_filter: "station_id > 1000"
rules:
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
  - dimension: VALIDITY
    sql_assertion:
      sql_statement: |
        SELECT
          city_asset_number, council_district
        FROM ${data()}
        WHERE city_asset_number IS NOT NULL
        GROUP BY 1,2
        HAVING COUNT(*) > 1
```

While the module only accepts input in snake_case, the YAML file provided to the `data_quality_spec_file` variable can use either camelCase or snake_case. This example below should also produce the same DataScan configuration as the previous examples.

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
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
  incremental_field = "modified_date"
  factories_config = {
    data_quality_spec = "config/data_quality_spec_camel_case.yaml"
  }
}
# tftest modules=1 resources=1 files=data_quality_spec_camel_case inventory=datascan_dq.yaml
```

The content of the `config/data_quality_spec_camel_case.yaml` files is as follows:

```yaml
# tftest-file id=data_quality_spec_camel_case path=config/data_quality_spec_camel_case.yaml
samplingPercent: 100
rowFilter: "station_id > 1000"
rules:
  - column: address
    dimension: VALIDITY
    ignoreNull: null
    nonNullExpectation: {}
    threshold: 0.99
  - column: council_district
    dimension: VALIDITY
    ignoreNull: true
    threshold: 0.9
    rangeExpectation:
      maxValue: '10'
      minValue: '1'
      strictMaxEnabled: false
      strictMinEnabled: true
  - column: council_district
    dimension: VALIDITY
    rangeExpectation:
      maxValue: '9'
      minValue: '3'
    threshold: 0.8
  - column: power_type
    dimension: VALIDITY
    ignoreNull: false
    regexExpectation:
      regex: .*solar.*
  - column: property_type
    dimension: VALIDITY
    ignoreNull: false
    setExpectation:
      values:
      - sidewalk
      - parkland
  - column: address
    dimension: UNIQUENESS
    uniquenessExpectation: {}
  - column: number_of_docks
    dimension: VALIDITY
    statisticRangeExpectation:
      maxValue: '15'
      minValue: '5'
      statistic: MEAN
      strictMaxEnabled: true
      strictMinEnabled: true
  - column: footprint_length
    dimension: VALIDITY
    rowConditionExpectation:
      sqlExpression: footprint_length > 0 AND footprint_length <= 10
  - dimension: VALIDITY
    tableConditionExpectation:
      sqlExpression: COUNT(*) > 0
  - dimension: VALIDITY
    sqlAssertion:
      sqlStatement: |
        SELECT
          city_asset_number, council_district
        FROM ${data()}
        WHERE city_asset_number IS NOT NULL
        GROUP BY 1,2
        HAVING COUNT(*) > 1
```

## Data Source

The input variable 'data' is required to create a DataScan. This value is immutable. Once it is set, you cannot change the DataScan to another source.

The input variable 'data' should be an object containing a single key-value pair that can be one of:

- `entity`: The Dataplex entity that represents the data source (e.g. BigQuery table) for DataScan, of the form: `projects/{project_number}/locations/{locationId}/lakes/{lakeId}/zones/{zoneId}/entities/{entityId}`.
- `resource`: The service-qualified full resource name of the cloud resource for a DataScan job to scan against. The field could be: BigQuery table of type "TABLE" for DataProfileScan/DataQualityScan format, e.g: `//bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET_ID/tables/TABLE_ID`.

The example below shows how to specify the data source for DataScan of type `resource`:

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  data_profile_spec = {}
}
# tftest modules=1 resources=1
```

The example below shows how to specify the data source for DataScan of type `entity`:

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  data = {
    entity = "projects/<project_number>/locations/<locationId>/lakes/<lakeId>/zones/<zoneId>/entities/<entityId>"
  }
  data_profile_spec = {}
}
# tftest modules=1 resources=1 inventory=datascan_entity.yaml
```

## Execution Schedule

The input variable 'execution_schedule' specifies when a scan should be triggered, based on a cron schedule expression.

If not specified, the default is `on_demand`, which means the scan will not run until the user calls `dataScans.run` API.

The following example shows how to schedule the DataScan at 1AM everyday using 'America/New_York' timezone.

```hcl
module "dataplex-datascan" {
  source             = "./fabric/modules/dataplex-datascan"
  name               = "datascan"
  prefix             = "test"
  project_id         = "my-project-name"
  region             = "us-central1"
  execution_schedule = "TZ=America/New_York 0 1 * * *"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  data_profile_spec = {}
}

# tftest modules=1 resources=1 inventory=datascan_cron.yaml
```

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

An example is provided below for using some of these variables. Refer to the [project module](../project/README.md#iam) for complete examples of the IAM interface.

```hcl
module "dataplex-datascan" {
  source     = "./fabric/modules/dataplex-datascan"
  name       = "datascan"
  prefix     = "test"
  project_id = "my-project-name"
  region     = "us-central1"
  data = {
    resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
  }
  data_profile_spec = {}
  iam = {
    "roles/dataplex.dataScanAdmin" = [
      "serviceAccount:svc-1@project-id.iam.gserviceaccount.com"
    ],
    "roles/dataplex.dataScanEditor" = [
      "user:admin-user@example.com"
    ]
  }
  iam_by_principals = {
    "group:user-group@example.com" = [
      "roles/dataplex.dataScanViewer"
    ]
  }
  iam_bindings_additive = {
    am1-viewer = {
      member = "user:am1@example.com"
      role   = "roles/dataplex.dataScanViewer"
    }
  }
}
# tftest modules=1 resources=5 inventory=datascan_iam.yaml
```

## TODO
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [data](variables.tf#L17) | The data source for DataScan. The source can be either a Dataplex `entity` or a BigQuery `resource`. | <code title="object&#40;&#123;&#10;  entity   &#61; optional&#40;string&#41;&#10;  resource &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L122) | Name of Dataplex Scan. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L133) | The ID of the project where the Dataplex DataScan will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L138) | Region for the Dataplex DataScan. | <code>string</code> | ✓ |  |
| [data_profile_spec](variables.tf#L29) | DataProfileScan related setting. Variable descriptions are provided in https://cloud.google.com/dataplex/docs/reference/rest/v1/DataProfileSpec. | <code title="object&#40;&#123;&#10;  sampling_percent &#61; optional&#40;number&#41;&#10;  row_filter       &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [data_quality_spec](variables.tf#L38) | DataQualityScan related setting. Variable descriptions are provided in https://cloud.google.com/dataplex/docs/reference/rest/v1/DataQualitySpec. | <code title="object&#40;&#123;&#10;  sampling_percent &#61; optional&#40;number&#41;&#10;  row_filter       &#61; optional&#40;string&#41;&#10;  post_scan_actions &#61; optional&#40;object&#40;&#123;&#10;    bigquery_export &#61; optional&#40;object&#40;&#123;&#10;      results_table &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  rules &#61; list&#40;object&#40;&#123;&#10;    column               &#61; optional&#40;string&#41;&#10;    ignore_null          &#61; optional&#40;bool, null&#41;&#10;    dimension            &#61; string&#10;    threshold            &#61; optional&#40;number&#41;&#10;    non_null_expectation &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;    range_expectation &#61; optional&#40;object&#40;&#123;&#10;      min_value          &#61; optional&#40;number&#41;&#10;      max_value          &#61; optional&#40;number&#41;&#10;      strict_min_enabled &#61; optional&#40;bool&#41;&#10;      strict_max_enabled &#61; optional&#40;bool&#41;&#10;    &#125;&#41;&#41;&#10;    regex_expectation &#61; optional&#40;object&#40;&#123;&#10;      regex &#61; string&#10;    &#125;&#41;&#41;&#10;    set_expectation &#61; optional&#40;object&#40;&#123;&#10;      values &#61; list&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    uniqueness_expectation &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;    statistic_range_expectation &#61; optional&#40;object&#40;&#123;&#10;      statistic          &#61; string&#10;      min_value          &#61; optional&#40;number&#41;&#10;      max_value          &#61; optional&#40;number&#41;&#10;      strict_min_enabled &#61; optional&#40;bool&#41;&#10;      strict_max_enabled &#61; optional&#40;bool&#41;&#10;    &#125;&#41;&#41;&#10;    row_condition_expectation &#61; optional&#40;object&#40;&#123;&#10;      sql_expression &#61; string&#10;    &#125;&#41;&#41;&#10;    table_condition_expectation &#61; optional&#40;object&#40;&#123;&#10;      sql_expression &#61; string&#10;    &#125;&#41;&#41;&#10;    sql_assertion &#61; optional&#40;object&#40;&#123;&#10;      sql_statement &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [description](variables.tf#L88) | Custom description for DataScan. | <code>string</code> |  | <code>null</code> |
| [execution_schedule](variables.tf#L94) | Schedule DataScan to run periodically based on a cron schedule expression. If not specified, the DataScan is created with `on_demand` schedule, which means it will not run until the user calls `dataScans.run` API. | <code>string</code> |  | <code>null</code> |
| [factories_config](variables.tf#L100) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  data_quality_spec &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L24) | Dataplex DataScan IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L31) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L46) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L17) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [incremental_field](variables.tf#L109) | The unnested field (of type Date or Timestamp) that contains values which monotonically increase over time. If not specified, a data scan will run for all data in the table. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L115) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L127) | Optional prefix used to generate Dataplex DataScan ID. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [data_scan_id](outputs.tf#L17) | Dataplex DataScan ID. |  |
| [id](outputs.tf#L22) | A fully qualified Dataplex DataScan identifier for the resource with format projects/{{project}}/locations/{{location}}/dataScans/{{data_scan_id}}. |  |
| [name](outputs.tf#L27) | The relative resource name of the scan, of the form: projects/{project}/locations/{locationId}/dataScans/{datascan_id}, where project refers to a project_id or project_number and locationId refers to a GCP region. |  |
| [type](outputs.tf#L32) | The type of DataScan. |  |
<!-- END TFDOC -->
