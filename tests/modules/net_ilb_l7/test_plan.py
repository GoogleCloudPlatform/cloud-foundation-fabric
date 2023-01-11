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

import collections


def test_defaults(plan_runner):
  "Test with default values."
  _, resources = plan_runner(tf_var_file='test.defaults.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_region_backend_service.default': 1,
      'google_compute_region_target_http_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_groups(plan_runner):
  "Test groups."
  _, resources = plan_runner(tf_var_file='test.groups.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_instance_group.default': 1,
      'google_compute_region_backend_service.default': 1,
      'google_compute_region_target_http_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_health_checks_external(plan_runner):
  "Test external health check."
  _, resources = plan_runner(tf_var_file='test.health-checks-external.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_region_backend_service.default': 1,
      'google_compute_region_target_http_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_health_checks_custom(plan_runner):
  "Test custom health check."
  _, resources = plan_runner(tf_var_file='test.health-checks-custom.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_region_backend_service.default': 1,
      'google_compute_region_target_http_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_https(plan_runner):
  "Test HTTPS load balancer."
  _, resources = plan_runner(tf_var_file='test.https.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_region_target_https_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_negs(plan_runner):
  "Test negs."
  _, resources = plan_runner(tf_var_file='test.negs.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_network_endpoint.default': 1,
      'google_compute_network_endpoint_group.default': 1,
      'google_compute_region_backend_service.default': 1,
      'google_compute_region_target_http_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_ssl_certificates(plan_runner):
  "Test HTTPS load balancer with SSL certificates."
  _, resources = plan_runner(tf_var_file='test.ssl.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_region_ssl_certificate.default': 1,
      'google_compute_region_target_https_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }


def test_urlmaps(plan_runner):
  "Test URL maps."
  _, resources = plan_runner(tf_var_file='test.urlmaps.tfvars')
  counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
  assert counts == {
      'google_compute_forwarding_rule.default': 1,
      'google_compute_health_check.default': 1,
      'google_compute_region_backend_service.default': 2,
      'google_compute_region_target_http_proxy.default': 1,
      'google_compute_region_url_map.default': 1
  }
