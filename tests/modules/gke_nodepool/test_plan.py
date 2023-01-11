# Copyright 2022 Google LLC
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


def test_defaults(plan_runner):
  "Test resources created with variable defaults."
  _, resources = plan_runner()
  assert len(resources) == 1
  assert resources[0]['values']['autoscaling'] == []


def test_service_account(plan_runner):
  _, resources = plan_runner()
  assert len(resources) == 1
  _, resources = plan_runner(service_account_create='true')
  assert len(resources) == 2
  assert 'google_service_account' in [r['type'] for r in resources]


def test_nodepool_config(plan_runner):
  nodepool_config = '''{
    autoscaling = { use_total_nodes = true, max_node_count = 3}
    management = {}
    upgrade_settings = { max_surge = 3, max_unavailable = 3 }
  }'''
  _, resources = plan_runner(nodepool_config=nodepool_config)
  assert resources[0]['values']['autoscaling'] == [{
      'location_policy': None,
      'max_node_count': None,
      'min_node_count': None,
      'total_max_node_count': 3,
      'total_min_node_count': None
  }]
  nodepool_config = '{ autoscaling = { max_node_count = 3} }'
  _, resources = plan_runner(nodepool_config=nodepool_config)
  assert resources[0]['values']['autoscaling'] == [{
      'location_policy': None,
      'max_node_count': 3,
      'min_node_count': None,
      'total_max_node_count': None,
      'total_min_node_count': None
  }]


def test_node_config(plan_runner):
  node_config = '''{
    gcfs     = true
    metadata = { foo = "bar" }
  }'''
  _, resources = plan_runner(node_config=node_config)
  values = resources[0]['values']['node_config'][0]
  assert values['gcfs_config'] == [{'enabled': True}]
  assert values['metadata'] == {
      'disable-legacy-endpoints': 'true',
      'foo': 'bar'
  }
