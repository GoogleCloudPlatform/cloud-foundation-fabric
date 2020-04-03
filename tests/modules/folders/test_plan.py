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


def test_folder(plan_runner):
  "Test folder resources."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 2
  assert set(r['type'] for r in resources) == set(['google_folder'])
  assert set(r['values']['display_name'] for r in resources) == set([
      'folder-a', 'folder-b'
  ])
  assert set(r['values']['parent'] for r in resources) == set([
      'organizations/12345678'
  ])


def test_iam_roles_only(plan_runner):
  "Test folder resources with only iam roles passed."
  _, resources = plan_runner(
      FIXTURES_DIR, iam_roles='{folder-a = [ "roles/owner"]}')
  assert len(resources) == 3


def test_iam(plan_runner):
  "Test folder resources with iam roles and members."
  iam_roles = '{folder-a = ["roles/owner"], folder-b = ["roles/viewer"]}'
  iam_members = '{folder-a = { "roles/owner" = ["user:a@b.com"] }}'
  _, resources = plan_runner(
      FIXTURES_DIR, iam_roles=iam_roles, iam_members=iam_members)
  assert len(resources) == 4
