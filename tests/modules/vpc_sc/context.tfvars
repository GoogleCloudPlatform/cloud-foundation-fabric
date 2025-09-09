access_policy = "12345678"
context = {
  identity_sets = {
    test = ["user:one@example.com", "user:two@example.com"]
  }
  project_numbers = {
    test-0 = 111111
    test-1 = 222222
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
