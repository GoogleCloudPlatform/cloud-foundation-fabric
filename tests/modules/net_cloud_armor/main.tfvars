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

project_id          = "test-project"
name                = "test-policy"
description         = "Test security policy"
default_rule_action = "deny(403)"
adaptive_protection_config = {
  layer_7_ddos_defense = {
    enable          = true
    rule_visibility = "STANDARD"
  }
}
rules = {
  rule-owasp = {
    action      = "deny(403)"
    priority    = 1000
    description = "OWASP rule"
    expression  = "evaluatePreconfiguredWaf('sqli-v33-stable')"
  }
}
