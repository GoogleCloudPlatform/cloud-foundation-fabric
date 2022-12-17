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

project_id       = "my-project"
network          = "my-network"
data_folders     = ["../firewall-rules"]
deployment_scope = "global"
policy_name      = "global-test"
firewall_rules = {
  "rule-1" = {
    action         = "allow"
    description    = "rule 30"
    direction      = "INGRESS"
    disabled       = false
    enable_logging = true
    layer4_configs = [{
      ports    = ["8080", "443", "80"]
      protocol = "tcp"
      },
      {
        ports    = ["53", "123-130"]
        protocol = "udp"
      }
    ]
    priority           = 1113
    src_ip_ranges      = ["0.0.0.0/0"]
    target_secure_tags = ["516738215535", "839187618417"]
  }
}
