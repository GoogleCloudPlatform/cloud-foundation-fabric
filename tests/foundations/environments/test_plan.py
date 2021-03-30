# Copyright 2021 Google LLC
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


import os
import pytest


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_folder_roles(e2e_plan_runner):
  "Test folder roles."
  modules, _ = e2e_plan_runner(FIXTURES_DIR, refresh=False)
  for env in ['test', 'prod']:
    resources = modules[f'module.test.module.environment-folders["{env}"]']
    folders = [r for r in resources if r['type'] == 'google_folder']
    assert len(folders) == 1
    folder = folders[0]
    assert folder['values']['display_name'] == env

    bindings = [r['index']
                for r in resources if r['type'] == 'google_folder_iam_binding']
    assert len(bindings) == 5


def test_org_roles(e2e_plan_runner):
  "Test folder roles."
  tf_vars = {
      'organization_id': 'organizations/123',
      'iam_xpn_config': '{grant = true, target_org = true}'
  }
  modules, _ = e2e_plan_runner(FIXTURES_DIR, refresh=False, **tf_vars)
  for env in ['test', 'prod']:
    resources = modules[f'module.test.module.environment-folders["{env}"]']
    folder_bindings = [r['index']
                       for r in resources if r['type'] == 'google_folder_iam_binding']
    assert len(folder_bindings) == 4

    resources = modules[f'module.test.module.tf-service-accounts["{env}"]']
    org_bindings = [r for r in resources
                    if r['type'] == 'google_organization_iam_member']
    assert len(org_bindings) == 2
    assert {b['values']['role'] for b in org_bindings} == {
        'roles/resourcemanager.organizationViewer',
        'roles/compute.xpnAdmin'
    }
