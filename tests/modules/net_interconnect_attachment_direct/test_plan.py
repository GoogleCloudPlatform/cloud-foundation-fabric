# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

_VAR_BGP = (
    '{'
    'session_range="169.254.63.1/29", '
    'candidate_ip_ranges= ["169.254.63.0/29"], '
    'advertised_route_priority=0, '
    '}'
)
_VAR_CONFIG = (
    '{'
    'description="", '
    'vlan_id=603, '
    'bandwidth="BPS_10G", '
    'admin_enabled=true, '
    'mtu=1440, '
    '}'

)
_VAR_ROUTER_CONFIG = (
    '{'
    'description="", '
    'asn=65003, '
    'keepalive_interval=20, '
    'advertise_config= {'
    '   mode="CUSTOM", '
    '   groups=["ALL_SUBNETS"], '
    '   ip_ranges = {'
    '   "199.36.153.8/30" = "custom" }, '
    '  }, '
    '}'
)


def test_router_create_false(plan_runner):
  "Test with no router creation."
  _, resources = plan_runner(router_create='false')
  assert len(resources) == 3


def test_vlanattachment(plan_runner):
  "Test vlan attachment"
  _, resources = plan_runner(bgp=_VAR_BGP, config=_VAR_CONFIG)
  assert len(resources) == 4
  for r in resources:
    if r['type'] != 'google_compute_interconnect_attachment':
      continue
    assert r['values']['interconnect'].endswith(
        'interconnects/mylab-interconnect-1')
    assert r['values']['name'] == 'vlan-603'
    assert r['values']['vlan_tag8021q'] == 603
    assert r['values']['candidate_subnets'] == ['169.254.63.0/29']
    assert r['values']['bandwidth'] == 'BPS_10G'
    assert r['values']['mtu'] == '1440'
    assert r['values']['admin_enabled'] == True

  def test_router(plan_runner):
    "Test router"
  _, resources = plan_runner(router_config=_VAR_ROUTER_CONFIG)
  assert len(resources) == 4
  for r in resources:
    if r['type'] != 'google_compute_router':
      continue
    assert r['values']['name'] == 'router-vlan-attachment'
    assert r['values']['network'] == 'my-vpc'
    assert r['values']['bgp'] == [{
        'advertise_mode': 'CUSTOM',
        'advertised_groups': ['ALL_SUBNETS'],
        'advertised_ip_ranges': [{'description': 'custom', 'range': '199.36.153.8/30'}],
        'asn': 65003,
        'keepalive_interval': 20,
    }]

  def test_router_peer(plan_runner):
    "Test router peer"
  _, resources = plan_runner(bgp=_VAR_BGP)
  assert len(resources) == 4
  for r in resources:
    if r['type'] != 'google_compute_router_peer':
      continue
    assert r['values']['peer_ip_address'] == '169.254.63.2'
    assert r['values']['peer_asn'] == 65418
    assert r['values']['interface'] == 'vlan-603'

  def test_router_interface(plan_runner):
    "Test router interface"
  _, resources = plan_runner(bgp=_VAR_BGP)
  assert len(resources) == 4
  for r in resources:
    if r['type'] != 'google_compute_router_interface':
      continue
    assert r['values']['name'] == 'interface-vlan-603'
    assert r['values']['ip_range'] == '169.254.63.1/29'
    assert r['values']['interconnect_attachment'] == 'vlan-603'
