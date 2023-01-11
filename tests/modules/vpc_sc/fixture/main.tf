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

module "test" {
  source                     = "../../../../modules/vpc-sc"
  access_policy              = var.access_policy
  access_policy_create       = var.access_policy_create
  access_levels              = var.access_levels
  egress_policies            = var.egress_policies
  ingress_policies           = var.ingress_policies
  service_perimeters_bridge  = var.service_perimeters_bridge
  service_perimeters_regular = var.service_perimeters_regular
}
