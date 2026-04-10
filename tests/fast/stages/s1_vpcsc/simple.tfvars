automation = {
  outputs_bucket = "test"
}
factories_config = {
  paths = {
    access_levels    = "./data-simple/access-levels"
    egress_policies  = "./data-simple/egress-policies"
    ingress_policies = "./data-simple/ingress-policies"
  }
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
  iam = {
    bigquery_options   = []
    description        = "iam (Terraform-managed)."
    destination        = "logging.googleapis.com/projects/ft0-prod-audit-logs-0/locations/global/buckets/iam"
    disabled           = false
    exclusions         = []
    filter             = ""
    id                 = "organizations/1234567890/sinks/iam"
    include_children   = true
    intercept_children = false
    name               = "iam"
    org_id             = "529325294915"
    project_id         = "ft0-prod-audit-logs-0"
    writer_identity    = "serviceAccount:service-org-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
  }
  vpc-sc = {
    bigquery_options   = []
    description        = "vpc-sc (Terraform-managed)."
    destination        = "logging.googleapis.com/projects/ft0-prod-audit-logs-0/locations/global/buckets/vpc-sc"
    disabled           = false
    exclusions         = []
    filter             = ""
    id                 = "organizations/1234567890/sinks/vpc-sc"
    include_children   = true
    intercept_children = false
    name               = "vpc-sc"
    org_id             = "529325294915"
    project_id         = "ft0-prod-audit-logs-0"
    writer_identity    = "serviceAccount:service-org-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
  }
  worksapce = {
    bigquery_options   = []
    description        = "worksapce (Terraform-managed)."
    destination        = "logging.googleapis.com/projects/ft0-prod-audit-logs-0/locations/global/buckets/worksapce"
    disabled           = false
    exclusions         = []
    filter             = ""
    id                 = "organizations/1234567890/sinks/worksapce"
    include_children   = true
    intercept_children = false
    name               = "worksapce"
    org_id             = "529325294915"
    project_id         = "ft0-prod-audit-logs-0"
    writer_identity    = "serviceAccount:o1234567890-1234567890@gcp-sa-logging.iam.gserviceaccount.com"
  }
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
perimeters = {
  default = {
    use_explicit_dry_run_spec = true
    spec = {
      access_levels       = ["$access_levels:geo_it", "$access_levels:identity_me"]
      egress_policies     = ["$egress_policies:test"]
      ingress_policies    = ["$ingress_policies:fast-org-log-sinks", "$ingress_policies:test"]
      restricted_services = ["$service_sets:restricted_services"]
      resources = [
        "projects/1234567890"
      ]
    }
  }
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
