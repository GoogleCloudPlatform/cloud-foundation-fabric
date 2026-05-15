resource "google_iam_deny_policy" "default" {
  for_each     = var.iam_deny_policies == null ? {} : var.iam_deny_policies
  parent       = urlencode("cloudresourcemanager.googleapis.com/organizations/${local.organization_id_numeric}")
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
          for_each = try(rule.value.denial_condition, null) == null ? [] : [""]
          content {
            title       = try(rule.value.denial_condition.title, null)
            expression  = rule.value.denial_condition.expression
            description = try(rule.value.denial_condition.description, null)
            location    = try(rule.value.denial_condition.location, null)
          }
        }
        denied_permissions    = rule.value.denied_permissions
        exception_principals  = try(rule.value.exception_principals, [])
        exception_permissions = try(rule.value.exception_permissions, [])
      }
    }
  }
}
