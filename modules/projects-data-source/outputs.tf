/**
 * Copyright 2023 Google LLC
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

output "project_numbers" {
  description = "List of project numbers."
  value       = [for item in local.projects_after_ignore : trimprefix(item.project, "projects/")]
}

output "projects" {
  description = "List of projects in [StandardResourceMetadata](https://cloud.google.com/asset-inventory/docs/reference/rest/v1p1beta1/resources/searchAll#StandardResourceMetadata) format."
  value       = local.projects_after_ignore
}
