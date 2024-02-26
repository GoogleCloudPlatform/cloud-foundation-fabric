/**
 * Copyright 2024 Google LLC
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

module "squid-proxy-gitlab" {
  source     = "./squid-proxy"
  project_id = module.gitlab_instance.project.project_id
  region     = var.regions.primary
  network_config = {
    network_self_link      = var.vpc_self_links.prod-landing
    proxy_subnet_self_link = var.subnet_self_links.prod-landing["${var.regions.primary}/landing-gitlab-server-ew1"]
  }
}