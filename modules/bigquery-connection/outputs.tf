/**
 * Copyright 2025 Google LLC
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

output "connection_config" {
  description = "The connection configuration."
  value = {
    aws            = one(google_bigquery_connection.connection.aws)
    azure          = one(google_bigquery_connection.connection.azure)
    cloud_resource = one(google_bigquery_connection.connection.cloud_resource)
    cloud_spanner  = one(google_bigquery_connection.connection.cloud_spanner)
    cloud_sql      = one(google_bigquery_connection.connection.cloud_sql)
    spark          = one(google_bigquery_connection.connection.spark)
  }
}

output "connection_id" {
  description = "The ID of the BigQuery connection."
  value       = google_bigquery_connection.connection.connection_id
}

output "description" {
  description = "The description of the connection."
  value       = google_bigquery_connection.connection.description
}

output "location" {
  description = "The location of the connection."
  value       = google_bigquery_connection.connection.location
}
