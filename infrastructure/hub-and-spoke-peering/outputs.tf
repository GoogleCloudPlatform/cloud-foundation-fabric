# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "hub" {
  description = "Hub network resources."
  value = {
    network_name   = module.vpc-hub.name
    subnet_ips     = module.vpc-hub.subnet_ips
    subnet_regions = module.vpc-hub.subnet_regions
    privte_dns_zone = {
      name   = module.hub-private-zone.name
      domain = module.hub-private-zone.domain
    }
    forwarding_dns_zone = {
      name   = module.hub-forwarding-zone.name
      domain = module.hub-forwarding-zone.domain
    }
  }
}

output "spoke-1" {
  description = "Spoke1 network resources."
  value = {
    network_name   = module.vpc-spoke-1.name
    subnet_ips     = module.vpc-spoke-1.subnet_ips
    subnet_regions = module.vpc-spoke-1.subnet_regions
    peering_to_hub_private_dns_zone = {
      name   = module.spoke-1-peering-zone-to-hub-private-zone.name
      domain = module.spoke-1-peering-zone-to-hub-private-zone.domain
    }
    peering_to_hub_forwarding_dns_zone = {
      name   = module.spoke-1-peering-zone-to-hub-forwarding-zone.name
      domain = module.spoke-1-peering-zone-to-hub-forwarding-zone.domain
    }
  }
}

output "spoke-2" {
  description = "Spoke2 network resources."
  value = {
    network_name   = module.vpc-spoke-2.name
    subnet_ips     = module.vpc-spoke-2.subnet_ips
    subnet_regions = module.vpc-spoke-2.subnet_regions
    peering_to_hub_private_dns_zone = {
      name   = module.spoke-2-peering-zone-to-hub-private-zone.name
      domain = module.spoke-2-peering-zone-to-hub-private-zone.domain
    }
    peering_to_hub_forwarding_dns_zone = {
      name   = module.spoke-2-peering-zone-to-hub-forwarding-zone.name
      domain = module.spoke-2-peering-zone-to-hub-forwarding-zone.domain
    }
  }
}
