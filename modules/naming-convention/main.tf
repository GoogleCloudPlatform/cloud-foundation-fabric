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

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  suffix = var.suffix == null ? "" : "-${var.suffix}"
  // merge common and per-resource labels
  labels = {
    for resource_type, resources in var.resources : resource_type => {
      for name in resources : name => merge(
        // change this line if you need different tokens
        { environment = var.environment, team = var.team },
        try(var.labels[resource_type][name], {})
      )
    }
  }
  // create per-resource names by assembling tokens
  names = {
    for resource_type, resources in var.resources : resource_type => {
      for name in resources : name => join(
        try(var.separator_override[resource_type], "-"),
        compact([
          var.use_resource_prefixes ? resource_type : "",
          var.prefix,
          // change these lines if you need different tokens
          var.team,
          var.environment,
          name,
          var.suffix
      ]))
    }
  }
}
