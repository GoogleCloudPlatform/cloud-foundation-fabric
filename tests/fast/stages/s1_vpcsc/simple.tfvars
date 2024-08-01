automation = {
  outputs_bucket = "test"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
factories_config = {
  access_levels    = "../../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/access-levels"
  egress_policies  = "../../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/egress-policies"
  ingress_policies = "../../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/ingress-policies"
}
perimeters = {
  default = {
    access_levels    = ["geo_it", "identity_me"]
    egress_policies  = ["test"]
    ingress_policies = ["test"]
    dry_run          = true
    resources = [
      "projects/1234567890"
    ]
  }
}
resource_discovery = {
  enabled = false
}
