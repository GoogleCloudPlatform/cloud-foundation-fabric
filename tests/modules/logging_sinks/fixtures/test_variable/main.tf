/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "sinks" {
  source = "../../../../../modules/logging-sinks"
  sinks = [
    {
      name        = "organization-1"
      resource    = "organizations/12345678"
      filter      = "filter: org_simple"
      destination = "destination: org_simple"
      options     = null
    },
    {
      name        = "billing-1"
      resource    = "billing_accounts/12345678"
      filter      = "filter: billing_simple"
      destination = "bigquery destination: billing_simple"
      options = {
        bigquery_partitioned_tables = true
        include_children            = false
        unique_writer_identity      = null
      }
    },
    {
      name        = "folder-1"
      resource    = "folders/12345678"
      filter      = "filter: folder_simple"
      destination = "bigquery destination: folder_simple"
      options = {
        bigquery_partitioned_tables = false
        include_children            = true
        unique_writer_identity      = null
      }
    },
    {
      name        = "project-1"
      resource    = "projects/12345678"
      filter      = "filter: project-1"
      destination = "destination: project-1"
      options = {
        bigquery_partitioned_tables = null
        include_children            = true
        unique_writer_identity      = null
      }
    },
    {
      name        = "project-2"
      resource    = "projects/12345678"
      filter      = "filter: project-2"
      destination = "destination: project-2"
      options = {
        bigquery_partitioned_tables = null
        include_children            = null
        unique_writer_identity      = true
      }
    },
  ]
}

output "names" {
  value = module.sinks.names
}
