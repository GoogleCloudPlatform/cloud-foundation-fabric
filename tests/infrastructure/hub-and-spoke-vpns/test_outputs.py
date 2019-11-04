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
  hub_output = plan.outputs['hub']
  for hub_subnet in plan.variables['hub_subnets']:
    assert hub_output['subnets_ips'][hub_subnet['subnet_name']] == hub_subnet['subnet_ip']
    assert hub_output['subnets_regions'][hub_subnet['subnet_name']] == hub_subnet['subnet_region']


def test_spokes_outputs(plan):
  "Spokes VPC ranges and regions should match input variables."
  spoke_output_tpl = ('spoke-%s')
  spole_subnets_tpl = ('spoke_%s_subnets')
  for i in range(1, 3):
    spoke_output = plan.outputs[spoke_output_tpl % i]
    for spoke_subnet in plan.variables[spole_subnets_tpl % i]:
      assert spoke_output['subnets_ips'][spoke_subnet['subnet_name']] == spoke_subnet['subnet_ip']
      assert spoke_output['subnets_regions'][spoke_subnet['subnet_name']] == spoke_subnet['subnet_region']
