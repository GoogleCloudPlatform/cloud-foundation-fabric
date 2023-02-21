org_policies = {
  "compute.vmExternalIpAccess" = {
    rules = [{ deny = { all = true } }]
  }
  "iam.allowedPolicyMemberDomains" = {
    rules = [{
      allow = {
        values = ["C0xxxxxxx", "C0yyyyyyy"]
      }
    }]
  }
  "compute.restrictLoadBalancerCreationForTypes" = {
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
      },
      {
        deny = { values = ["in:EXTERNAL"] }
      }
    ]
  }
}
