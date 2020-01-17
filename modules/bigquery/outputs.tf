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

output "datasets" {
  description = "Dataset resources."
  value = [
    for _, resource in google_bigquery_dataset.datasets :
    resource
  ]
}

output "ids" {
  description = "Dataset ids."
  value = [
    for _, resource in google_bigquery_dataset.datasets :
    resource.id
  ]
}

output "names" {
  description = "Dataset names."
  value = [
    for _, resource in google_bigquery_dataset.datasets :
    resource.friendly_name
  ]
}

output "self_links" {
  description = "Dataset self links."
  value = [
    for _, resource in google_bigquery_dataset.datasets :
    resource.self_link
  ]
}
