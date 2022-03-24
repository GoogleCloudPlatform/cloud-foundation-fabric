/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "test" {
  source                        = "../../../../modules/net-ilb-l7"
  project_id                    = "my-project"
  name                          = "ilb-l7-test"
  region                        = "europe-west1"
  backend_services_config       = var.backend_services_config
  forwarding_rule_config        = var.forwarding_rule_config
  health_checks_config          = var.health_checks_config
  health_checks_config_defaults = var.health_checks_config_defaults
  https                         = var.https
  ssl_certificates_config       = var.ssl_certificates_config
  static_ip_config              = var.static_ip_config
  target_proxy_https_config     = var.target_proxy_https_config
  url_map_config                = var.url_map_config
}
