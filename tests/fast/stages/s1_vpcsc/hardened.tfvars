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
logging = {
  project_number = "1234567890"
  writer_identities = {
    audit-logs           = "serviceAccount:service-org-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
    iam                  = "serviceAccount:service-org-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
    vpc-sc               = "serviceAccount:service-org-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
    workspace-audit-logs = "serviceAccount:o1234567890-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
  }
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
resource_discovery = {
  enabled = false
}
storage_buckets = {
  "iac-0/iac-outputs" = "test"
}
