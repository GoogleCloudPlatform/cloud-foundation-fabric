/**
 * Copyright 2025 Google LLC
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

# tfdoc:file:description Service agents supporting resources.

locals {
  _sa_raw = yamldecode(file("${path.module}/service-agents.yaml"))
  service_agents = {
    for agent in local._sa_raw :
    agent.name => {
      create_command = (
        "gcloud beta services identity create --service=${agent.api} --folder=${local.folder_number}"
      )
      display_name = agent.display_name
      identity = templatestring(agent.identity, {
        folder_number = local.folder_number
      })
    }
  }
}
