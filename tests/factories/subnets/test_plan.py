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

import os
import pytest

FIXTURES_DIR = os.path.join(os.path.dirname(__file__), "fixture")


def test_firewall(plan_runner):
  "Test hierarchical firewall rules from conf/rules"
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 6
  assert set(r["type"] for r in resources) == set(
      ["google_compute_subnetwork", "google_compute_subnetwork_iam_binding"])
  subnets = [
      r["values"] for r in resources
      if r["type"] == "google_compute_subnetwork"
  ]
  iam_bindings = [
      r["values"] for r in resources
      if r["type"] == "google_compute_subnetwork_iam_binding"
  ]

  subnet_a_a = [
      s for s in subnets if s["project"] == "project-a"
      and s["network"] == "vpc-a" and s["name"] == "subnet-a"
  ][0]
  assert subnet_a_a["ip_cidr_range"] == "10.0.0.0/24"
  assert subnet_a_a["private_ip_google_access"] == True
  assert subnet_a_a["region"] == "europe-west1"
  assert subnet_a_a["secondary_ip_range"] == [{
      "ip_cidr_range":
      "192.168.0.0/24",
      "range_name":
      "secondary-range-a"
  }, {
      "ip_cidr_range":
      "192.168.1.0/24",
      "range_name":
      "secondary-range-b"
  }]

  subnet_a_b = [
      s for s in subnets if s["project"] == "project-a"
      and s["network"] == "vpc-a" and s["name"] == "subnet-b"
  ][0]
  assert subnet_a_b["private_ip_google_access"] == False

  iam_binding_b_alpha = [
      b for b in iam_bindings if b["project"] == "project-b"
  ][0]
  assert set(iam_binding_b_alpha["members"]) == set(
      ["user:sruffilli@google.com"])
  assert iam_binding_b_alpha["role"] == "roles/compute.networkUser"
  assert iam_binding_b_alpha["subnetwork"] == "subnet-alpha"
