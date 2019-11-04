# Copyright 2019 Google LLC
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

"Test cloud routers resources creation in root module."


def test_hub_custom_routers(plan):
  "Custom routers should match input variables."
  hub_custom_router_tpl = ('google_compute_router.hub-to-spoke-%s-custom[0]')
  for i in range(1, 3):
    name = hub_custom_router_tpl % i
    custom_router = plan.resource_changes[name]
    adv_ranges = custom_router['change']['after']['bgp'][0]['advertised_ip_ranges']
    spoke_subnets = plan.variables['spoke_%s_subnets' % (3 - i)]
    assert custom_router['change']['after']['bgp'][0]['advertise_mode'] == 'CUSTOM'
    assert custom_router['change']['after']['bgp'][0]['advertised_groups'] == ['ALL_SUBNETS']
    assert custom_router['change']['after']['bgp'][0]['asn'] == plan.variables['hub_bgp_asn']
    assert [range['range'] for range in adv_ranges] == [subnet['subnet_ip']
                                                            for subnet in spoke_subnets]

def test_spoke_routers(plan):
  "Spoke routers should match input variables."
  spoke_router_tpl = ('google_compute_router.spoke-%s')
  spoke_bgp_asn_tpl = ('spoke_%s_bgp_asn')
  for i in range(1, 3):
    spoke_router = plan.resource_changes[spoke_router_tpl % i]
    spoke_bgp_asn = plan.variables[spoke_bgp_asn_tpl % i]
    assert spoke_router['change']['after']['bgp'][0]['advertise_mode'] == 'DEFAULT'
    assert spoke_router['change']['after']['bgp'][0]['advertised_groups'] == None
    assert spoke_router['change']['after']['bgp'][0]['asn'] == spoke_bgp_asn
