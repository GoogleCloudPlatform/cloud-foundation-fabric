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

import pytest


@pytest.fixture(scope='module')
def result(run_fixture, fix_path):
  "Runs fixture interpolating current path, and returns result."
  return run_fixture(fix_path('fixtures/vpc-subnets'))


def test_vpc_attributes(result):
  "Test network attributes."
  network = result.output['network']
  assert network['routing_mode'] == 'REGIONAL'
  assert network['description'] == 'Created by the vpc-subnets fixture.'


def test_subnet_names(result):
  "Test subnet names output."
  resource_names = sorted([s['name']
                           for s in result.output['subnets'].values()])
  assert resource_names == sorted(
      [k for k in result.plan.variables['subnets']])


def test_subnet_ips(result):
  "Test subnet IPs output."
  for name, attrs in result.plan.variables['subnets'].items():
    assert result.output['subnet_ips'][name] == attrs['ip_cidr_range']


def test_subnet_regions(result):
  "Test subnet regions output."
  assert result.output['subnet_regions'] == dict(
      (k, v['region']) for k, v in result.plan.variables['subnets'].items())


def test_secondary_ip_ranges(result):
  "Test subnet secondary ranges output."
  for name, attrs in result.plan.variables['subnets'].items():
    assert attrs['secondary_ip_range'] == result.output['subnet_secondary_ranges'][name]


def test_flow_logs(result):
  "Test that log config is set using the enable flow logs variable."
  enable_flow_logs = result.plan.variables['subnet_flow_logs']
  for name, attrs in result.plan.variables['subnets'].items():
    log_config = enable_flow_logs.get(name, False)
    assert len(result.output['subnets'][name]['log_config']) == log_config
