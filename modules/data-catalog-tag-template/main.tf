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
  _factory_tag_template = {
    for f in try(fileset(var.factories_config.tag_templates, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.factories_config.tag_templates}/${f}"))
  }

  factory_tag_template = merge(local._factory_tag_template, var.tag_templates)
}

resource "google_data_catalog_tag_template" "tag_template" {
  for_each        = local.factory_tag_template
  project         = var.project_id
  tag_template_id = each.key
  region          = each.value.region
  display_name    = try(each.value.display_name, null)

  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_id     = fields.key
      display_name = try(fields.value["display_name"], null)
      is_required  = try(fields.value["is_required"], false)
      type {
        primitive_type = try(fields.value["type"].primitive_type, null)
        dynamic "enum_type" {
          for_each = try(fields.value["type"].enum_type != null, false) ? ["1"] : []
          content {
            dynamic "allowed_values" {
              for_each = fields.value["type"].enum_type
              content {
                display_name = allowed_values.value
              }
            }
          }
        }
      }
    }
  }

  force_delete = try(each.value.force_delete, false)
}
