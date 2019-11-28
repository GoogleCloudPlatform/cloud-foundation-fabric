# Opinionated BigQuery module

TODO(jccb): add description.

## Example usage

```hcl
module "bq" {
  source     = "../modules/bigquery/"
  project_id = "my-project"
  datasets = [
    {
      id          = "dataset1"
      name        = "dataset1"
      description = "dataset1 description"
      location    = "EU"
      labels = {
        environment = "dev"
      }
      # default_partition_expiration_ms = 10000
      # default_table_expiration_ms - 10000
    }  ]

  dataset_access = {
    dataset1 = {
      "me@myorg.com" : "roles/bigquery.dataViewer"
    }
  }

  tables = [
    {
      table_id    = "table1"
      dataset_id  = "dataset1"
      description = "dataset1 description"
      labels = {
        team = "sales"
      }
      schema = [
        {
          type = "DATE"
          name = "date"
        }
        {
          type = "STRING"
          name = "name"
        }
      ]
      time_partitioning = {
        field = "date"
        type  = "DAY"
      }
    }
  ]

  views = [
    {
      dataset = "dataset1"
      table   = "view1"
      query   = "select date from `my-project.dataset1.table1`"
    }
  ]
}
```

## Variables

| name           | description                                                 | type   | required |
|----------------|-------------------------------------------------------------|:------:|:--------:|
| project_id     | The ID of the project where the datasets, tables, and views | string | ✓        |
| datasets       | List of datasets to be created (see structure below)        | string |          |
| tables         | List of tables to be created (see structure below)          | string |          |
| views          | List of views to be created (see structure below)           | string |          |
| dataset_access | Dataset-level permissions to be granted                     | string |          |

### dataset structure
The datasets list should contains objects with the following structure:

``` hcl
    {
      id          = "dataset id"
      name        = "dataset name"
      description = "dataset description"
      location    = "dataset location"
      labels = { # optional
        label1 = "value1"
      }
      default_partition_expiration_ms = 10000 # optional
      default_table_expiration_ms - 10000 # optional
    }

```

### table structure

``` hcl
    {
      table_id    = "table name"
      dataset_id  = "table dataset"
      description = "table description"
      labels = {
        label1 = "value1"
      }
      schema = [
        {
          type = "DATE"
          name = "date"
        }
        {
          type = "STRING"
          name = "name"
        }
      ]
    }

```

You can optionally specify ```expiration_time```,
```time_partitioning``` and ```clustering``` for any table.


### views structure

The structure for the views field is just a dataset (where the view
will be created), the table (view name), and the query for the view. Keep in mind that the query should use the complete name for any table it references.

``` hcl
    {
      dataset = "dataset1"
      table   = "view1"
      query   = "select date from `my-project.dataset.table`"
    }
```


## Outputs

| name     | description                            |
|----------|----------------------------------------|
| datasets | Map of dataset objects keyed by name   |
| tables   | List of table objects                  |
| views    | List of table objects created as views |
