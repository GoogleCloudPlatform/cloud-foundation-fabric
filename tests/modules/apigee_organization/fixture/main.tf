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
  source             = "../../../../modules/apigee-organization"
  project_id         = "my-project"
  analytics_region   = var.analytics_region
  runtime_type       = "CLOUD"
  billing_type       = "EVALUATION"
  authorized_network = var.network
  apigee_environments = {
    eval1 = {
      api_proxy_type  = "PROGRAMMABLE"
      deployment_type = "PROXY"
    }
    eval2 = {
      api_proxy_type  = "CONFIGURABLE"
      deployment_type = "ARCHIVE"
    }
    eval3 = {}
  }
  apigee_envgroups = {
    eval = {
      environments = [
        "eval1",
        "eval2"
      ]
      hostnames = [
        "eval.api.example.com"
      ]
    }
  }
}
