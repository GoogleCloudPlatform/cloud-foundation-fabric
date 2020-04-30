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
    '   name=null, secondary_ip_range=null},'
    'b={region = "europe-west1", ip_cidr_range = "10.0.1.0/24",'
    '   name=null, secondary_ip_range=null},'
    'c={region = "europe-west1", ip_cidr_range = "10.0.2.0/24",'
    '   name="c", secondary_ip_range={a="192.168.0.0/24", b="192.168.1.0/24"}},'
    '}'
)
_VAR_LOG_CONFIG = '{a = { flow_sampling = 0.1 }}'
_VAR_LOG_CONFIG_DEFAULTS = (
    '{'
    'aggregation_interval = "INTERVAL_10_MIN", '
    'flow_sampling = 0.5, '
    'metadata = "INCLUDE_ALL_METADATA"'
    '}'
)


def test_subnets_simple(plan_runner):
  "Test subnets variable."
  _, resources = plan_runner(FIXTURES_DIR, subnets=_VAR_SUBNETS)
  assert len(resources) == 4
  subnets = [r['values']
             for r in resources if r['type'] == 'google_compute_subnetwork']
  assert set(s['name'] for s in subnets) == set(
      ['my-vpc-a', 'my-vpc-b', 'c'])
  assert set(len(s['secondary_ip_range']) for s in subnets) == set([0, 0, 2])


def test_subnet_log_configs(plan_runner):
  "Test subnets flow logs configuration and defaults."
  _, resources = plan_runner(FIXTURES_DIR, subnets=_VAR_SUBNETS,
                             log_configs=_VAR_LOG_CONFIG,
                             log_config_defaults=_VAR_LOG_CONFIG_DEFAULTS,
                             subnet_flow_logs='{a=true, b=true}')
  assert len(resources) == 4
  flow_logs = {}
  for r in resources:
    if r['type'] != 'google_compute_subnetwork':
      continue
    flow_logs[r['values']['name']] = r['values']['log_config']
  assert flow_logs == {
      # enable, override one default option
      'my-vpc-a': [{
          'aggregation_interval': 'INTERVAL_10_MIN',
          'flow_sampling': 0.1,
          'metadata': 'INCLUDE_ALL_METADATA'
      }],
      # enable, use defaults
      'my-vpc-b': [{
          'aggregation_interval': 'INTERVAL_10_MIN',
          'flow_sampling': 0.5,
          'metadata': 'INCLUDE_ALL_METADATA'
      }],
      # don't enable
      'c': []
  }
