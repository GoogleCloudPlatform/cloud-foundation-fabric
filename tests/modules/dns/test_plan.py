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


def test_private(plan_runner):
  "Test private zone with three recordsets."
  _, resources = plan_runner()
  assert len(resources) == 7
  assert set(r['type'] for r in resources) == {
      'google_dns_record_set', 'google_dns_managed_zone'
  }
  for r in resources:
    if r['type'] != 'google_dns_managed_zone':
      continue
    assert r['values']['visibility'] == 'private'
    assert len(r['values']['private_visibility_config']) == 1


def test_private_recordsets(plan_runner):
  "Test recordsets in private zone."
  _, resources = plan_runner()
  recordsets = [
      r['values'] for r in resources if r['type'] == 'google_dns_record_set'
  ]

  assert set(r['name'] for r in recordsets) == {
      'localhost.test.example.', 'local-host.test.example.', '*.test.example.',
      "test.example.", "geo.test.example.", "wrr.test.example."
  }

  for r in recordsets:
    if r['name'] not in ['wrr.test.example.', 'geo.test.example.']:
      assert r['routing_policy'] == []
      assert r['rrdatas'] != []


def test_routing_policies(plan_runner):
  "Test recordsets with routing policies."
  _, resources = plan_runner()
  recordsets = [
      r['values'] for r in resources if r['type'] == 'google_dns_record_set'
  ]
  geo_zone = [
      r['values'] for r in resources if r['address'] ==
      'module.test.google_dns_record_set.cloud-geo-records["A geo"]'
  ][0]
  assert geo_zone['name'] == 'geo.test.example.'
  assert geo_zone['routing_policy'][0]['wrr'] == []
  geo_policy = geo_zone['routing_policy'][0]['geo']
  assert geo_policy[0]['location'] == 'europe-west1'
  assert geo_policy[0]['rrdatas'] == ['127.0.0.4']
  assert geo_policy[1]['location'] == 'europe-west2'
  assert geo_policy[1]['rrdatas'] == ['127.0.0.5']
  assert geo_policy[2]['location'] == 'europe-west3'
  assert geo_policy[2]['rrdatas'] == ['127.0.0.6']

  wrr_zone = [
      r['values'] for r in resources if r['address'] ==
      'module.test.google_dns_record_set.cloud-wrr-records["A wrr"]'
  ][0]
  assert wrr_zone['name'] == 'wrr.test.example.'
  wrr_policy = wrr_zone['routing_policy'][0]['wrr']
  assert wrr_policy[0]['weight'] == 0.6
  assert wrr_policy[0]['rrdatas'] == ['127.0.0.7']
  assert wrr_policy[1]['weight'] == 0.2
  assert wrr_policy[1]['rrdatas'] == ['127.0.0.8']
  assert wrr_policy[2]['weight'] == 0.2
  assert wrr_policy[2]['rrdatas'] == ['127.0.0.9']
  assert wrr_zone['routing_policy'][0]['geo'] == []


def test_private_no_networks(plan_runner):
  "Test private zone not exposed to any network."
  _, resources = plan_runner(client_networks='[]')
  for r in resources:
    if r['type'] != 'google_dns_managed_zone':
      continue
    assert r['values']['visibility'] == 'private'
    assert len(r['values']['private_visibility_config']) == 0


def test_forwarding_recordsets_null_forwarders(plan_runner):
  "Test forwarding zone with wrong set of attributes does not break."
  _, resources = plan_runner(type='forwarding')
  assert len(resources) == 1
  resource = resources[0]
  assert resource['type'] == 'google_dns_managed_zone'
  assert resource['values']['forwarding_config'] == []


def test_forwarding(plan_runner):
  "Test forwarding zone with single forwarder."
  _, resources = plan_runner(type='forwarding', recordsets='null',
                             forwarders='{ "1.2.3.4" = null }')
  assert len(resources) == 1
  resource = resources[0]
  assert resource['type'] == 'google_dns_managed_zone'
  assert resource['values']['forwarding_config'] == [{
      'target_name_servers': [{
          'forwarding_path': '',
          'ipv4_address': '1.2.3.4'
      }]
  }]


def test_peering(plan_runner):
  "Test peering zone."
  _, resources = plan_runner(type='peering', recordsets='null',
                             peer_network='dummy-vpc-self-link')
  assert len(resources) == 1
  resource = resources[0]
  assert resource['type'] == 'google_dns_managed_zone'
  assert resource['values']['peering_config'] == [{
      'target_network': [{
          'network_url': 'dummy-vpc-self-link'
      }]
  }]


def test_public(plan_runner):
  "Test public zone with two recordsets."
  _, resources = plan_runner(type='public')
  for r in resources:
    if r['type'] != 'google_dns_managed_zone':
      continue
    assert r['values']['visibility'] == 'public'
    assert r['values']['private_visibility_config'] == []
