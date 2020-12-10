# Copyright 2020 Google LLC
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

from collections import Counter


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_group(plan_runner):
  "Test group."
  _, resources = plan_runner(FIXTURES_DIR)
  import pprint
  pprint.pprint(resources)
  assert len(resources) == 1
  r = resources[0]
  assert r['type'] == 'google_cloud_identity_group'
  assert r['values']['display_name'] == 'display name'
  assert r['values']['group_key'][0]['id'] == 'my-group@example.com'
  assert r['values']['parent'] == 'customers/C01234567'


def test_members(plan_runner):
  "Test group owners."
  owners = '["owner@example.com"]'
  managers = '["manager@example.com"]'
  members = '["member@example.com"]'
  _, resources = plan_runner(FIXTURES_DIR, owners=owners, managers=managers,
                             members=members)

  resource_types = Counter([r['type'] for r in resources])
  assert resource_types == {
    'google_cloud_identity_group': 1,
    'google_cloud_identity_group_membership': 3,
  }

  # members
  values = next(r['values'] for r in resources if r['name'] == 'members')
  assert values['preferred_member_key'][0]['id'] == 'member@example.com'
  assert [role['name'] for role in values['roles']] == ['MEMBER']

  # managers
  values = next(r['values'] for r in resources if r['name'] == 'managers')
  assert values['preferred_member_key'][0]['id'] == 'manager@example.com'
  assert [role['name'] for role in values['roles']] == ['MEMBER', 'MANAGER']

  # owners
  values = next(r['values'] for r in resources if r['name'] == 'owners')
  assert values['preferred_member_key'][0]['id'] == 'owner@example.com'
  assert [role['name'] for role in values['roles']] == ['OWNER', 'MEMBER', 'MANAGER']
