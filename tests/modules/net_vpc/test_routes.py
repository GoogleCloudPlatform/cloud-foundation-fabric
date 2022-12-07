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

import pytest

_route_parameters = [('gateway', 'global/gateways/default-internet-gateway'),
                     ('instance', 'zones/europe-west1-b/test'),
                     ('ip', '192.168.0.128'),
                     ('ilb', 'regions/europe-west1/forwardingRules/test'),
                     ('vpn_tunnel', 'regions/europe-west1/vpnTunnels/foo')]


@pytest.mark.parametrize('next_hop_type,next_hop', _route_parameters)
def test_vpc_routes(plan_summary, next_hop_type, next_hop):
  'Test vpc routes.'

  var_routes = '''{
    next-hop = {
      dest_range    = "192.168.128.0/24"
      tags          = null
      next_hop_type = "%s"
      next_hop      = "%s"
    }
    gateway = {
      dest_range    = "0.0.0.0/0",
      priority      = 100
      tags          = ["tag-a"]
      next_hop_type = "gateway",
      next_hop      = "global/gateways/default-internet-gateway"
    }
  }''' % (next_hop_type, next_hop)
  summary = plan_summary('modules/net-vpc', tf_var_files=['common.tfvars'],
                         routes=var_routes)
  assert len(summary.values) == 3
  route = summary.values[f'google_compute_route.{next_hop_type}["next-hop"]']
  assert route[f'next_hop_{next_hop_type}'] == next_hop
