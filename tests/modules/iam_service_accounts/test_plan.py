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


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_resources(plan_runner):
  "Test service account resource."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 3
  assert set(r['type'] for r in resources) == set(['google_service_account'])
  assert set(r['values']['account_id'] for r in resources) == set([
      'sa-one', 'sa-two', 'sa-three'
  ])
  _, resources = plan_runner(FIXTURES_DIR, prefix='foo')
  assert set(r['values']['account_id'] for r in resources) == set([
      'foo-sa-one', 'foo-sa-two', 'foo-sa-three'
  ])


def test_iam_roles(plan_runner):
  "Test iam roles with no memmbers."
  _, resources = plan_runner(FIXTURES_DIR,
                             iam_roles='["roles/iam.serviceAccountUser"]')
  assert len(resources) == 6
  iam_resources = [r for r in resources if r['type']
                   != 'google_service_account']
  assert len(iam_resources) == 3
  assert set(r['type'] for r in iam_resources) == set(
      ['google_service_account_iam_binding'])
  assert [r['index'] for r in iam_resources] == [
      'sa-one-roles/iam.serviceAccountUser',
      'sa-three-roles/iam.serviceAccountUser',
      'sa-two-roles/iam.serviceAccountUser',
  ]
