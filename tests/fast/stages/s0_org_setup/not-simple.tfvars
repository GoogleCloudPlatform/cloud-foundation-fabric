factories_config = {
  cicd     = "data-simple/cicd.yaml"
  defaults = "data-simple/defaults.yaml"
}

environments = {
  "dev" = {
    name       = "Development"
    tag_name   = "development"
    is_default = false
  }
  "prod" = {
    name       = "Production"
    tag_name   = "production"
    is_default = true
  }
}