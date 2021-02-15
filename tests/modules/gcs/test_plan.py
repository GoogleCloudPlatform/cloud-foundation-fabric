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

def test_buckets(plan_runner):
  "Test bucket resources."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  r = resources[0]
  assert r['type'] == 'google_storage_bucket'
  assert r['values']['name'] == 'bucket-a'
  assert r['values']['project'] == 'my-project'

def test_prefix(plan_runner):
  "Test bucket name when prefix is set."
  _, resources = plan_runner(FIXTURES_DIR, prefix='foo')
  assert resources[0]['values']['name'] == 'foo-eu-bucket-a'


def test_config_values(plan_runner):
  "Test that variables set the correct attributes on buckets."
  variables = dict(
    uniform_bucket_level_access='true',
    force_destroy='true',
    versioning='true'
  )
  _, resources = plan_runner(FIXTURES_DIR, **variables)
  assert len(resources) == 1
  r = resources[0]
  assert r['values']['uniform_bucket_level_access'] is True
  assert r['values']['force_destroy'] is True
  assert r['values']['versioning'] == [{'enabled': True}]
  assert r['values']['logging'] == [{'log_bucket': 'foo'}]
  assert r['values']['retention_policy'] == [
    {'is_locked': False, 'retention_period': 5}
  ]


def test_iam(plan_runner):
  "Test bucket resources with iam roles and members."
  iam = '{ "roles/storage.admin" = ["user:a@b.com"] }'
  _, resources = plan_runner(FIXTURES_DIR, iam=iam)
  assert len(resources) == 2
