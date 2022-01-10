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

from collections import Counter


def test_group(plan_runner):
  "Test group."
  _, resources = plan_runner()
  assert len(resources) == 1
  r = resources[0]
  assert r['type'] == 'google_cloud_identity_group'
  assert r['values']['display_name'] == 'display name'
  assert r['values']['group_key'][0]['id'] == 'my-group@example.com'
  assert r['values']['parent'] == 'customers/C01234567'


def test_members(plan_runner):
  "Test group members."
  members = '["member@example.com"]'
  _, resources = plan_runner(members=members)

  resource_types = Counter([r['type'] for r in resources])
  assert resource_types == {
      'google_cloud_identity_group': 1,
      'google_cloud_identity_group_membership': 1,
  }

  values = next(r['values'] for r in resources if r['name'] == 'members')
  assert values['preferred_member_key'][0]['id'] == 'member@example.com'
  assert [role['name'] for role in values['roles']] == ['MEMBER']
