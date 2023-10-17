/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Tag bindings.

# TODO: re-implement once
# - the provider accepts a project id in the parent without a permadiff
# - the disk resource exposes an id that can be used to build the parent

# locals {
#   tag_parent_base = (
#     "//compute.googleapis.com/projects/${var.project_id}/zones/${var.zone}"
#   )
# }

# resource "google_tags_location_tag_binding" "instance" {
#   for_each = var.create_template ? {} : coalesce(var.tag_bindings, {})
#   parent = (
#     "${local.tag_parent_base}/instances/${google_compute_instance.default.0.instance_id}"
#   )
#   tag_value = each.value
#   location  = var.zone
# }
