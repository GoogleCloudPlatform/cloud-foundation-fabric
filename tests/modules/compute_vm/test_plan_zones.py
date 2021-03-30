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


def test_default(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR)
  assert resources[0]['values']['zone'] == 'europe-west1-b'


def test_multiple_default(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=2)
  assert set(r['values']['zone'] for r in resources) == set(['europe-west1-b'])


def test_custom(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, zones='["a", "b"]')
  assert resources[0]['values']['zone'] == 'a'


def test_custom_default(plan_runner):
  _, resources = plan_runner(
      FIXTURES_DIR, instance_count=3, zones='["a", "b"]')
  assert [r['values']['zone'] for r in resources] == ['a', 'b', 'a']


def test_group(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=2,
                             group='{named_ports={}}', zones='["a", "b"]')
  assert resources[2]['type'] == 'google_compute_instance_group'
  assert resources[2]['values']['zone'] == 'a'


def test_iam(plan_runner):
  iam = '{"roles/a" = ["user:a@a.com"], "roles/b" = ["user:a@a.com"]}'
  _, resources = plan_runner(FIXTURES_DIR, instance_count=3,
                             iam=iam, zones='["a", "b"]')
  iam_bindings = dict(
      (r['index'], r['values']['zone']) for r in resources if r['type']
      == 'google_compute_instance_iam_binding'
  )
  assert iam_bindings == {
      'roles/a/test-1': 'a',
      'roles/a/test-2': 'b',
      'roles/a/test-3': 'a',
      'roles/b/test-1': 'a',
      'roles/b/test-2': 'b',
      'roles/b/test-3': 'a',
  }
