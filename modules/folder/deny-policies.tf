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

# tfdoc:file:description IAM Deny policies.

resource "google_iam_deny_policy" "default" {
  for_each     = var.iam_deny_policies
  parent       = urlencode("cloudresourcemanager.googleapis.com/folders/${local.folder_number}")
  name         = each.key
  display_name = each.value.display_name
  dynamic "rules" {
    for_each = each.value.rules
    iterator = rule
    content {
      description = rule.value.description
      deny_rule {
        denied_principals = [
          for p in rule.value.denied_principals : lookup(local.ctx.iam_principals, p, p)
        ]
        dynamic "denial_condition" {
          for_each = rule.value.denial_condition == null ? [] : [""]
          content {
            title = rule.value.denial_condition.title
            expression = templatestring(
              rule.value.denial_condition.expression, var.context.condition_vars
            )
            description = rule.value.denial_condition.description
            location    = rule.value.denial_condition.location
          }
        }
        denied_permissions = rule.value.denied_permissions
        exception_principals = [
          for p in rule.value.exception_principals : lookup(local.ctx.iam_principals, p, p)
        ]
        exception_permissions = rule.value.exception_permissions
      }
    }
  }
}
