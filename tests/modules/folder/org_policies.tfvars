parent = "organizations/12345678"
name   = "folder-a"
org_policies = {
  "iam.disableServiceAccountKeyCreation" = {
    rules = [{ enforce = true }]
  }
  "iam.disableServiceAccountKeyUpload" = {
    rules = [
      {
        condition = {
          expression  = "resource.matchTagId(aa, bb)"
          title       = "condition"
          description = "test condition"
          location    = "xxx"
        }
        enforce = true
      },
      {
        enforce = false
      }
    ]
  }
  "compute.vmExternalIpAccess" = {
    rules = [{ deny = { all = true } }]
  }
  "iam.allowedPolicyMemberDomains" = {
    inherit_from_parent = true
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
