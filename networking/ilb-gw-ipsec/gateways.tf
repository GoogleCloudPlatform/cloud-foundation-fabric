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

locals {
  addresses = {
    for k, v in module.addresses.internal_addresses : k => v.address
  }
  subnets = merge(
    module.vpc-hub.subnet_self_links,
    module.vpc-landing.subnet_self_links,
    module.vpc-onprem.subnet_self_links
  )
}

module "addresses" {
  source     = "../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    hub-gw-1 = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/hub-default"]
    }
    hub-gw-2 = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/hub-default"]
    }
    hub-vip = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/hub-vip"]
    }
    landing-gw-1 = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/landing-default"]
    }
    landing-gw-2 = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/landing-default"]
    }
    landing-gw-onprem = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/onprem-default"]
    }
    onprem-gw-onprem = {
      region     = var.region
      subnetwork = local.subnets["${var.region}/onprem-default"]
    }
  }
}
