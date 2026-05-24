# tfdoc:file:description IAM bindings.

locals {
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
}

resource "google_billing_account_iam_binding" "authoritative" {
  for_each           = local.iam
  billing_account_id = var.id
  role               = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for v in each.value : lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_billing_account_iam_binding" "bindings" {
  for_each           = var.iam_bindings
  billing_account_id = var.id
  role               = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_billing_account_iam_member" "bindings" {
  for_each           = var.iam_bindings_additive
  billing_account_id = var.id
  role               = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member             = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}
