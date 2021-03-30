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
OAUTH_SCOPE = ['https://www.googleapis.com/auth/cloud-platform']
OAUTH_SCOPES = [
    'https://www.googleapis.com/auth/devstorage.read_only',
    'https://www.googleapis.com/auth/logging.write',
    'https://www.googleapis.com/auth/monitoring',
    'https://www.googleapis.com/auth/monitoring.write']


def test_defaults(plan_runner):
  "Test resources created with variable defaults."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  node_config = resources[0]['values']['node_config'][0]
  assert node_config['oauth_scopes'] == OAUTH_SCOPES
  assert 'service_account' not in node_config


def test_external_sa(plan_runner):
  "Test resources created with externally managed sa."
  _, resources = plan_runner(
      FIXTURES_DIR, node_service_account='foo@example.org')
  assert len(resources) == 1
  node_config = resources[0]['values']['node_config'][0]
  assert node_config['oauth_scopes'] == OAUTH_SCOPES
  assert node_config['service_account'] == 'foo@example.org'


def test_external_scopes(plan_runner):
  "Test resources created with externally defined scopes."
  oauth_scopes = '["https://www.googleapis.com/auth/cloud-platform"]'
  _, resources = plan_runner(
      FIXTURES_DIR, node_service_account_scopes=oauth_scopes)
  assert len(resources) == 1
  node_config = resources[0]['values']['node_config'][0]
  assert node_config['oauth_scopes'] == OAUTH_SCOPE
  assert 'service_account' not in node_config


def test_internal_sa(plan_runner):
  "Test resources created with internally managed sa."
  _, resources = plan_runner(FIXTURES_DIR, node_service_account_create='true')
  assert len(resources) == 2
  node_config = resources[0]['values']['node_config'][0]
  assert node_config['oauth_scopes'] == OAUTH_SCOPE
  assert 'service_account' not in node_config
