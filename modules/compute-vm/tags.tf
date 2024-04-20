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

# TODO: re-implement once the following have been addressed in the provider
# - permadiff in google_tags_location_tag_binding which returns a project
#   number in the tag id even when a project id is set
# - no numeric id exposed from the google_compute_disk resource making it
#   impossible to derive the tag binding parent
# - google_compute_instance.params.resource_manager_tags and
#   google_compute_instance.boot_disk.initialize_params.resource_manager_tags
#   attributes need a map of tag key => tag value, while only the tag value
#   is really needed by the API

# resource "google_tags_location_tag_binding" "instance" {
#   for_each = var.create_template ? {} : coalesce(var.tag_bindings, {})
#   parent = (
#     "${local.tag_parent_base}/instances/${google_compute_instance.default[0].instance_id}"
#   )
#   tag_value = each.value
#   location  = var.zone
# }
