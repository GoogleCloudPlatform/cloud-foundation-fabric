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
}
