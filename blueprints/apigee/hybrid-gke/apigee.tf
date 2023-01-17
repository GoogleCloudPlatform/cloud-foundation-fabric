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

locals {
  envgroup    = "test"
  environment = "apis-test"
}

module "apigee" {
  source     = "../../../modules/apigee"
  project_id = module.project.project_id
  organization = {
    analytics_region = var.region
    runtime_type     = "HYBRID"
  }
  envgroups = {
    (local.envgroup) = [var.hostname]
  }
  environments = {
    (local.environment) = {
      envgroups = [local.envgroup]
    }
  }
}

resource "local_file" "deploy_apiproxy_file" {
  content = templatefile("${path.module}/templates/deploy-apiproxy.sh.tpl", {
    org = module.project.project_id
    env = local.environment
  })
  filename        = "${path.module}/deploy-apiproxy.sh"
  file_permission = "0777"
}
