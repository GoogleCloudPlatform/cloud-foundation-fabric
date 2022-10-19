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

_VAR_PEER_VPC_CONFIG = '''{
  peer_vpc_self_link="projects/my-project/global/networks/peer",
  export_routes=true, import_routes=null
}'''
_VAR_ROUTES_TEMPLATE = '''{
  next-hop = {
  dest_range="192.168.128.0/24", tags=null,
  next_hop_type="%s", next_hop="%s"},
  gateway = {
  dest_range="0.0.0.0/0", priority=100, tags=["tag-a"],
  next_hop_type="gateway",
  next_hop="global/gateways/default-internet-gateway"}
}'''
_VAR_ROUTES_NEXT_HOPS = {
    'gateway': 'global/gateways/default-internet-gateway',
    'instance': 'zones/europe-west1-b/test',
    'ip': '192.168.0.128',
    'ilb': 'regions/europe-west1/forwardingRules/test',
    'vpn_tunnel': 'regions/europe-west1/vpnTunnels/foo'
}


def test_vpc_simple(plan_runner):
  "Test vpc with no extra options."
  _, resources = plan_runner()
  assert len(resources) == 1
  assert [r['type'] for r in resources] == ['google_compute_network']
  assert [r['values']['name'] for r in resources] == ['test']
  assert [r['values']['project'] for r in resources] == ['test-project']


def test_vpc_shared(plan_runner):
  "Test shared vpc variables."
  _, resources = plan_runner(shared_vpc_host='true',
                             shared_vpc_service_projects='["tf-a", "tf-b"]')
  assert len(resources) == 4
  assert set(r['type'] for r in resources) == set([
      'google_compute_network', 'google_compute_shared_vpc_host_project',
      'google_compute_shared_vpc_service_project'
  ])


def test_vpc_peering(plan_runner):
  "Test vpc peering variables."
  _, resources = plan_runner(peering_config=_VAR_PEER_VPC_CONFIG)
  assert len(resources) == 3
  assert set(r['type'] for r in resources) == set(
      ['google_compute_network', 'google_compute_network_peering'])
  peerings = [
      r['values']
      for r in resources
      if r['type'] == 'google_compute_network_peering'
  ]
  assert [p['name'] for p in peerings] == ['test-peer', 'peer-test']
  assert [p['export_custom_routes'] for p in peerings] == [True, False]
  assert [p['import_custom_routes'] for p in peerings] == [False, True]


def test_vpc_routes(plan_runner):
  "Test vpc routes."
  for next_hop_type, next_hop in _VAR_ROUTES_NEXT_HOPS.items():
    _var_routes = _VAR_ROUTES_TEMPLATE % (next_hop_type, next_hop)
    _, resources = plan_runner(routes=_var_routes)
    assert len(resources) == 3
    resource = [r for r in resources if r['values']['name'] == 'test-next-hop'
               ][0]
    assert resource['values']['next_hop_%s' % next_hop_type]
