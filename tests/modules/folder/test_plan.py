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


def test_folder(plan_runner):
  "Test folder resources."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  resource = resources[0]
  assert resource['type'] == 'google_folder'
  assert resource['values']['display_name'] == 'folder-a'
  assert resource['values']['parent'] == 'organizations/12345678'


def test_iam(plan_runner):
  "Test folder resources with iam roles and members."
  iam = '{"roles/owner" = ["user:a@b.com"] }'
  _, resources = plan_runner(FIXTURES_DIR, iam=iam)
  assert len(resources) == 2


def test_iam_multiple_members(plan_runner):
  "Test folder resources with multiple iam members."
  iam = '{"roles/owner" = ["user:a@b.com", "user:c@d.com"] }'
  _, resources = plan_runner(FIXTURES_DIR, iam=iam)
  assert len(resources) == 2


def test_iam_multiple_roles(plan_runner):
  "Test folder resources with multiple iam roles."
  iam = (
      '{ '
      '"roles/owner" = ["user:a@b.com"], '
      '"roles/viewer" = ["user:c@d.com"] '
      '} '
  )
  _, resources = plan_runner(FIXTURES_DIR, iam=iam)
  assert len(resources) == 3
