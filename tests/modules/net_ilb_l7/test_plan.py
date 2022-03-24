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

_BACKEND_SVC_CONFIG = '''{
  my-group = {
    enable_cdn    = false,
    cdn_config    = null,
    backends = [
      {
        group   = "my_group",
        options = null
      }
    ],
    health_checks = []
    log_config    = null
    options       = null
  }
}'''

_BACKEND_SVC_CONFIG_HC = '''{
  my-group = {
    enable_cdn    = false,
    cdn_config    = null,
    backends = [
      {
        group   = "my_group",
        options = null
      }
    ],
    health_checks = ["hc_1"]
    log_config    = null
    options       = null
  }
}'''

_NAME = 'ilb-l7-test'

_RESERVED_IP_CONFIG = '''{
  reserve = true
  options = null
}'''

_SSL_CERTIFICATES_CONFIG = '''{
  my-domain = {
    domains = [
      "my-domain.com"
    ],
    tls_private_key      = "my-key"
    tls_self_signed_cert = "my-cert"
  }
}'''

_TARGET_PROXY_HTTPS_CONFIG = '''{
  ssl_certificates = [
    "my-domain"
  ]
}'''


def test_group_default_hc(plan_runner):
  "Tests a group backend service with no HC specified."
  _, resources = plan_runner(backend_services_config=_BACKEND_SVC_CONFIG)
  assert len(resources) == 5
  resources = dict((r['type'], r['values']) for r in resources)

  fwd_rule = resources['google_compute_forwarding_rule']
  assert fwd_rule['load_balancing_scheme'] == 'INTERNAL_MANAGED'
  assert fwd_rule['port_range'] == '80'
  assert fwd_rule['ip_protocol'] == 'TCP'

  group = resources['google_compute_region_backend_service']
  assert len(group['backend']) == 1
  assert group['backend'][0]['group'] == 'my_group'

  health_check = resources['google_compute_region_health_check']
  assert health_check['name'] == _NAME + '-default'
  assert len(health_check['http_health_check']) > 0
  assert len(health_check['https_health_check']) == 0
  assert len(health_check['http2_health_check']) == 0
  assert len(health_check['tcp_health_check']) == 0
  assert health_check['http_health_check'][0]['port_specification'] == 'USE_SERVING_PORT'
  assert health_check['http_health_check'][0]['proxy_header'] == 'NONE'
  assert health_check['http_health_check'][0]['request_path'] == '/'

  assert 'google_compute_region_target_http_proxy' in resources
  assert 'google_compute_region_target_https_proxy' not in resources
  assert 'google_compute_region_url_map' in resources


def test_group_no_hc(plan_runner):
  "Tests a group backend service without HCs (including no default HC)."
  _, resources = plan_runner(backend_services_config=_BACKEND_SVC_CONFIG,
                             health_checks_config_defaults='null')

  assert len(resources) == 4
  resources = dict((r['type'], r['values']) for r in resources)

  assert 'google_compute_region_backend_service' in resources
  assert 'google_compute_forwarding_rule' in resources
  assert 'google_compute_region_health_check' not in resources
  assert 'google_compute_region_target_http_proxy' in resources
  assert 'google_compute_region_target_https_proxy' not in resources
  assert 'google_compute_region_url_map' in resources


def test_group_existing_hc(plan_runner):
  "Tests a group backend service with referencing an existing HC."
  _, resources = plan_runner(backend_services_config=_BACKEND_SVC_CONFIG_HC)
  assert len(resources) == 4
  resources = dict((r['type'], r['values']) for r in resources)

  assert 'google_compute_region_backend_service' in resources
  assert 'google_compute_forwarding_rule' in resources
  assert 'google_compute_region_health_check' not in resources
  assert 'google_compute_region_target_http_proxy' in resources
  assert 'google_compute_region_target_https_proxy' not in resources
  assert 'google_compute_region_url_map' in resources


def test_reserved_ip(plan_runner):
  "Tests an IP reservation with a group backend service."
  _, resources = plan_runner(
    backend_services_config=_BACKEND_SVC_CONFIG,
    static_ip_config=_RESERVED_IP_CONFIG
  )
  assert len(resources) == 6
  resources = dict((r['type'], r['values']) for r in resources)

  assert 'google_compute_region_backend_service' in resources
  assert 'google_compute_address' in resources
  assert 'google_compute_forwarding_rule' in resources
  assert 'google_compute_region_target_http_proxy' in resources
  assert 'google_compute_region_target_https_proxy' not in resources
  assert 'google_compute_region_url_map' in resources


def test_ssl(plan_runner):
  "Tests HTTPS and SSL certificates."
  _, resources = plan_runner(
    backend_services_config=_BACKEND_SVC_CONFIG,
    https="true",
    ssl_certificates_config=_SSL_CERTIFICATES_CONFIG,
    target_proxy_https_config=_TARGET_PROXY_HTTPS_CONFIG
  )
  assert len(resources) == 6
  resources = dict((r['type'], r['values']) for r in resources)

  fwd_rule = resources['google_compute_forwarding_rule']
  assert fwd_rule['port_range'] == '443'

  assert 'google_compute_region_backend_service' in resources
  assert 'google_compute_forwarding_rule' in resources
  assert 'google_compute_ssl_certificate' in resources
  assert 'google_compute_region_target_http_proxy' not in resources
  assert 'google_compute_region_target_https_proxy' in resources
  assert 'google_compute_region_url_map' in resources


def test_ssl_existing_cert(plan_runner):
  "Tests HTTPS and SSL existing certificate."
  _, resources = plan_runner(
    backend_services_config=_BACKEND_SVC_CONFIG,
    https="true",
    target_proxy_https_config=_TARGET_PROXY_HTTPS_CONFIG
  )
  assert len(resources) == 5
  resources = dict((r['type'], r['values']) for r in resources)

  fwd_rule = resources['google_compute_forwarding_rule']
  assert fwd_rule['port_range'] == '443'

  assert 'google_compute_region_backend_service' in resources
  assert 'google_compute_forwarding_rule' in resources
  assert 'google_compute_ssl_certificate' not in resources
  assert 'google_compute_region_target_http_proxy' not in resources
  assert 'google_compute_region_target_https_proxy' in resources
  assert 'google_compute_region_url_map' in resources
