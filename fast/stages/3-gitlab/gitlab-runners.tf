/**
 * Copyright 2023 Google LLC
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


module "gitlab-runner" {
  source    = "../../../blueprints/third-party-solutions/gitlab-runner"
  vm_config = {
    project_id = module.project.project_id
  }
  gitlab_config = {
    hostname    = var.gitlab_config.hostname
    ca_cert_pem = tls_self_signed_cert.gitlab_ca_cert[0].cert_pem
  }
  gitlab_runner_config = {
    authentication_token = var.gitlab_runners_config.tokens.landing
    runners_config       = {
      docker = {}
    }
  }
  network_config = {
    network_self_link = var.vpc_self_links.prod-landing
    subnet_self_link  = var.subnet_self_links.prod-landing["${var.regions.primary}/landing-gitlab-runners-ew1"]
  }
}