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


def test_iam(plan_runner):
  "Test IAM bindings."
  iam = (
      '{"roles/owner" = ["user:one@example.org"],'
      '"roles/viewer" = ["user:two@example.org", "user:three@example.org"]}'
  )
  _, resources = plan_runner(FIXTURES_DIR, iam=iam)
  roles = dict((r['values']['role'], r['values']['members'])
               for r in resources if r['type'] == 'google_project_iam_binding')
  assert roles == {
      'roles/owner': ['user:one@example.org'],
      'roles/viewer': ['user:three@example.org', 'user:two@example.org']}


def test_iam_additive(plan_runner):
  "Test IAM additive bindings."
  iam = (
      '{"roles/owner" = ["user:one@example.org"],'
      '"roles/viewer" = ["user:two@example.org", "user:three@example.org"]}'
  )
  _, resources = plan_runner(FIXTURES_DIR, iam_additive=iam)
  roles = set((r['values']['role'], r['values']['member'])
              for r in resources if r['type'] == 'google_project_iam_member')
  assert roles == set([
      ('roles/owner', 'user:one@example.org'),
      ('roles/viewer', 'user:three@example.org'),
      ('roles/viewer', 'user:two@example.org')
  ])


def test_iam_additive_members(plan_runner):
  "Test IAM additive members."
  iam = (
      '{"user:one@example.org" = ["roles/owner"],'
      '"user:two@example.org" = ["roles/owner", "roles/editor"]}'
  )
  _, resources = plan_runner(FIXTURES_DIR, iam_additive_members=iam)
  roles = set((r['values']['role'], r['values']['member'])
              for r in resources if r['type'] == 'google_project_iam_member')
  assert roles == set([
      ('roles/owner', 'user:one@example.org'),
      ('roles/owner', 'user:two@example.org'),
      ('roles/editor', 'user:two@example.org')
  ])
