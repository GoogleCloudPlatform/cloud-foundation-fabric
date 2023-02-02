automation = {
  federated_identity_pools     = null
  federated_identity_providers = null
  project_id                   = "tn0-prod-automation-0"
  project_number               = 123456
  outputs_bucket               = "tn0-prod-automation-0"
  service_accounts = {
    networking = "foo-tn0-net-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    resman     = "foo-tn0-resman-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    security   = "foo-tn0-sec-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    dp-dev     = "foo-tn0-dp-dev-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    dp-prod    = "foo-tn0-dp-prod-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    gke-dev    = "foo-tn0-gke-dev-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    gke-prod   = "foo-tn0-gke-prod-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    pf-dev     = "foo-tn0-pf-dev-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    pf-prod    = "foo-tn0-pf-prod-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    sandbox    = "foo-tn0-sandbox-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
    teams      = "foo-tn0-teams-0@foo-tn0-prod-iac-core-0.iam.gserviceaccount.com"
  }
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  # organization_iam_admin = "organizations/123456789012/roles/organizationIamAdmin",
  service_project_network_admin = "organizations/123456789012/roles/xpnServiceAdmin"
}
fast_features = {
  data_platform   = true
  gke             = true
  project_factory = true
  sandbox         = true
  teams           = true
}
groups = {
  gcp-devops          = "gcp-devops",
  gcp-network-admins  = "gcp-network-admins",
  gcp-security-admins = "gcp-security-admins",
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix     = "foo-tn0"
root_node  = "folders/1234567890"
short_name = "tn0"
tags = {
  keys = {
    context     = "tagKeys/1234567890"
    environment = "tagKeys/4567890123"
    tenant      = "tagKeys/7890123456"
  }
  names = {
    context     = "context"
    environment = "environment"
    tenant      = "tenant"
  }
  values = {
    "context/data" : "tagValues/1234567890",
    "context/gke" : "tagValues/1234567890",
    "context/networking" : "tagValues/1234567890",
    "context/sandbox" : "tagValues/1234567890",
    "context/security" : "tagValues/1234567890",
    "context/teams" : "tagValues/1234567890",
    "environment/development" : "tagValues/1234567890",
    "environment/production" : "tagValues/1234567890"
  }
}
test_skip_data_sources = true
