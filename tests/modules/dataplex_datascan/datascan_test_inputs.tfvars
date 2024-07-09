# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
name       = "datascan"
prefix     = "test"
project_id = "test-project"
region     = "us-central1"
labels = {
  billing_id = "a"
}
iam = {
  "roles/dataplex.dataScanViewer" = [
    "user:user@example.com"
  ],
  "roles/dataplex.dataScanEditor" = [
    "user:user@example.com",
  ]
}
iam_by_principals = {
  "group:user-group@example.com" = [
    "roles/dataplex.dataScanEditor"
  ]
}
execution_schedule = "TZ=America/New_York 1 1 * * *"
data = {
  resource = "//bigquery.googleapis.com/projects/bigquery-public-data/datasets/austin_bikeshare/tables/bikeshare_stations"
}
description       = "Custom description."
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
