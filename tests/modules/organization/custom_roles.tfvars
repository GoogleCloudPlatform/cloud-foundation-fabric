custom_roles = {
  role_default_description = {
    permissions = ["compute.instances.list"]
  }
  role_empty_description = {
    description = ""
    permissions = ["compute.instances.list"]
  }
  role_with_description = {
    description = "Allows listing compute instances."
    title       = "My custom role"
    permissions = ["compute.instances.list"]
  }
}
