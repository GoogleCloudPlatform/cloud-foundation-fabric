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

variable "annotations" {
  description = "Resource annotations."
  type        = map(string)
  default     = {}
}

variable "automations" {
  description = "Configuration for automations associated with the deployment pipeline in a name => attributes format"
  type = map(object({
    project_id      = optional(string, null)
    region          = optional(string, null)
    service_account = optional(string, null)
    annotations     = optional(map(string))
    labels          = optional(map(string))
    description     = optional(string, null)
    suspended       = optional(bool, false)
    selector = optional(list(object({
      id     = optional(string, "*")
      labels = optional(map(string), {})
    })), [{ id = "*" }])
    promote_release_rule = optional(object({
      id                    = optional(string, "promote-release")
      wait                  = optional(string, null)
      destination_target_id = optional(string, null)
      destination_phase     = optional(string, null)
    }))
    advance_rollout_rule = optional(object({
      id            = optional(string, "advance-rollout")
      source_phases = optional(list(string), null)
      wait          = optional(string, null)
    }))
    repair_rollout_rule = optional(object({
      id     = optional(string, "repair-rollout")
      phases = optional(list(string), null)
      jobs   = optional(list(string), null)
      retry = optional(object({
        attempts     = optional(string, null)
        wait         = optional(string, null)
        backoff_mode = optional(string, null)
      }))
      rollback = optional(object({
        destination_phase                   = optional(string, null)
        disable_rollback_if_rollout_pending = optional(bool, true)
      }))
    }))
    timed_promote_release_rule = optional(object({
      id                    = optional(string, "timed-promote-release")
      destination_target_id = optional(string, null)
      schedule              = optional(string, null)
      time_zone             = optional(string, null)
      destination_phase     = optional(string, null)
    }))
  }))
  default  = {}
  nullable = true
  validation {
    condition = alltrue([
      for k, v in var.automations :
      !(v.promote_release_rule == null && v.advance_rollout_rule == null && v.repair_rollout_rule == null && v.timed_promote_release_rule == null)
    ])
    error_message = <<EOF
    At least one rule should be defined (promote_release_rule, advance_rollout_rule, repair_rollout_rule or timed_promote_release_rule)
    EOF
  }
}

variable "deploy_policies" {
  description = "Configurations for Deployment Policies in a name => attributes format"
  type = map(object({
    project_id  = optional(string, null)
    region      = optional(string, null)
    description = optional(string, null)
    annotations = optional(map(string))
    labels      = optional(map(string))
    suspended   = optional(bool, false)
    selectors = optional(list(object({
      id     = optional(string, "*")
      type   = optional(string, "DELIVERY_PIPELINE")
      labels = optional(map(string), {})
    })), [{ id = "*", type = "DELIVERY_PIPELINE" }])
    rollout_restrictions = map(object({
      invokers  = optional(list(string), null)
      actions   = optional(list(string), null)
      time_zone = optional(string)
      weekly_windows = optional(list(object({
        start_time = optional(object({
          hours   = optional(string)
          minutes = optional(string)
          seconds = optional(string)
          nanos   = optional(string)
        }))
        end_time = optional(object({
          hours   = optional(string)
          minutes = optional(string)
          seconds = optional(string)
          nanos   = optional(string)
        }))
        days_of_week = optional(list(string))
      })), [])
      one_time_windows = optional(list(object({
        start_date = optional(object({
          year  = optional(string)
          month = optional(string)
          day   = optional(string)
        }))
        start_time = optional(object({
          hours   = optional(string)
          minutes = optional(string)
          seconds = optional(string)
          nanos   = optional(string)
        }))
        end_date = optional(object({
          year  = optional(string)
          month = optional(string)
          day   = optional(string)
        }))
        end_time = optional(object({
          hours   = optional(string)
          minutes = optional(string)
          seconds = optional(string)
          nanos   = optional(string)
        }))
      })), [])
    }))
  }))
  default  = {}
  nullable = true
  validation {
    condition = alltrue([
      for k, v in var.deploy_policies :
      sum([for kk, vv in v.rollout_restrictions : (length(vv.weekly_windows) > 0 || length(vv.one_time_windows) > 0) ? 0 : 1]) == 0
    ])
    error_message = <<EOF
    At least one window should be defined (weekly_windows or one_time_windows)
    EOF
  }
}

