resource "google_iam_deny_policy" "default" {
  for_each     = var.iam_deny_policies == null ? {} : var.iam_deny_policies
  parent       = urlencode("cloudresourcemanager.googleapis.com/projects/${local.project.project_id}")
  name         = each.key
  display_name = each.value.display_name
  dynamic "rules" {
    for_each = each.value.rules
    iterator = rule
    content {
      description = rule.value.description
      deny_rule {
        denied_principals = rule.value.denied_principals
        dynamic "denial_condition" {
          for_each = rule.value.denial_condition == null ? [] : [""]
          content {
            title       = rule.value.denial_condition.title
            expression  = templatestring(rule.value.denial_condition.expression, var.context.condition_vars)
            description = rule.value.denial_condition.description
            location    = rule.value.denial_condition.location
          }
        }
        denied_permissions    = rule.value.denied_permissions
        exception_principals  = rule.value.exception_principals
        exception_permissions = rule.value.exception_permissions
      }
    }
  }
}
