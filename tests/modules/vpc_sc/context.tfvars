access_policy = "12345678"
context = {
  folder_ids = {
    test = "folders/1234567890"
  }
  identity_sets = {
    test = ["user:one@example.com", "user:two@example.com"]
  }
  organization_ids = {
    test = "organizations/366118655033"
  }
  project_numbers = {
    test-0 = 111111
    test-1 = 222222
  }
  psc_endpoints = {
    test = "//compute.googleapis.com/projects/test-net/global/forwardingRules/psc-apis"
  }
  resource_sets = {
    test = ["projects/321", "projects/654"]
  }
  service_sets = {
    test = ["compute.googleapis.com", "container.googleapis.com"]
  }
}
factories_config = {
  access_levels    = "data/access-levels"
  egress_policies  = "data/egress-policies"
  ingress_policies = "data/ingress-policies"
  perimeters       = "data/perimeters"
}
