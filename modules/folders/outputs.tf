/**
 * Copyright 2018 Google LLC
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

output "folder" {
  description = "Folder resource (for single use)."
  value       = length(var.names) > 0 ? local.folders[0] : null
}

output "id" {
  description = "Folder id (for single use)."
  value       = length(var.names) > 0 ? local.folders[0].name : null
}

output "name" {
  description = "Folder name (for single use)."
  value       = length(var.names) > 0 ? local.folders[0].display_name : null
}

output "folders" {
  description = "Folder resources."
  value       = local.folders
}

output "ids" {
  description = "Folder ids."
  value       = zipmap(var.names, [for f in local.folders : f.name])
}

output "names" {
  description = "Folder names."
  value       = zipmap(var.names, [for f in local.folders : f.display_name])
}

output "ids_list" {
  description = "List of folder ids."
  value       = [for f in local.folders : f.name]
}

output "names_list" {
  description = "List of folder names."
  value       = [for f in local.folders : f.display_name]
}
