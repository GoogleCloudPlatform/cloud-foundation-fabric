/**
 * Copyright 2024 Google LLC
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
  # read factory data
  _tt_path = try(pathexpand(var.factories_config.tag_templates), null)
  _tt_files = try(
    fileset(local._tt_path, "**/*.yaml"),
    []
  )
  _tt = {
    for f in local._tt_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._tt_path, "-")}/${f}"
    ))
  }
  # normalize factory data and merge
  tag_templates = merge({
    for k, v in local._tt : k => {
      display_name = lookup(v, "display_name", null)
      force_delete = lookup(v, "force_delete", false)
      region       = lookup(v, "region", null)
      fields = {
        for fk, fv in v.fields : fk => {
          display_name = lookup(fv, "display_name", null)
          description  = lookup(fv, "description", null)
          is_required  = lookup(fv, "is_required", false)
          order        = lookup(fv, "order", null)
          type = merge(
            { primitive_type = null, enum_type_values = null },
            fv.type
          )
        }
      }
      iam                   = lookup(v, "iam", {})
      iam_bindings          = lookup(v, "iam_bindings", {})
      iam_bindings_additive = lookup(v, "iam_bindings_additive", {})
    }
  }, var.tag_templates)
}

resource "google_data_catalog_tag_template" "default" {
  for_each = local.tag_templates
  project  = var.project_id
  region = lookup(
    var.factories_config,
    coalesce(each.value.region, var.region),
    coalesce(each.value.region, var.region)
  )
  tag_template_id = each.key
  display_name    = each.value.display_name
  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_id     = fields.key
      display_name = fields.value.display_name
      description  = fields.value.description
      is_required  = fields.value.is_required
      order        = fields.value.order
      dynamic "type" {
        for_each = fields.value.type.primitive_type != null ? [""] : []
        content {
          primitive_type = fields.value.type.primitive_type
        }
      }
      dynamic "type" {
        for_each = fields.value.type.enum_type_values != null ? [""] : []
        content {
          enum_type {
            dynamic "allowed_values" {
              for_each = toset(fields.value.type.enum_type_values)
              content {
                display_name = allowed_values.key
              }
            }
          }
        }
      }
    }
  }
  force_delete = try(each.value.force_delete, false)
}
