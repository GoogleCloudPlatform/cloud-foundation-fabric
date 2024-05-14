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
  dns_names = [for v1 in flatten([for k2, v2 in var.apigee_config.endpoint_attachments :
    [for v3 in coalesce(v2.dns_names, []) : {
      endpoint_attachment = k2
      dns_name            = split(".", v3)
      }
    if v3 != null]]) : {
    endpoint_attachment = v1.endpoint_attachment
    domain              = length(v1.dns_name) == 1 ? "." : "${join(".", slice(v1.dns_name, 1, length(v1.dns_name)))}."
    name                = length(v1.dns_name) == 1 ? "*." : v1.dns_name[0]
  }]
  peered_domains = distinct([for v in local.dns_names : v.domain])
  private_dns_zones = { for k1, v1 in { for v2 in local.peered_domains :
    v2 => distinct([for v3 in local.dns_names : v3.name if v3.domain == v2]) } : k1 =>
    { for v4 in v1 : "A ${v4}" => {
      geo_routing = [for v5 in local.dns_names :
        {
          location = var.apigee_config.endpoint_attachments[v5.endpoint_attachment].region
          records  = [module.apigee.endpoint_attachment_hosts[v5.endpoint_attachment]]
        }
      if v5.domain == k1 && v5.name == v4] }
    }
  }
}

module "private_dns_zones" {
  for_each = (var.network_config.apigee_vpc == null || var.apigee_config.organization.disable_vpc_peering
    ? {} :
  local.private_dns_zones)
  source     = "../../../modules/dns"
  project_id = module.project.project_id
  name       = trimsuffix(replace(each.key, ".", "-"), "-")
  zone_config = {
    domain = each.key
    private = {
      client_networks = [module.apigee_vpc[0].self_link]
    }
  }
  recordsets = each.value
}
