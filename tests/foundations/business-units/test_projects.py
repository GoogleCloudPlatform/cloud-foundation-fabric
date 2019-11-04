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
  names = ('shared', 'terraform', 'audit')
  prefix = plan.variables['prefix']
  billing_account = plan.variables['billing_account_id']
  project_names = ['%s-%s' % (prefix, name) for name in names]
  for mod in project_modules.values():
    resource = mod.resources['google_project.project']
    assert resource['values']['billing_account'] == billing_account
    assert resource['values']['name'] in project_names


def test_project_services(plan, project_modules):
  "Project service resource must enable APIs specified in the variable."
  num_services = len(plan.variables['project_services'])
  for mod in project_modules.values():
    project_services = [r for r in mod.resources if r.startswith(
        'google_project_service.project_services')]
    assert len(project_services) >= num_services
