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


def test_external_addresses(plan_runner):
  addresses = '{one = "europe-west1", two = "europe-west2"}'
  _, resources = plan_runner(external_addresses=addresses)
  assert [r['values']['name'] for r in resources] == ['one', 'two']
  assert set(r['values']['address_type'] for r in resources) == set(
      ['EXTERNAL'])
  assert [r['values']['region'] for r in resources
         ] == ['europe-west1', 'europe-west2']


def test_global_addresses(plan_runner):
  _, resources = plan_runner(global_addresses='["one", "two"]')
  assert [r['values']['name'] for r in resources] == ['one', 'two']
  assert set(r['values']['address_type'] for r in resources) == set([None])


def test_internal_addresses(plan_runner):
  addresses = ('{one = {region = "europe-west1", subnetwork = "foobar"}, '
               'two = {region = "europe-west2", subnetwork = "foobarz"}}')
  _, resources = plan_runner(internal_addresses=addresses)
  assert [r['values']['name'] for r in resources] == ['one', 'two']
  assert set(r['values']['address_type'] for r in resources) == set(
      ['INTERNAL'])
  assert [r['values']['region'] for r in resources
         ] == ['europe-west1', 'europe-west2']


def test_internal_addresses_config(plan_runner):
  addresses = '''{
    one = {
      region = "europe-west1"
      subnetwork = "foobar"
      address = "10.0.0.2"
      purpose = "SHARED_LOADBALANCER_VIP"
    },
    two = {region = "europe-west2", subnetwork = "foobarz"}
  }'''
  _, resources = plan_runner(internal_addresses=addresses)
  assert [r['values']['name'] for r in resources] == ['one', 'two']
  assert set(r['values']['address_type'] for r in resources) == set(
      ['INTERNAL'])
  assert [r['values'].get('address') for r in resources] == ['10.0.0.2', None]
  assert [r['values'].get('purpose') for r in resources
         ] == ['SHARED_LOADBALANCER_VIP', None]


def test_psa_config(plan_runner):
  psa_addresses = '{cloudsql-mysql={address="10.199.0.0", network="foobar", prefix_length = 24}}'
  _, resources = plan_runner(psa_addresses=psa_addresses)
  assert set(r['values']['purpose'] for r in resources) == set(['VPC_PEERING'])
  assert set(r['values']['address'] for r in resources) == set(['10.199.0.0'])
