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


def test_resources(plan_runner):
  "Test service account resource."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  resource = resources[0]
  assert resource['type'] == 'google_service_account'
  assert resource['values']['account_id'] == 'sa-one'

  _, resources = plan_runner(FIXTURES_DIR, prefix='foo')
  assert len(resources) == 1
  resource = resources[0]
  assert resource['values']['account_id'] == 'foo-sa-one'


def test_iam_roles(plan_runner):
  "Test iam roles with one member."
  iam=('{"roles/iam.serviceAccountUser" = ["user:a@b.com"]}')
  _, resources = plan_runner(FIXTURES_DIR, iam=iam)
  assert len(resources) == 2
  iam_resources = [r for r in resources
                   if r['type'] != 'google_service_account']
  assert len(iam_resources) == 1

  iam_resource = iam_resources[0]
  assert iam_resource['type']  == 'google_service_account_iam_binding'
  assert iam_resource['index']  == 'roles/iam.serviceAccountUser'
  assert iam_resource['values']['role']  == 'roles/iam.serviceAccountUser'
  assert iam_resource['values']['members']  == ["user:a@b.com"]
