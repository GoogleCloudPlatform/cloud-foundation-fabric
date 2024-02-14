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
    for f in try(fileset(var.factories_config.tags, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.factories_config.tags}/${f}"))
  }

  factory_tag_template = merge(local._factory_tag_template, var.tags)
}

resource "google_data_catalog_tag" "engine" {
  for_each = local.factory_tag_template
  parent   = "projects/${each.value.project_id}/locations/${each.value.project_id}/entryGroups/@bigquery/entries/${trim(base64encode(each.value.parent), "=")}"
  column   = try(each.value.column, null)
  template = each.value.template
  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_name   = fields.key
      string_value = fields.value
    }
  }
}
