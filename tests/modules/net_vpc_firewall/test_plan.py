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

def test_vpc_firewall_simple(plan_runner):
  "Test vpc with no extra options."
  _, resources = plan_runner()
  assert len(resources) == 3
  assert set([r['type'] for r in resources]) == set(
      ['google_compute_firewall'])
  assert set([r['values']['name'] for r in resources]) == set(
      ['vpc-ingress-tag-http', 'vpc-ingress-tag-https', 'vpc-ingress-tag-ssh'])
  assert set([r['values']['project'] for r in resources]) == set(['project'])
  assert set([r['values']['network'] for r in resources]) == set(['vpc'])


def test_vpc_firewall_factory(plan_runner):
  "Test shared vpc variables."
  _, resources = plan_runner(
    data_folder="config/firewall",
    cidr_template_file="config/cidr_template.yaml"
  )
  assert len(resources) == 4
  factory_rule = [r for r in resources if r["values"]
                  ["name"] == "allow-healthchecks"][0]["values"]
  assert set(factory_rule["source_ranges"]) == set(
      ["130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"])
  assert set(factory_rule["target_tags"]) == set(["lb-backends"])
