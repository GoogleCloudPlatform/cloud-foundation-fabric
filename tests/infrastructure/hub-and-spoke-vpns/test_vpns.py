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

"Test firewall resources creation in root module."


import pytest


@pytest.fixture(scope='module')
def spoke_to_hub_vpn(plan):
  count = range(1,3)
  names = ['module.vpn-spoke-%s-to-hub' % i for i in count]
  return dict((name, plan.modules[name]) for name in names)


@pytest.fixture(scope='module')
def hub_to_spoke_vpn(plan):
  count = range(1,3)
  var_names = ['spoke_%s_bgp_asn' % i for i in count]
  names = ['module.vpn-hub-to-spoke-%s' % i for i in count]
  return var_names, [plan.modules[name] for name in names]


def test_spokes_peer_asn(plan, spoke_to_hub_vpn):
  "Test that the spoke-to-hub VPNs mach input variables"
  hub_bgp_asn = plan.variables['hub_bgp_asn']
  for mod in spoke_to_hub_vpn.values():
    spoke_bgp_peer = mod.resources['google_compute_router_peer.bgp_peer[0]']
    assert spoke_bgp_peer['values']['peer_asn'] == hub_bgp_asn


def test_hub_peer_asns(plan, hub_to_spoke_vpn):
  "Test that the hub-to-spoke VPNs mach input variables"
  count = range(1,3)
  var_names, mods = hub_to_spoke_vpn
  for var_name, mod in zip(var_names, mods):
    hub_bgp_peer = mod.resources['google_compute_router_peer.bgp_peer[0]']
    spoke_bgp_asn = plan.variables[var_name]
    assert hub_bgp_peer['values']['peer_asn'] == spoke_bgp_asn
