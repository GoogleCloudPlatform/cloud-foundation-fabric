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

# simple mapping between principal prefixes used in IAM Allow Policies and corresponding templates in IAM Deny policies
# Only conversion for a user, a group and a service account (or service agent) is supported, more complicated use cases
# (eg. domain -> customerId) need to be addressed via entries in iam_principals block inside defaults.yaml
locals {
  deny_policy_principals_templates = {
    "group"          = "principalSet://goog/group/%s"
    "serviceAccount" = "principal://iam.googleapis.com/projects/-/serviceAccounts/%s"
    "user"           = "principal://goog/subject/%s"
  }
}

resource "google_iam_deny_policy" "default" {
  for_each     = var.iam_deny_policies
  parent       = urlencode("cloudresourcemanager.googleapis.com/organizations/${local.organization_id_numeric}")
  name         = each.key
  display_name = each.value.display_name
  dynamic "rules" {
    for_each = each.value.rules
    iterator = rule
    content {
      description = rule.value.description
      deny_rule {
        denied_principals = [
          for pf in [
            # standard FAST interpolation first
            for p in rule.value.denied_principals : lookup(local.ctx.iam_principals, p, p)
          ] : # formatting (based on the principal's prefix) comes as the next step
          contains(keys(local.deny_policy_principals_templates), split(":", pf)[0]) ?
          # If YES: Format it using the template found
          format(local.deny_policy_principals_templates[split(":", pf)[0]], split(":", pf)[1]) :
          # If NO: Fall back safely to the original raw string without breaking format()
          pf
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
          for pf in [
            # standard FAST interpolation first
            for p in rule.value.exception_principals : lookup(local.ctx.iam_principals, p, p)
          ] : # formatting (based on the principal's prefix) comes as the next step
          contains(keys(local.deny_policy_principals_templates), split(":", pf)[0]) ?
          # If YES: Format it using the template found
          format(local.deny_policy_principals_templates[split(":", pf)[0]], split(":", pf)[1]) :
          # If NO: Fall back safely to the original raw string without breaking format()
          pf
        ]
        exception_permissions = rule.value.exception_permissions
      }
    }
  }
}
