org_policies = {
  "compute.vmExternalIpAccess" = {
    deny = { all = true }
  }
  "iam.allowedPolicyMemberDomains" = {
    inherit_from_parent = true
    allow = {
      values = ["C0xxxxxxx", "C0yyyyyyy"]
    }
  }
  "compute.restrictLoadBalancerCreationForTypes" = {
    deny = { values = ["in:EXTERNAL"] }
    rules = [
      {
        condition = {
          expression  = "resource.matchTagId(aa, bb)"
          title       = "condition"
          description = "test condition"
          location    = "xxx"
        }
        allow = {
          values = ["EXTERNAL_1"]
        }
      },
      {
        condition = {
          expression  = "resource.matchTagId(cc, dd)"
          title       = "condition2"
          description = "test condition2"
          location    = "xxx"
        }
        allow = {
          all = true
        }
      }
    ]
  }
}
