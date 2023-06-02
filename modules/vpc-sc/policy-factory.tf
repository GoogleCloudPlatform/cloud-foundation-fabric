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
  _policy_data = [
    for f in try(fileset(var.data_folder, "*.yaml"), []) :
    yamldecode(file("${var.data_folder}/${f}"))
  ]
  _policy_egress = flatten([
    for f in local._policy_data : [
      for k, v in lookup(f, "egress", {}) : merge(v, { name = k })
    ]
  ])
  _policy_ingress = flatten([
    for f in local._policy_data : [
      for k, v in lookup(f, "ingress", {}) : merge(v, { name = k })
    ]
  ])
  policy_egress = {
    for p in local._policy_egress :
    (p.name) => merge(local._policy_egress_default, p)
  }
  policy_ingress = {
    for p in local._policy_ingress :
    (p.name) => merge(local._policy_ingress_default, p)
  }
}
