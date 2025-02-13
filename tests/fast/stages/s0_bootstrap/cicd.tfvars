billing_account = {
  id = "000000-111111-222222"
}
essential_contacts = "gcp-organization-admins@fast.example.com"
groups = {
  gcp-support = "group:gcp-support@example.com"
}
org_policies_config = {
  import_defaults = false
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
outputs_location = "/fast-config"
prefix           = "fast"
cicd_config = {
  bootstrap = {
    identity_provider = "gh-test"
    repository = {
      name   = "fast/bootstrap"
      type   = "github"
      branch = "main"
    }
  }
  resman = {
    identity_provider = "gl-test"
    repository = {
      name   = "fast/resource_management"
      type   = "gitlab"
      branch = "main"
    }
  }
}
fast_addon = {
  resman-tenants = {
    parent_stage = "1-resman"
    cicd_config = {
      identity_provider = "gh-test"
      repository = {
        name   = "fast/tenants"
        type   = "github"
        branch = "main"
      }
    }
  }
}
workload_identity_providers = {
  gh-test = {
    attribute_condition = "attribute.repository_owner==\"fast\""
    issuer              = "github"
  }
  gl-test = {
    attribute_condition = "attribute.namespace_path==\"fast\""
    issuer              = "gitlab"
  }
}
