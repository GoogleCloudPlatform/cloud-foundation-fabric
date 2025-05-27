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

locals {
  boot_disk_tags = flatten([
    for k, v in var.tag_bindings : [
      for dk, dv in google_compute_disk.boot : {
        disk_id   = dv.disk_id
        key       = "${dk}/${k}"
        tag_value = v
      }
    ]
  ])
  disk_tags = flatten([
    for k, v in var.tag_bindings : [
      for dk, dv in google_compute_disk.disks : {
        disk_id   = dv.disk_id
        key       = "${dk}/${k}"
        tag_value = v
      }
    ]
  ])
  region_disk_tags = flatten([
    for k, v in var.tag_bindings : [
      for dk, dv in google_compute_region_disk.disks : {
        disk_id   = dv.disk_id
        key       = "${dk}/${k}"
        tag_value = v
      }
    ]
  ])
  tag_parent_base = format(
    "//compute.googleapis.com/projects/%s",
    coalesce(var.project_number, var.project_id)
  )
}

# use a different resource to avoid overlapping key issues

resource "google_tags_location_tag_binding" "network" {
  for_each = local.template_create ? {} : var.network_tag_bindings
  parent = (
    "${local.tag_parent_base}/zones/${var.zone}/instances/${google_compute_instance.default[0].instance_id}"
  )
  tag_value = each.value
  location  = var.zone
}

resource "google_tags_location_tag_binding" "instance" {
  for_each = local.template_create ? {} : var.tag_bindings
  parent = (
    "${local.tag_parent_base}/zones/${var.zone}/instances/${google_compute_instance.default[0].instance_id}"
  )
  tag_value = each.value
  location  = var.zone
}

resource "google_tags_location_tag_binding" "boot_disks" {
  for_each = (
    local.template_create ? {} : { for v in local.boot_disk_tags : v.key => v }
  )
  parent = (
    "${local.tag_parent_base}/zones/${var.zone}/disks/${each.value.disk_id}"
  )
  tag_value = each.value.tag_value
  location  = var.zone
}

resource "google_tags_location_tag_binding" "disks" {
  for_each = (
    local.template_create ? {} : { for v in local.disk_tags : v.key => v }
  )
  parent = (
    "${local.tag_parent_base}/zones/${var.zone}/disks/${each.value.disk_id}"
  )
  tag_value = each.value.tag_value
  location  = var.zone
}

resource "google_tags_location_tag_binding" "disks_regional" {
  for_each = (
    local.template_create ? {} : { for v in local.region_disk_tags : v.key => v }
  )
  parent = (
    "${local.tag_parent_base}/regions/${local.region}/disks/${each.value.disk_id}"
  )
  tag_value = each.value.tag_value
  location  = local.region
}

# TODO: enable once the template id is available

# resource "google_tags_location_tag_binding" "template" {
#   for_each = local.template_create ? var.tag_bindings : {}
#   parent = (
#     "${local.tag_parent_base}/regions/${local.region}/instanceTemplates/${google_compute_instance.default[0].instance_id}"
#   )
#   tag_value = each.value
#   location  = local.region
# }
