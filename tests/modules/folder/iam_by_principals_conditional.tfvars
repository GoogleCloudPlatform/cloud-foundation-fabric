parent = "organizations/12345678"
name   = "folder-a"
iam_by_principals_conditional = {
  "user:one@example.com" = {
    roles = ["roles/owner", "roles/viewer"]
    condition = {
      title       = "expires_after_2024_12_31"
      description = "Expiring at midnight of 2024-12-31"
      expression  = "request.time < timestamp(\"2025-01-01T00:00:00Z\")"
    }
  }
}
