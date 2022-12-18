org_policies = {
  "iam.disableServiceAccountKeyCreation" = {
    enforce = true
  }
  "iam.disableServiceAccountKeyUpload" = {
    enforce = false
    rules = [
      {
        condition = {
          expression  = "resource.matchTagId(aa, bb)"
          title       = "condition"
          description = "test condition"
          location    = "xxx"
        }
        enforce = true
      }
    ]
  }
}
