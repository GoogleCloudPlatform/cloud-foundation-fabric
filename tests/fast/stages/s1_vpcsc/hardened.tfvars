automation = {
  outputs_bucket = "test"
}
factories_config = {
  dataset = "datasets/hardened"
}
iam_principals = {
  "service_agents/org/csc-hpsa"            = "serviceAccount:service-org-1234567890@gcp-sa-csc-hpsa.iam.gserviceaccount.com"
  "service_agents/org/ktd-hpsa"            = "serviceAccount:service-org-1234567890@gcp-sa-ktd-hpsa.iam.gserviceaccount.com"
  "service_agents/org/security-center-api" = "serviceAccount:service-org-1234567890@security-center-api.iam.gserviceaccount.com"
}
logging_sinks = {
  audit-logs = {
    bigquery_options   = []
    description        = "audit-logs (Terraform-managed)."
    destination        = "logging.googleapis.com/projects/ft0-prod-audit-logs-0/locations/global/buckets/audit-logs"
    disabled           = false
    exclusions         = []
    filter             = ""
    id                 = "organizations/1234567890/sinks/audit-logs"
    include_children   = true
    intercept_children = false
    name               = "audit-logs"
    org_id             = "529325294915"
    project_id         = "ft0-prod-audit-logs-0"
    writer_identity    = "serviceAccount:service-org-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
  }
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
project_ids = {
  log-0 = "ft0-prod-audit-logs-0"
}
project_numbers = {
  log-0 = 1122334455
}
resource_discovery = {
  enabled = false
}
storage_buckets = {
  "iac-0/iac-outputs" = "test"
}
