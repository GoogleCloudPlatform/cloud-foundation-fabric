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
  source                           = "../../../../modules/net-xlb"
  project_id                       = "my-project"
  name                             = "xlb-test"
  health_checks_config_defaults    = var.health_checks_config_defaults
  health_checks_config             = var.health_checks_config
  backend_services_config          = var.backend_services_config
  url_map_config                   = var.url_map_config
  https                            = var.https
  ssl_certificates_config          = var.ssl_certificates_config
  ssl_certificates_config_defaults = var.ssl_certificates_config_defaults
  target_proxy_https_config        = var.target_proxy_https_config 
  reserve_ip_address               = var.reserve_ip_address
  global_forwarding_rule_config    = var.global_forwarding_rule_config
}
