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

locals {
  parent_prefix     = "//compute.googleapis.com"
  parent_net_prefix = "${local.parent_prefix}/projects/${data.google_project.project.number}/zones/${var.zone}/instances"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_tags_tag_binding" "binding" {
  for_each  = var.create_template ? {} : coalesce(var.tag_bindings, {})
  parent    = "${local.parent_prefix}/${google_compute_instance.default.0.id}"
  tag_value = each.value
}

resource "google_tags_location_tag_binding" "network_binding" {
  for_each  = var.create_template ? {} : coalesce(var.network_tag_bindings, {})
  location  = var.zone
  parent    = "${local.parent_net_prefix}/${google_compute_instance.default.0.instance_id}"
  tag_value = each.value
}
