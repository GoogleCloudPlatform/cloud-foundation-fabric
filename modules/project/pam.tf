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

locals {
  _pam_entitlements_factory_path = pathexpand(coalesce(var.factories_config.pam_entitlements, "-"))
  _pam_entitlements_factory_data_raw = merge([
    for f in try(fileset(local._pam_entitlements_factory_path, "*.yaml"), []) :
    yamldecode(templatefile("${local._pam_entitlements_factory_path}/${f}", var.context))
  ]...)
  # simulate applying defaults to data coming from yaml files
  _pam_entitlements_factory_data = {
    for k, v in local._pam_entitlements_factory_data_raw : k => {
      max_request_duration = v.max_request_duration
      eligible_users       = v.eligible_users
      privileged_access = [
        for pa in v.privileged_access : {
          role      = pa.role
          condition = try(pa.condition, null)
        }
      ]
      requester_justification_config = can(v.requester_justification_config) ? {
        not_mandatory = try(v.requester_justification_config.not_mandatory, true)
        unstructured  = try(v.requester_justification_config.unstructured, false)
        } : {
        not_mandatory = false
        unstructured  = true
      }
      manual_approvals = can(v.manual_approvals) ? {
        require_approver_justification = v.manual_approvals.require_approver_justification
        steps = [
          for s in v.manual_approvals.steps : {
            approvers                 = s.approvers
            approvals_needed          = try(s.approvals_needed, 1)
            approver_email_recipients = try(s.approver_email_recipients, null)
          }
        ]
      } : null
      additional_notification_targets = can(v.additional_notification_targets) ? {
        admin_email_recipients     = try(v.additional_notification_targets.admin_email_recipients, null)
        requester_email_recipients = try(v.additional_notification_targets.requester_email_recipients, null)
      } : null
    }
  }
  pam_entitlements = merge(
    local._pam_entitlements_factory_data,
    var.pam_entitlements
  )
}

resource "google_privileged_access_manager_entitlement" "default" {
  for_each = local.pam_entitlements

  parent               = "projects/${local.project_id}"
  location             = "global"
  entitlement_id       = each.key
  max_request_duration = each.value.max_request_duration

  eligible_users {
    principals = [
      for u in each.value.eligible_users : lookup(local.ctx.iam_principals, u, u)
    ]
  }

  privileged_access {
    gcp_iam_access {
      resource_type = "cloudresourcemanager.googleapis.com/Project"
      resource      = "//cloudresourcemanager.googleapis.com/projects/${local.project.project_id}"
      dynamic "role_bindings" {
        for_each = each.value.privileged_access
        iterator = binding
        content {
          role = lookup(local.ctx.custom_roles, binding.value.role, binding.value.role)
          condition_expression = binding.value.condition == null ? null : templatestring(
            binding.value.condition, var.context.condition_vars
          )
        }
      }
    }
  }

  requester_justification_config {
    dynamic "not_mandatory" {
      for_each = each.value.requester_justification_config.not_mandatory ? [""] : []
      content {}
    }
    dynamic "unstructured" {
      for_each = each.value.requester_justification_config.unstructured ? [""] : []
      content {}
    }
  }

  dynamic "approval_workflow" {
    for_each = each.value.manual_approvals == null ? [] : [""]
    content {
      manual_approvals {
        require_approver_justification = each.value.manual_approvals.require_approver_justification
        dynamic "steps" {
          for_each = each.value.manual_approvals.steps
          iterator = step
          content {
            approvers {
              principals = [
                for a in step.value.approvers : lookup(local.ctx.iam_principals, a, a)
              ]
            }

            approvals_needed          = step.value.approvals_needed
            approver_email_recipients = step.value.approver_email_recipients
          }
        }
      }
    }
  }

  dynamic "additional_notification_targets" {
    for_each = each.value.additional_notification_targets == null ? [] : [""]
    content {
      admin_email_recipients     = each.value.additional_notification_targets.admin_email_recipients
      requester_email_recipients = each.value.additional_notification_targets.requester_email_recipients
    }
  }
  depends_on = [
    google_project_service.project_services,
    google_project_iam_binding.authoritative,
    google_project_iam_binding.bindings,
    google_project_iam_member.bindings
  ]
}
