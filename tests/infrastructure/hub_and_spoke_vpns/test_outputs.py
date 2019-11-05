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


def test_hub_outputs(plan):
  "Hub VPC ranges and regions should match input variables."
  output = plan.outputs['hub']
  for subnet in plan.variables['hub_subnets']:
    name = subnet['subnet_name']
    assert output['subnets_ips'][name] == subnet['subnet_ip']
    assert output['subnets_regions'][name] == subnet['subnet_region']


def test_spokes_outputs(plan):
  "Spokes VPC ranges and regions should match input variables."
  for i in (1, 2):
    output = plan.outputs['spoke-%s' % i]
    for subnet in plan.variables['spoke_%s_subnets' % i]:
      name = subnet['subnet_name']
      assert output['subnets_ips'][name] == subnet['subnet_ip']
      assert output['subnets_regions'][name] == subnet['subnet_region']
