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
  instance_shared_config = merge(
    var.instance_shared_config,
    { service_account = module.f5-sa.email }
  )
}

module "f5-sa" {
  source     = "../../../../modules/iam-service-account"
  project_id = local.project_id
  name       = "${var.prefix}-f5-sa"
}

module "f5-lb" {
  source                     = "../f5-bigip-ha-active"
  forwarding_rules_config    = var.forwarding_rules_config
  instance_dedicated_configs = var.instance_dedicated_configs
  instance_shared_config     = local.instance_shared_config
  prefix                     = var.prefix
  project_id                 = local.project_id
  region                     = var.region
  vpc_config = {
    dataplane = {
      network    = module.vpc-dataplane.self_link
      subnetwork = module.vpc-dataplane.subnet_self_links["${var.region}/${var.prefix}-dataplane"]
    }
    management = {
      network    = module.vpc-management.self_link
      subnetwork = module.vpc-management.subnet_self_links["${var.region}/${var.prefix}-management"]
    }
  }
}
