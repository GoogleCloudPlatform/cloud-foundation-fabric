# Copyright 2023 Google LLC
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

output:
  compression: true
  url: ${chronicle_url}
  identity:
    secret_key: |
      ${indent(6, secret_key)}
    collector_id: ${collector_id}
    customer_id: ${customer_id}
server:
  graceful_timeout: 15s
  drain_timeout: 10s
  http:
    port: 8080
    host: 0.0.0.0
    read_timeout: 3s
    read_header_timeout: 3s
    write_timeout: 3s
    idle_timeout: 3s
    routes:
    - meta:
        available_status: 204
        ready_status: 204
        unready_status: 503
collectors:
- syslog:
    common:
      enabled: true
      data_type: PAN_FIREWALL
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2001
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2001
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: F5_BIGIP_LTM
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2011
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2011
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: NIX_SYSTEM
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2021
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2021
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: AUDITD
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2031
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2031
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: WINEVTLOG
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2041
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2041
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: WINDOWS_DEFENDER_AV
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2051
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2051
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: POWERSHELL
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2061
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2061
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}
- syslog:
    common:
      enabled: true
      data_type: WINDOWS_FIREWALL
      data_hint:
      batch_n_seconds: 10
      batch_n_bytes: 1048576
    tcp_address: 0.0.0.0:2071
%{ if ! tls_required ~}
    udp_address: 0.0.0.0:2071
%{ endif ~}
    connection_timeout_sec: 60
%{ if tls_required ~}
    certificate: "/opt/chronicle/external/certs/tls.crt"
    certificate_key: "/opt/chronicle/external/certs/tls.key"
    minimum_tls_version: "TLSv1_3"
%{ endif ~}