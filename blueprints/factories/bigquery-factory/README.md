# Google Cloud BQ Factory

This module allows creation and management of BigQuery datasets tables and views by defining them in well-formatted YAML files. YAML abstraction for BQ can simplify users onboarding and also makes creation of tables easier compared to HCL.

This factory is based on the [BQ dataset module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/bigquery-dataset) which currently only supports tables and views. As soon as external table and materialized view support is added, this factory will be enhanced accordingly.

You can create as many files as you like, the code will loop through it and create everything accordingly.

## Example

### Terraform code

In this section we show how to create tables and views from a file structure simlar to the one shown below.
```bash
bigquery
│
├── tables
│   ├── table_a.yaml
│   ├── table_b.yaml
├── views
│   ├── view_a.yaml
│   ├── view_b.yaml
```

First we create the table definition in `bigquery/tables/countries.yaml`.

```yaml
# tftest-file id=table path=bigquery/tables/countries.yaml
dataset: my_dataset
table: countries
deletion_protection: true
labels:
  env: prod
schema:
  - name: country
    type: STRING
  - name: population
    type: INT64
```

And a view in  `bigquery/views/population.yaml`.

```yaml
# tftest-file id=view path=bigquery/views/population.yaml
dataset: my_dataset
view: department
query: SELECT SUM(population) from  my_dataset.countries
labels:
  env: prod
```

With this file structure, we can use the factory as follows:

```hcl
module "bq" {
  source      = "./fabric/blueprints/factories/bigquery-factory"
  project_id  = var.project_id
  tables_path = "bigquery/tables"
  views_path  = "bigquery/views"
}
# tftest modules=2 resources=3 files=table,view inventory=simple.yaml
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L17) | Project ID. | <code>string</code> | ✓ |  |
| [tables_path](variables.tf#L22) | Relative path for the folder storing table data. | <code>string</code> | ✓ |  |
| [views_path](variables.tf#L27) | Relative path for the folder storing view data. | <code>string</code> | ✓ |  |

<!-- END TFDOC -->

## TODO

- [ ] add external table support
- [ ] add materialized view support

