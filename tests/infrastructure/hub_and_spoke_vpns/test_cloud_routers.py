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
  "Hub to spoke routers should match input variables."
  for i in (1, 2):
    router = plan.resources['google_compute_router.hub-to-spoke-%s-custom[0]' % i]
    bgp = router['values']['bgp'][0]
    assert bgp['advertise_mode'] == 'CUSTOM'
    assert bgp['advertised_groups'] == ['ALL_SUBNETS']
    assert bgp['asn'] == plan.variables['hub_bgp_asn']
    subnet_ranges = [s['subnet_ip']
                     for s in plan.variables['spoke_%s_subnets' % (3 - i)]]
    assert [r['range'] for r in bgp['advertised_ip_ranges']] == subnet_ranges


def test_spoke_routers(plan):
  "Spoke routers should match input variables."
  for i in (1, 2):
    router = plan.resources['google_compute_router.spoke-%s' % i]
    bgp = router['values']['bgp'][0]
    assert bgp['advertise_mode'] == 'DEFAULT'
    assert bgp['advertised_groups'] == None
    assert bgp['asn'] == plan.variables['spoke_%s_bgp_asn' % i]
