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


def test_single_instance(plan_runner):
  plan, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  assert resources[0]['type'] == 'google_compute_instance'


def test_multiple_instances(plan_runner):
  plan, resources = plan_runner(FIXTURES_DIR, instance_count=2)
  assert len(resources) == 2
  assert set(r['type'] for r in resources) == set(['google_compute_instance'])


def test_service_account(plan_runner):
  plan, resources = plan_runner(FIXTURES_DIR, instance_count=2,
                                service_account_create='true')
  assert len(resources) == 3
  assert 'google_service_account' in [r['type'] for r in resources]


def test_template(plan_runner):
  plan, resources = plan_runner(FIXTURES_DIR, use_instance_template='true')
  assert len(resources) == 1
  assert resources[0]['type'] == 'google_compute_instance_template'
  assert resources[0]['values']['name_prefix'] == 'test-'
