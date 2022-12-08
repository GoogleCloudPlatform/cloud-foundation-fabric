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


def test_plan(plan_summary):
  'Test module resources and outputs.'
  summary = plan_summary(
      'modules/net-glb', tf_var_files=['test-outputs.tfvars'])
  assert set(summary.outputs.keys()) == set([
      'address', 'backend_service_ids', 'forwarding_rule', 'group_ids',
      'health_check_ids', 'neg_ids'
  ])
  assert summary.counts == {
      'google_compute_backend_bucket': 1,
      'google_compute_backend_service': 5,
      'google_compute_global_forwarding_rule': 1,
      'google_compute_global_network_endpoint': 1,
      'google_compute_global_network_endpoint_group': 1,
      'google_compute_health_check': 1,
      'google_compute_instance_group': 1,
      'google_compute_network_endpoint': 2,
      'google_compute_network_endpoint_group': 2,
      'google_compute_region_network_endpoint_group': 1,
      'google_compute_target_http_proxy': 1,
      'google_compute_url_map': 1
  }
