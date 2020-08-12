/**
 * Copyright 2020 Google LLC
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

module "vpc-landing" {
  source     = "../../modules/net-vpc"
  project_id = var.project_id
  name       = "${local.prefix}landing"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.landing
      name               = "${local.prefix}landing"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "firewall-landing" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = var.project_id
  network              = module.vpc-landing.name
  admin_ranges_enabled = true
  admin_ranges         = [var.ip_ranges.landing]
}
