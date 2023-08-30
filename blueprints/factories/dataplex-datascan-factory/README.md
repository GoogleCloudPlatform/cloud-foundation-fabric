# Dataplex DataScan Factory

<!-- BEGIN TOC -->
  - [Rule Templates](#rule-templates)
- [Variables](#variables)
<!-- END TOC -->

## Overview

This module allows creation and management of Dataplex DataScan resources based on a directory of well-formatted YAML configuration files files. YAML abstraction enable data SMEs to create data profile and data quality scans without needing to understand Terraform.

This factory is based on the [Dataplex DataScan module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/dataplex-datascan). The module can be forked and customized to your organization's needs.

## Example

Given the following directory:

```bash
datascan-specs
├── table-1
│   ├── data_profile.yaml
├── table-2
│   ├── data_quality.yaml
```

The yaml files are as follows. Documentation for the variables accepted in a DataScan config YAML file is provided in `sample-specs/example.yaml`.

```yaml
# tftest-file id=profile path=datascan-specs/table-1/data_profile.yaml
data:
  resource: "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
data_profile_spec:
```

```yaml
# tftest-file id=dq path=datascan-specs/table-2/data_quality.yaml
data:
  resource: "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
data_quality_spec:
  sampling_percent: 100
  row_filter: "station_id > 1000"
  rules:
    - column: address
      dimension: VALIDITY
      ignore_null: null
      non_null_expectation: {}
```

With this file structure, we can use the factory as follows:

```hcl
module "datascan-factory" {
  source      = "./fabric/blueprints/factories/dataplex-datascan-factory"
  project_id                        = "<my-project>"
  region                            = "us-central1"
  datascan_spec_folder              = "datascan-specs"
}
# tftest modules=2 resources=3 files=profile,dq inventory=simple.yaml
```

### Rule Templates

This module supports creating rule templates that can be referenced in each DataScan yaml.

For example, given the following rule_templates, where the key is the template name and value is the content of a data_quality_spec [DataQualityRule](https://cloud.google.com/dataplex/docs/reference/rest/v1/DataQualityRule) object.

```
rule_templates:
  valid_address:
    column: address
    dimension: VALIDITY
    ignore_null: true
    non_null_expectation: {}
    threshold: 0.99
  valid_council_district:
    column: council_district
    dimension: VALIDITY
    ignore_null: true
    threshold: 0.9
    range_expectation:
      max_value: '10'
      min_value: '1'
      strict_max_enabled: false
      strict_min_enabled: true
  valid_power_type:
    column: power_type
    dimension: VALIDITY
    ignore_null: false
    regex_expectation:
      regex: .*solar.*
  valid_property_type:
    column: property_type
    dimension: VALIDITY
    ignore_null: false
    set_expectation:
      values:
      - sidewalk
      - parkland
  unique_column:
    dimension: UNIQUENESS
    uniqueness_expectation: {}
  valid_number_of_docks:
    column: number_of_docks
    dimension: VALIDITY
    statistic_range_expectation:
      max_value: '15'
      min_value: '5'
      statistic: MEAN
      strict_max_enabled: true
      strict_min_enabled: true
  valid_footprint_length:
    column: footprint_length
    dimension: VALIDITY
    row_condition_expectation:
      sql_expression: footprint_length > 0 AND footprint_length <= 10
  not_empty:
    dimension: VALIDITY
    table_condition_expectation:
      sql_expression: COUNT($param_a) > 0
```

You can create an object with the key `use_rule_template` and specify the `template_name` argument to point to the object key in the `rule_templates` object. Additionally, you can override any variable provided in the template or supply missing variables for a rule object using the `override` argument. The `override` argument supports partial overriding of a subset of variables in a rule object.  Example usage of rule templates inside a datascan data_quality_spec is shown below.

```yaml
data_quality_scan:
  rules:
    - use_rule_template: 
        template_name: valid_council_district
    - use_rule_template: 
        template_name: valid_property_type
        override:
          set_expectation:
            values:
            - parkland
    - use_rule_template: 
        template_name: unique_column
        override:
          column: address
    - use_rule_template: 
        template_name: valid_number_of_docks
        override:
          statistic_range_expectation:
            strict_max_enabled: false
            strict_min_enabled: false
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [datascan_spec_folder](variables.tf#L41) | Relative path for the folder containing datascan YAML configuration files. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L46) | Default value for the project ID where the DataScans will be created. Cannot be overriden at the file level. | <code>string</code> | ✓ |  |
| [region](variables.tf#L51) | Default value for the region where the DataScans will be created. Cannot be overriden at the file level. | <code>string</code> | ✓ |  |
| [datascan_defaults_file_path](variables.tf#L17) | File containing default values for the datascan configurations that can be overridden at the file level. | <code>string</code> |  | <code>null</code> |
| [datascan_rule_templates_file_path](variables.tf#L35) | Relative path for the YAML file containing the rule templates that can be referenced in datascans. | <code>string</code> |  | <code>null</code> |
| [merge_iam_bindings_defaults](variables.tf#L29) | If true, merge the default iam_bindings with the provided datascan iam_bindings. If false, the provided datascan iam_bindings will override the default iam_bindings. | <code>bool</code> |  | <code>false</code> |
| [merge_labels_with_defaults](variables.tf#L23) | If true, merge the default labels with the provided datascan labels. If false, the provided datascan labels will override the default labels. | <code>bool</code> |  | <code>false</code> |
<!-- END TFDOC -->
