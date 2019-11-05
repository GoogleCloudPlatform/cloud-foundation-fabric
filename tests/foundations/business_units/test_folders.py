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

"Test shared and business-units folders"


import pytest


def test_shared_folder(plan):
  "Shared folder resource attributes must match variables."
  root_node = plan.variables['root_node']
  resource = plan.modules['module.shared-folder'].resources['google_folder.folders[0]']
  assert resource['values']['parent'] == root_node
  assert resource['values']['display_name'] == 'shared'


def test_business_unit_folders(plan):
  "Business Unit folder resource attributes must match variables."
  address_tpl = (
      'module.business-unit-%s-folders.module.business-unit-folder'
      '.google_folder.folders[0]'
  )
  count = range(1, 4)
  business_unit_names = [
      plan.variables['business_unit_%s_name' % i] for i in count]
  root_node = plan.variables['root_node']
  for address in [address_tpl % i for i in count]:
    resource = plan.resource_changes[address]
    assert resource['change']['after']['parent'] == root_node
    assert resource['change']['after']['display_name'] in business_unit_names
