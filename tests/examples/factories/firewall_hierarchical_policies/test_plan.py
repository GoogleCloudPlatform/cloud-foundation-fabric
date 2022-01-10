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

def test_firewall(plan_runner):
  "Test hierarchical firewall rules from conf/rules"
  _, resources = plan_runner()
  assert len(resources) == 6
  assert set(r["type"] for r in resources) == set([
      "google_compute_firewall_policy_rule", "google_compute_firewall_policy_association", "google_compute_firewall_policy"
  ])
  rule_ssh = [r["values"] for r in resources if r["type"] ==
              "google_compute_firewall_policy_rule"
              and r["values"]["priority"] == 1001]
  rule_icmp = [r["values"] for r in resources if r["type"] ==
               "google_compute_firewall_policy_rule"
               and r["values"]["priority"] == 1000]
  association_org = [r["values"] for r in resources if r["type"] ==
                     "google_compute_firewall_policy_association"
                     and r["values"]["attachment_target"] == "organizations/1234567890"]
  association_folder = [r["values"] for r in resources if r["type"] ==
                        "google_compute_firewall_policy_association"
                        and r["values"]["attachment_target"] == "folders/0987654321"]
  policies_org = [r["values"] for r in resources if r["type"] ==
                  "google_compute_firewall_policy"
                  and r["values"]["parent"] == "organizations/1234567890"]
  policies_folder = [r["values"] for r in resources if r["type"] ==
                     "google_compute_firewall_policy"
                     and r["values"]["parent"] == "folders/0987654321"]

  assert set(rule_ssh[0]["match"][0]["src_ip_ranges"]) == set(
      ["10.0.0.0/24", "10.0.10.0/24", "192.168.1.1/32"])
  assert rule_icmp[0]["match"][0]["layer4_configs"][0]["ip_protocol"] == "icmp"
  assert association_org[0]["name"] == "hierarchical-fw-policy-organizations-1234567890"
  assert association_folder[0]["name"] == "hierarchical-fw-policy-folders-0987654321"
  assert policies_org[0]["short_name"] == "hierarchical-fw-policy-organizations-1234567890"
  assert policies_folder[0]["short_name"] == "hierarchical-fw-policy-folders-0987654321"
