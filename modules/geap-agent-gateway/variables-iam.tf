/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description IAM Unified Access Policy variables.

variable "access_policies" {
  description = "IAM v3 Unified Access Policies (UAPs) and their bindings, keyed by policy ID. Set 'rules' to create a project access policy and bind it, or 'policy_reuse' to bind an existing access policy."
  type = map(object({
    annotations  = optional(map(string))
    bind         = optional(bool, true)
    binding_id   = optional(string)
    display_name = optional(string)
    policy_reuse = optional(string)
    # 'project' binds to the gateway project, 'gateway' binds to this
    # Agent Gateway, or pass a full '//...' resource URI.
    target_resource = optional(string, "project")
    binding_condition = optional(object({
      expression  = string
      title       = optional(string)
      description = optional(string)
      location    = optional(string)
    }))
    rules = optional(map(object({
      principals           = list(string)
      agent_id             = optional(string)
      condition            = optional(string)
      condition_service    = optional(string, "iap.googleapis.com")
      description          = optional(string)
      effect               = optional(string, "ALLOW")
      endpoint_id          = optional(string)
      excluded_permissions = optional(list(string), [])
      excluded_principals  = optional(list(string), [])
      location             = optional(string)
      mcp_server_id        = optional(string)
      permissions = optional(
        list(string), ["iap.googleapis.com/resources.egressViaIAP"]
      )
      registry = optional(bool, false)
    })), {})
  }))
  nullable = false
  default  = {}

  validation {
    condition = alltrue([
      for k, v in var.access_policies :
      (v.policy_reuse == null && length(v.rules) > 0)
      || (v.policy_reuse != null && length(v.rules) == 0)
    ])
    error_message = "Each access policy must either define at least one rule in 'rules' or set 'policy_reuse' (not both)."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.access_policies : [
        for rk, rv in v.rules : contains(["ALLOW", "DENY"], rv.effect)
      ]
    ]))
    error_message = "Rule effect must be 'ALLOW' or 'DENY'."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.access_policies : [
        for rk, rv in v.rules : (
          length(compact([rv.agent_id, rv.endpoint_id, rv.mcp_server_id]))
          + (rv.registry ? 1 : 0)
        ) <= 1
      ]
    ]))
    error_message = "Set at most one of 'agent_id', 'endpoint_id', 'mcp_server_id', or 'registry' per rule."
  }
}
