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
  _rules_egress = {
    for name, rule in merge(var.egress_rules) :
    "egress/${name}" => merge(rule, { name = name, direction = "EGRESS" })
  }
  _rules_ingress = {
    for name, rule in merge(var.ingress_rules) :
    "ingress/${name}" => merge(rule, { name = name, direction = "INGRESS" })
  }
  rules = merge(
    local.factory_egress_rules, local.factory_ingress_rules,
    local._rules_egress, local._rules_ingress
  )
  # do not depend on the parent id as that might be dynamic and prevent count
  use_hierarchical = var.region == null
  use_regional     = !local.use_hierarchical && var.region != "global"
}
