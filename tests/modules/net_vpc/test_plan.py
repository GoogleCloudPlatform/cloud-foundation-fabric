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

import yaml


def test_simple(generic_plan_validator):
  generic_plan_validator(inventory_path='simple.yaml',
                         module_path="modules/net-vpc",
                         tf_var_files=['common.tfvars'])


def test_vpc_shared(generic_plan_validator):
  generic_plan_validator(inventory_path='shared_vpc.yaml',
                         module_path="modules/net-vpc",
                         tf_var_files=['common.tfvars', 'shared_vpc.tfvars'])


def test_vpc_peering(generic_plan_validator):
  generic_plan_validator(inventory_path='peering.yaml',
                         module_path="modules/net-vpc",
                         tf_var_files=['common.tfvars', 'peering.tfvars'])


def test_vpc_routes(plan_runner):
  "Test vpc routes."
  for next_hop_type, next_hop in _VAR_ROUTES_NEXT_HOPS.items():
    _var_routes = _VAR_ROUTES_TEMPLATE % (next_hop_type, next_hop)
    _, resources = plan_runner(routes=_var_routes)
    assert len(resources) == 3
    resource = [r for r in resources if r['values']['name'] == 'test-next-hop'
               ][0]
    assert resource['values']['next_hop_%s' % next_hop_type]
