locals {
  _custom_roles_files = [
    for f in try(fileset(var.factories_config.custom_roles, "*.yaml"), []) :
    "${var.factories_config.custom_roles}/${f}"
  ]

  _custom_roles_list = flatten([for f in local._custom_roles_files :
    [for role_name, permissions in yamldecode(file("${f}")) : {
      role_name   = role_name
      permissions = permissions
    }]
  ])

  _factory_custom_roles = { for r in local._custom_roles_list :
    r.role_name => r.permissions
  }

  _iam_bindings_files = [
    for f in try(fileset(var.factories_config.bindings, "*.yaml"), []) :
    "${var.factories_config.bindings}/${f}"
  ]

  _iam_bindings_list = flatten([for f in local._iam_bindings_files :
    [for binding_name, data in yamldecode(file("${f}")) : {
      binding_name = binding_name
      data = {
        members = data.members
        role    = try(google_project_iam_custom_role.roles[data.role].name, data.role)
        condition = {
          title       = data.condition.title
          expression  = data.condition.expression
          description = try(data.condition.description, null)
        }
      }
    }]
  ])

  _factory_iam_bindings = { for b in local._iam_bindings_list :
    b.binding_name => b.data
  }

  _iam_bindings_additive_files = [
    for f in try(fileset(var.factories_config.bindings_additive, "*.yaml"), []) :
    "${var.factories_config.bindings}/${f}"
  ]

  _iam_bindings_additive_list = flatten([for f in local._iam_bindings_additive_files :
    [for binding_name, data in yamldecode(file("${f}")) : {
      binding_name = binding_name
      data = {
        members = data.members
        role    = try(google_project_iam_custom_role.roles[data.role].name, data.role)
        condition = {
          title       = data.condition.title
          expression  = data.condition.expression
          description = try(data.condition.description, null)
        }
      }
    }]
  ])

  _factory_iam_bindings_additive = { for b in local._iam_bindings_additive_list :
    b.binding_name => b.data
  }

  custom_roles = merge(
    var.custom_roles,
    local._factory_custom_roles
  )

  iam_bindings = merge(
    local._factory_iam_bindings,
    var.iam_bindings
  )

  iam_bindings_additive = merge(
    local._factory_iam_bindings_additive,
    var.iam_bindings
  )
}
