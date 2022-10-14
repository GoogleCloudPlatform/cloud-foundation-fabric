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


def test_single_range(plan_runner):
  "Test single PSA range."
  psa_config = '''{
    ranges = {
      bar = "172.16.100.0/24"
      foo = "172.16.101.0/24"
    },
    routes = null
  }'''
  _, resources = plan_runner(psa_config=psa_config)
  assert len(resources) == 5
  for r in resources:
    if r['type'] == 'google_compute_network_peering_routes_config':
      assert not r['values']['export_custom_routes']
      assert not r['values']['import_custom_routes']


def test_routes_export(plan_runner):
  "Test routes export."
  psa_config = '''{
    ranges = {
      bar = "172.16.100.0/24"
    }
    export_routes = true
    import_routes = false
  }'''
  _, resources = plan_runner(psa_config=psa_config)
  assert len(resources) == 4
  for r in resources:
    if r['type'] == 'google_compute_network_peering_routes_config':
      assert r['values']['export_custom_routes']
      assert not r['values']['import_custom_routes']


def test_routes_import(plan_runner):
  "Test routes import."
  psa_config = '''{
    ranges = {
      bar = "172.16.100.0/24"
    },
    export_routes = false
    import_routes = true
  }'''
  _, resources = plan_runner(psa_config=psa_config)
  for r in resources:
    if r['type'] == 'google_compute_network_peering_routes_config':
      assert not r['values']['export_custom_routes']
      assert r['values']['import_custom_routes']


def test_routes_export_import(plan_runner):
  "Test routes export and import."
  psa_config = '''{
    ranges = {
      bar = "172.16.100.0/24"
    },
    export_routes = true
    import_routes = true
  }'''
  _, resources = plan_runner(psa_config=psa_config)
  for r in resources:
    if r['type'] == 'google_compute_network_peering_routes_config':
      assert r['values']['export_custom_routes']
      assert r['values']['import_custom_routes']
