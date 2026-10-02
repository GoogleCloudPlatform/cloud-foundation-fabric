# Copyright 2026 Google LLC
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

project_id = "test-project"
region     = "europe-west1"
name       = "test-lb"
vpc_config = {
  network = "projects/test-project/global/networks/test-vpc"
}
group_configs = {
  default = {
    zone = "europe-west1-b"
  }
}
backend_service_configs = {
  default = {
    backends = [{ group = "default" }]
  }
}
protocol = "HTTPS"
ssl_certificates = {
  certificate_ids = [
    "projects/test-project/regions/europe-west1/sslCertificates/test-cert"
  ]
}
https_proxy_config = {
  server_tls_policy = "projects/test-project/locations/europe-west1/serverTlsPolicies/mtls"
}
