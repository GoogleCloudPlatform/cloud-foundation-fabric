/**
 * Copyright 2025 Google LLC
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
  _tag_bindings = {
    for k, v in var.tag_bindings : k => lookup(local.ctx.tag_values, v, v)
  }
}

resource "google_tags_location_tag_binding" "binding" {
  for_each = var.tag_bindings
  parent   = "//storage.googleapis.com/projects/_/buckets/${local._name}"
  tag_value = templatestring(local._tag_bindings[each.key], var.context.tag_vars)
  location = lookup(local.ctx.locations, var.location, var.location)
  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket_iam_binding.bindings
  ]
}
