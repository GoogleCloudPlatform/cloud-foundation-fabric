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

def test_firewall(plan_runner):
  "Test hierarchical firewall rules from conf/rules"
  _, resources = plan_runner()
  assert len(resources) == 2

  assert set(r["type"]
             for r in resources) == set(["google_compute_firewall"])

  rule_hc = [
      r["values"] for r in resources
      if r["values"]["name"] == "allow-healthchecks-vpc-a"
  ][0]
  rule_be = [
      r["values"] for r in resources
      if r["values"]["description"] == "Allow traffic to LB backend"
  ][0]

  assert set(rule_hc["source_ranges"]) == set(
      ["130.211.0.0/22", "35.191.0.0/16"])
  assert rule_hc["direction"] == "INGRESS"
  assert rule_hc["network"] == "vpc-a"
  assert rule_hc["priority"] == 1000
  assert rule_hc["project"] == "resource-factory-playground"
  assert rule_hc["allow"][0] == {'ports': ['80'], 'protocol': 'tcp'}
  assert rule_be["log_config"][0] == {'metadata': 'INCLUDE_ALL_METADATA'}
