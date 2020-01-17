# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import collections
import re

import pytest


Binding = collections.namedtuple('Binding', 'subnet role members')


@pytest.fixture(scope='module')
def result(run_fixture, fix_path):
  "Runs fixture interpolating current path, and returns result."
  return run_fixture(fix_path('fixtures/vpc-iam-bindings'))


@pytest.fixture(scope='module')
def bindings(result):
  "Returns a streamlined list of bindings."
  return [
      Binding(b['subnetwork'].split('/')[-1], b['role'], b['members'])
      for b in result.output['bindings'].values()
  ]


@pytest.fixture(scope='module')
def subnet_names(result):
  "Returns the list of subnet names."
  return [s['name'] for s in result.output['subnets'].values()]


def test_vpc_attributes(result):
  "Test network attributes."
  network = result.output['network']
  assert network['routing_mode'] == 'GLOBAL'
  assert network['description'] == 'Created by the vpc-iam-bindings fixture.'


def test_subnet_names(result, subnet_names):
  "Test subnet names output."
  resource_names = sorted(
      [s['name'] for s in result.output['subnets'].values()])
  assert resource_names == sorted(subnet_names)


def test_binding_roles(result, bindings, subnet_names):
  "Test that the correct roles from IAM bindings are set."
  assert len([b for b in bindings if b.subnet == 'subnet-a']) == 0
  assert set([b.role for b in bindings if b.subnet == 'subnet-b']) == set([
      'roles/compute.networkUser', 'roles/compute.networkViewer'
  ])
  assert [b.role for b in bindings if b.subnet == 'subnet-c'] == [
      'roles/compute.networkViewer'
  ]


def test_binding_members(result, bindings, subnet_names):
  "Test that the correct members from IAM bindings are set."
  r = re.compile(r'^serviceAccount:([^@]+)@.*$')
  for b in bindings:
    members = [r.sub(r'\1', m) for m in b.members]
    if b.subnet == 'subnet-b':
      if b.role == 'roles/compute.networkUser':
        assert members == ['user-a', 'user-b']
      else:
        assert members == ['user-d']
    else:
      assert members == ['user-d', 'user-e']
