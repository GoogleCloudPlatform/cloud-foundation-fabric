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
_VAR_SUBNETS = (
    '{ '
    'a={region = "europe-west1", ip_cidr_range = "10.0.0.0/24",'
    '   secondary_ip_range=null},'
    'b={region = "europe-west1", ip_cidr_range = "10.0.1.0/24",'
    '   secondary_ip_range={a="192.168.0.0/24", b="192.168.1.0/24"}},'
    '}'
)


def test_vpc_simple(plan_runner):
  "Test vpc with no extra options."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  assert [r['type'] for r in resources] == ['google_compute_network']
  assert [r['values']['name'] for r in resources] == ['my-vpc']
  assert [r['values']['project'] for r in resources] == ['my-project']


def test_subnets_simple(plan_runner):
  "Test subnets variable."
  _, resources = plan_runner(FIXTURES_DIR, subnets=_VAR_SUBNETS)
  assert len(resources) == 3
  subnets = [r['values']
             for r in resources if r['type'] == 'google_compute_subnetwork']
  assert set(s['name'] for s in subnets) == set(['my-vpc-a', 'my-vpc-b'])
  assert set(len(s['secondary_ip_range']) for s in subnets) == set([0, 2])


def test_subnets_options(plan_runner):
  "Test subnets options variables."
  _, resources = plan_runner(FIXTURES_DIR, subnets=_VAR_SUBNETS)
  assert len(resources) == 3
  subnets = [r['values']
             for r in resources if r['type'] == 'google_compute_subnetwork']
  assert set(s['name'] for s in subnets) == set(['my-vpc-a', 'my-vpc-b'])
  assert set(len(s['secondary_ip_range']) for s in subnets) == set([0, 2])


# def test_iam_roles_only(plan_runner):
#   "Test bucket resources with only iam roles passed."
#   _, resources = plan_runner(
#       FIXTURES_DIR, iam_roles='{bucket-a = [ "roles/storage.admin"]}')
#   assert len(resources) == 3


# def test_iam(plan_runner):
#   "Test bucket resources with iam roles and members."
#   iam_roles = (
#       '{bucket-a = ["roles/storage.admin"], '
#       'bucket-b = ["roles/storage.objectAdmin"]}'
#   )
#   iam_members = '{folder-a = { "roles/storage.admin" = ["user:a@b.com"] }}'
#   _, resources = plan_runner(
#       FIXTURES_DIR, iam_roles=iam_roles, iam_members=iam_members)
#   assert len(resources) == 4
