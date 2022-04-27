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
  assert len(resources) == 6
  assert sorted(r['address'] for r in resources) == [
      'module.hub.google_gke_hub_feature.configmanagement["1"]',
      # 'module.hub.google_gke_hub_feature.mci["mycluster1"]',
      # 'module.hub.google_gke_hub_feature.mci["mycluster2"]',
      'module.hub.google_gke_hub_feature.mcs["1"]',
      'module.hub.google_gke_hub_feature_membership.feature_member["mycluster1"]',
      'module.hub.google_gke_hub_feature_membership.feature_member["mycluster2"]',
      'module.hub.google_gke_hub_membership.membership["mycluster1"]',
      'module.hub.google_gke_hub_membership.membership["mycluster2"]'
  ]


def test_configmanagement_setup(resources):
  "Test configuration of configmanagement."
  resources = {r['address']: r['values'] for r in resources}

  expected_repo = 'https://github.com/danielmarzini/configsync-platform-example'
  expected_configmanagement = [{
      'binauthz': [{
          'enabled': True
      }],
      'config_sync': [{
          'git': [{
              'gcp_service_account_email': None,
              'https_proxy': None,
              'policy_dir': 'configsync',
              'secret_type': 'none',
              'sync_branch': 'main',
              'sync_repo': expected_repo,
              'sync_rev': None,
              'sync_wait_secs': None
          }],
          'source_format': 'hierarchy'
      }],
      'hierarchy_controller': [],
      'policy_controller': [{
          'audit_interval_seconds': None,
          'enabled': True,
          'exemptable_namespaces': [],
          'log_denies_enabled': True,
          'referential_rules_enabled': True,
          'template_library_installed': True
      }],
      'version': '1.10.2'
  }]

  for cluster in ['mycluster1', 'mycluster2']:
    membership_key = f'module.hub.google_gke_hub_membership.membership["{cluster}"]'
    membership = resources[membership_key]
    link = membership['endpoint'][0]['gke_cluster'][0]['resource_link']
    assert link == f'projects/myproject/locations/europe-west1-b/clusters/{cluster}'

    fm_key = f'module.hub.google_gke_hub_feature_membership.feature_member["{cluster}"]'
    fm = resources[fm_key]
    assert fm['configmanagement'] == expected_configmanagement
