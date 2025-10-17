# /**
#  * Copyright 2025 Google LLC
#  *
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *
#  *      http://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  */

resource "google_privileged_access_manager_entitlement" "default" {
  for_each = var.pam_entitlements

  parent               = local.folder_id
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
      resource_type = "cloudresourcemanager.googleapis.com/Folder"
      resource      = "//cloudresourcemanager.googleapis.com/${local.folder_id}"
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
            approver_email_recipients = step.value.aprover_email_recipients
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
}
