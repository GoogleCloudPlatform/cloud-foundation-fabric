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
_VAR_SUBNETS = (
    '[ '
    '{name = "a", region = "europe-west1", ip_cidr_range = "10.0.0.0/24",'
    '   secondary_ip_range=null},'
    '{name = "b", region = "europe-west1", ip_cidr_range = "10.0.1.0/24",'
    '   secondary_ip_range=null},'
    '{name = "c", region = "europe-west1", ip_cidr_range = "10.0.2.0/24",'
    '   secondary_ip_range={a="192.168.0.0/24", b="192.168.1.0/24"}},'
    ']'
)


def test_subnets_simple(plan_runner):
  "Test subnets variable."
  _, resources = plan_runner(FIXTURES_DIR, subnets=_VAR_SUBNETS)
  assert len(resources) == 4
  subnets = [r['values']
             for r in resources if r['type'] == 'google_compute_subnetwork']
  assert set(s['name'] for s in subnets) == set(
      ['a', 'b', 'c'])
  assert set(len(s['secondary_ip_range']) for s in subnets) == set([0, 0, 2])


def test_subnet_log_configs(plan_runner):
  "Test subnets flow logs configuration and defaults."
  log_config = '{"europe-west1/a" = { flow_sampling = 0.1 }}'
  log_config_defaults = (
      '{aggregation_interval = "INTERVAL_10_MIN", flow_sampling = 0.5, '
      'metadata = "INCLUDE_ALL_METADATA"}'
  )
  subnet_flow_logs = '{"europe-west1/a"=true, "europe-west1/b"=true}'
  _, resources = plan_runner(FIXTURES_DIR, subnets=_VAR_SUBNETS,
                             log_configs=log_config,
                             log_config_defaults=log_config_defaults,
                             subnet_flow_logs=subnet_flow_logs)
  assert len(resources) == 4
  flow_logs = {}
  for r in resources:
    if r['type'] != 'google_compute_subnetwork':
      continue
    flow_logs[r['values']['name']] = [{key: config[key] for key in config.keys() 
                               & {'aggregation_interval', 'flow_sampling', 'metadata'}} 
                               for config in r['values']['log_config']]
  assert flow_logs == {
      # enable, override one default option
      'a': [{
          'aggregation_interval': 'INTERVAL_10_MIN',
          'flow_sampling': 0.1,
          'metadata': 'INCLUDE_ALL_METADATA'
      }],
      # enable, use defaults
      'b': [{
          'aggregation_interval': 'INTERVAL_10_MIN',
          'flow_sampling': 0.5,
          'metadata': 'INCLUDE_ALL_METADATA'
      }],
      # don't enable
      'c': []
  }
