# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"Test project creation in root module."


import pytest


@pytest.fixture(scope='module')
def project_modules(plan):
  names = ['module.project-%s' %
           name for name in ('audit', 'shared-resources', 'tf')]
  return dict((name, plan.modules[name]) for name in names)


def test_project_resource(plan, project_modules):
  "Project resource attributes must match variables."
  root_node = plan.variables['root_node'].split('/')[1]
  billing_account = plan.variables['billing_account_id']
  for name, mod in project_modules.items():
    resource = mod['%s.google_project.project' % name]
    assert resource['values']['folder_id'] == root_node
    assert resource['values']['billing_account'] == billing_account


def test_project_services(plan, project_modules):
  "Project service resource must enable APIs specified in the variable."
  services = plan.variables['project_services']
  for name, mod in project_modules.items():
    resource = mod['%s.google_project_services.services[0]' % name]
    assert resource['values']['services'] == services
