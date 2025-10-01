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
  # Governed by local.defaults.billing_account - simplified billing config for network factory
  # factory_billing = local.defaults.billing_account
}

module "network_factory" {
  source = "../../../modules/net-vpc-factory"

  data_defaults = local.vpcs_defaults.defaults
  data_overrides = {}
  # Enhanced context with merged data from previous stages
  context = local.ctx

  factories_config = {
    vpcs              = var.factories_config.vpcs
    firewall_rules = {
      data = try(var.factories_config.firewall_rules.data, "data/firewall-rules")
    }
    psc_endpoints = {
      data = try(var.factories_config.psc_endpoints.data, "psc-endpoints")
    }
  }
}