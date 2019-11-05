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

"Test VPN BGP ASNs in root module."


import pytest


def test_spokes_peer_asn(plan):
  "Test that the spoke-to-hub VPNs mach input variables"
  mods = [v for k, v in plan.modules.items() if k.startswith('module.vpn-spoke')]
  for mod in mods:
    bgp_peer = mod.resources['google_compute_router_peer.bgp_peer[0]']
    assert bgp_peer['values']['peer_asn'] == plan.variables['hub_bgp_asn']


def test_hub_peer_asns(plan):
  "Test that the hub-to-spoke VPNs mach input variables"
  mods = [v for k, v in plan.modules.items() if k.startswith('module.vpn-hub')]
  for mod in mods:
    bgp_peer = mod.resources['google_compute_router_peer.bgp_peer[0]']
    asn_varname = 'spoke_%s_bgp_asn' % mod['address'][-1]
    assert bgp_peer['values']['peer_asn'] == plan.variables[asn_varname]
