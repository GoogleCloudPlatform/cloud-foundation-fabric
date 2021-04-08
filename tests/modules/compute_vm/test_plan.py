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


def test_single_instance(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  assert resources[0]['type'] == 'google_compute_instance'


def test_single_instance_single_name(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, single_name=1)
  assert len(resources) == 1
  assert resources[0]['type'] == 'google_compute_instance'
  assert resources[0]['values']['name'] == 'test'


def test_multiple_instances(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=2)
  assert len(resources) == 2
  assert set(r['type'] for r in resources) == set(['google_compute_instance'])


def test_service_account(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=2,
                             service_account_create='true')
  assert len(resources) == 3
  assert 'google_service_account' in [r['type'] for r in resources]


def test_template(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, use_instance_template='true')
  assert len(resources) == 1
  assert resources[0]['type'] == 'google_compute_instance_template'
  assert resources[0]['values']['name_prefix'] == 'test-'


def test_group(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=2,
                             group='{named_ports={}}')
  assert len(resources) == 3
  assert set(r['type'] for r in resources) == set([
      'google_compute_instance_group', 'google_compute_instance'
  ])


def test_group_zones(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=2,
                             group='{named_ports={}}',
                             zones='["europe-west1-b", "europe-west1-c"]')
  assert len(resources) == 4
  assert set(r['type'] for r in resources) == set([
      'google_compute_instance_group', 'google_compute_instance'
  ])


def test_iam(plan_runner):
  iam = (
      '{"roles/compute.instanceAdmin" = ["user:a@a.com", "user:b@a.com"],'
      '"roles/iam.serviceAccountUser" = ["user:a@a.com"]}'
  )
  _, resources = plan_runner(
      FIXTURES_DIR, instance_count=2, iam=iam)
  assert len(resources) == 6
  assert set(r['type'] for r in resources) == set([
      'google_compute_instance', 'google_compute_instance_iam_binding'])
  iam_bindings = dict(
      (r['index'], r['values']['members']) for r in resources if r['type']
      == 'google_compute_instance_iam_binding'
  )
  assert iam_bindings == {
      'roles/compute.instanceAdmin/test-1': ['user:a@a.com', 'user:b@a.com'],
      'roles/compute.instanceAdmin/test-2': ['user:a@a.com', 'user:b@a.com'],
      'roles/iam.serviceAccountUser/test-1': ['user:a@a.com'],
      'roles/iam.serviceAccountUser/test-2': ['user:a@a.com'],
  }


def test_confidential_compute(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=1,
                             confidential_compute='true')
  assert len(resources) == 1
  assert resources[0]['values']['confidential_instance_config'] == [
      {'enable_confidential_compute': True}]
  assert resources[0]['values']['scheduling'][0]['on_host_maintenance'] == 'TERMINATE'


def test_confidential_compute_template(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=1,
                             confidential_compute='true',
                             use_instance_template='true')
  assert len(resources) == 1
  assert resources[0]['values']['confidential_instance_config'] == [
      {'enable_confidential_compute': True}]
  assert resources[0]['values']['scheduling'][0]['on_host_maintenance'] == 'TERMINATE'
