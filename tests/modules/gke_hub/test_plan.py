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


@pytest.fixture
def resources(plan_runner):
  _, resources = plan_runner()
  return resources


def test_resource_count(resources):
  "Test number of resources created."
  assert len(resources) == 8
  assert sorted(r['address'] for r in resources) == [
      'module.hub.google_gke_hub_feature.default["configmanagement"]',
      'module.hub.google_gke_hub_feature.default["servicemesh"]',
      'module.hub.google_gke_hub_feature_membership.default["cluster-1"]',
      'module.hub.google_gke_hub_feature_membership.default["cluster-2"]',
      'module.hub.google_gke_hub_feature_membership.servicemesh["cluster-1"]',
      'module.hub.google_gke_hub_feature_membership.servicemesh["cluster-2"]',
      'module.hub.google_gke_hub_membership.default["cluster-1"]',
      'module.hub.google_gke_hub_membership.default["cluster-2"]'
  ]


def test_configmanagement_setup(resources):
  "Test configuration of configmanagement."
  resources = {r['address']: r['values'] for r in resources}

  expected_configmanagement = [{
      'binauthz': [],
      'config_sync': [{
          'git': [{
              'gcp_service_account_email':
                  None,
              'https_proxy':
                  None,
              'policy_dir':
                  'configsync',
              'secret_type':
                  'ssh',
              'sync_branch':
                  'main',
              'sync_repo':
                  'https://github.com/danielmarzini/configsync-platform-example',
              'sync_rev':
                  None,
              'sync_wait_secs':
                  None
          }],
          'oci': [],
          'prevent_drift': False,
          'source_format': 'hierarchy'
      }],
      'hierarchy_controller': [],
      'policy_controller': [],
      'version': '1.10.2'
  }]

  for cluster in ['cluster-1', 'cluster-2']:
    membership_key = f'module.hub.google_gke_hub_membership.default["{cluster}"]'
    membership = resources[membership_key]
    link = membership['endpoint'][0]['gke_cluster'][0]['resource_link']
    assert link == f'//container.googleapis.com/projects/myproject/locations/europe-west1-b/clusters/{cluster}'

    fm_key = f'module.hub.google_gke_hub_feature_membership.default["{cluster}"]'
    fm = resources[fm_key]
    print(fm['configmanagement'])
    assert fm['configmanagement'] == expected_configmanagement
