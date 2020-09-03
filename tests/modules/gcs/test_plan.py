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


def test_buckets(plan_runner):
  "Test bucket resources."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 2
  assert set(r['type'] for r in resources) == set(['google_storage_bucket'])
  assert set(r['values']['name'] for r in resources) == set([
      'bucket-a', 'bucket-b'
  ])
  assert set(r['values']['project'] for r in resources) == set([
      'my-project'
  ])


def test_prefix(plan_runner):
  "Test bucket name when prefix is set."
  _, resources = plan_runner(FIXTURES_DIR, prefix='foo')
  assert set(r['values']['name'] for r in resources) == set([
      'foo-eu-bucket-a', 'foo-eu-bucket-b'
  ])


def test_map_values(plan_runner):
  "Test that map values set the correct attributes on buckets."
  _, resources = plan_runner(FIXTURES_DIR)
  bpo = dict((r['values']['name'], r['values']['bucket_policy_only'])
             for r in resources)
  assert bpo == {'bucket-a': False, 'bucket-b': True}
  force_destroy = dict((r['values']['name'], r['values']['force_destroy'])
                       for r in resources)
  assert force_destroy == {'bucket-a': True, 'bucket-b': False}
  versioning = dict((r['values']['name'], r['values']['versioning'])
                    for r in resources)
  assert versioning == {
      'bucket-a': [{'enabled': True}], 'bucket-b': [{'enabled': False}]
  }
  logging_config = dict((r['values']['name'], r['values']['logging'])
                        for r in resources)
  assert logging_config == {
      'bucket-a': [{'log_bucket': 'foo'}],
      'bucket-b': []
  }
  retention_policies = dict((r['values']['name'], r['values']['retention_policy'])
                            for r in resources)
  assert retention_policies == {
      'bucket-a': [],
      'bucket-b': [{'is_locked': False, 'retention_period': 5}]
  }
  for r in resources:
    assert r['values']['labels'] == {
        'environment': 'test', 'location': 'eu',
        'storage_class': 'multi_regional', 'name': r['values']['name']
    }


def test_iam_roles_only(plan_runner):
  "Test bucket resources with only iam roles passed."
  _, resources = plan_runner(
      FIXTURES_DIR, iam_roles='{bucket-a = [ "roles/storage.admin"]}')
  assert len(resources) == 3


def test_iam(plan_runner):
  "Test bucket resources with iam roles and members."
  iam_roles = (
      '{bucket-a = ["roles/storage.admin"], '
      'bucket-b = ["roles/storage.objectAdmin"]}'
  )
  iam_members = '{folder-a = { "roles/storage.admin" = ["user:a@b.com"] }}'
  _, resources = plan_runner(
      FIXTURES_DIR, iam_roles=iam_roles, iam_members=iam_members)
  assert len(resources) == 4
