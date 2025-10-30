automation = {
  outputs_bucket = "test"
}
factories_config = {
  access_levels    = "../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/access-levels"
  egress_policies  = "../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/egress-policies"
  ingress_policies = "../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/ingress-policies"
  perimeters       = "../../../tests/fast/stages/s1_vpcsc/data/vpc-sc/perimeters"
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