variable "description" {
  description = "Cloud Deploy Delivery Pipeline description."
  type        = string
  default     = "Terraform managed."
  validation {
    condition     = length(var.description) <= 255
    error_message = "Description cannot be longer than 255 characters."
  }
}

variable "iam" {
  description = "IAM bindings for Cloud Deploy Delivery Pipeline resource in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "labels" {
  description = "Cloud Deploy Delivery Pipeline resource labels."
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.labels :
      can(regex("^[a-z]([a-z0-9_.-]{0,62}[a-z0-9.])?$", k)) &&
      can(regex("^[a-z0-9]([a-z0-9_.-]{0,62}[a-z0-9.])?$", v))
    ])
    error_message = "Labels must start with a lowercase letter and can only contain lowercase letters, numeric characters, underscores and dashes."
  }
}

variable "name" {
  description = "Cloud Deploy Delivery Pipeline name."
  type        = string
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "Delivery pipeline name must be between 1 and 63 characters and match the regular expression [a-z]([a-z0-9-]{0,61}[a-z0-9])?."
  }
}

variable "project_id" {
  description = "Project id used for resources, if not explicitly specified."
  type        = string
}

variable "region" {
  description = "Region used for resources, if not explicitly specified."
  type        = string
}

variable "suspended" {
  description = "Configuration to suspend a delivery pipeline."
  type        = bool
  default     = false
}

variable "targets" {
  description = "Configuration for new targets associated with the delivery pipeline in a list format. Order of the targets are defined by the order within the list"
  type = list(object({
    name                  = string
    create_target         = optional(bool, true)
    exclude_from_pipeline = optional(bool, false)
    description           = optional(string, null)
    project_id            = optional(string, null)
    region                = optional(string, null)
    profiles              = optional(list(string), [])
    delivery_pipeline_deploy_parameters = optional(list(object({
      values                 = optional(map(string), null)
      matching_target_labels = optional(map(string), null)
    })), [])
    target_deploy_parameters  = optional(map(string), null)
    execution_configs_usages  = optional(list(string))
    execution_configs_timeout = optional(string, null)
    multi_target_target_ids   = optional(list(string))
    require_approval          = optional(bool, false)
    annotations               = optional(map(string))
    labels                    = optional(map(string))
    strategy                  = optional(string, "STANDARD")
    verify                    = optional(bool, false)
    predeploy_actions         = optional(list(string))
    postdeploy_actions        = optional(list(string))
    deployment_percentages    = optional(list(number), [10])
    custom_canary_phase_configs = optional(map(object({
      deployment_percentage = string
      predeploy_actions     = optional(list(string))
      postdeploy_actions    = optional(list(string))
    })), {})
    cloud_run_configs = optional(object({
      project_id                = optional(string, null)
      region                    = optional(string, null)
      automatic_traffic_control = optional(bool, true)
      canary_revision_tags      = optional(list(string), null)
      prior_revision_tags       = optional(list(string), null)
      stable_revision_tags      = optional(list(string), null)
    }))
    iam = optional(map(list(string)), {})
  }))
  default  = []
  nullable = false
  validation {
    condition = alltrue([
      for target in var.targets :
      contains(["STANDARD", "CANARY"], target.strategy)
    ])
    error_message = "The strategy for a target must be either 'STANDARD' or 'CANARY'."
  }
  validation {
    condition = alltrue([
      for target in var.targets :
      target.strategy != "CANARY" || alltrue([
        for i, p in target.deployment_percentages :
        p >= 0 && p < 100 && (i == 0 || p > target.deployment_percentages[i - 1])
      ])
    ])
    error_message = "For canary strategy, deployment percentages must be in ascending order and each percentage must be between 0 and 99."
  }
}
