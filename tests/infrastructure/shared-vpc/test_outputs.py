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

"Test root module outputs."


def test_vpc_ranges(plan):
  "VPC ranges should match input variables."
  ranges = plan.outputs['vpc_subnets']
  for subnet in plan.variables['subnets']:
    assert ranges[subnet['subnet_name']] == subnet['subnet_ip']


def test_project_ids(plan):
  "Project ids should use prefix and match expected values."
  prefix = plan.variables['prefix']
  assert plan.outputs['host_project_id'] == prefix + '-vpc-host'
  assert plan.outputs['service_project_ids']['gce'] == prefix + '-gce'
