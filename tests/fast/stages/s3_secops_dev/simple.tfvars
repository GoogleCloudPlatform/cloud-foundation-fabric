billing_account = {
  id = "012345-67890A-BCDEF0",
}
project_reuse = null
folder_ids = {
  "secops-dev" = "folders/123456789"
}
tenant_config = {
  customer_id = "xxxxxx-xxxxxx-xxxxxx"
  region      = "europe"
}
secops_project_ids = {
  dev = "fast-dev-secops-0"
}
iam_default = {
  viewers = ["gcp-secops-admins@fast.example.com"]
}
iam = {
  "user:test@fast.example.com" = {
    roles  = ["roles/chronicle.editor"]
    scopes = ["gscope"]
  }
}
workspace_integration_config = {
  delegated_user        = "secops-feed@fast.example.com"
  workspace_customer_id = "C121212"
}
data_rbac_config = {
  labels = {
    google = {
      description = "Google logs"
      label_id    = "google"
      udm_query   = "principal.hostname=\"google.com\""
    }
  }
  scopes = {
    google = {
      description = "Google logs"
      scope_id    = "gscope"
      allowed_data_access_labels = [{
        data_access_label = "google"
      }]
    }
  }
}
