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

from pathlib import Path

from deepdiff import DeepDiff

BASEDIR = Path(__file__).parent
FIXTURE_PEERING = BASEDIR / 'fixture'
FIXTURE_VPN = BASEDIR.parent / 's02_networking_vpn/fixture'


def test_counts(fast_e2e_plan_runner):
  'Test stage.'
  num_modules, num_resources, _ = fast_e2e_plan_runner()
  # TODO: to re-enable per-module resource count check print _, then test
  assert num_modules > 0 and num_resources > 0


def test_vpn_peering_parity(e2e_plan_runner):
  '''Ensure VPN- and peering-based networking stages are identical except
  for VPN and VPC peering resources'''
  _, plan_peering = e2e_plan_runner(fixture_path=FIXTURE_PEERING)
  _, plan_vpn = e2e_plan_runner(fixture_path=FIXTURE_VPN)
  ddiff = DeepDiff(plan_vpn, plan_peering, ignore_order=True,
                   group_by='address', view='tree')

  removed_types = {x.t1['type'] for x in ddiff['dictionary_item_removed']}
  added_types = {x.t2['type'] for x in ddiff['dictionary_item_added']}

  assert added_types == {'google_compute_network_peering'}
  assert removed_types == {
      'google_compute_ha_vpn_gateway', 'google_compute_router',
      'google_compute_router_interface', 'google_compute_router_peer',
      'google_compute_vpn_tunnel', 'random_id'
  }
