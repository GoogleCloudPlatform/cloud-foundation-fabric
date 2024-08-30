automation = {
  federated_identity_pool      = null
  federated_identity_providers = null
  project_id                   = "fast-prod-automation"
  project_number               = 123456
  outputs_bucket               = "test"
  service_accounts = {
    resman-r = "ldj-prod-resman-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com"
  }
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  # organization_iam_admin = "organizations/123456789012/roles/organizationIamAdmin",
  gcve_network_admin               = "organizations/123456789012/roles/gcveNetworkAdmin"
  network_firewall_policies_admin  = "organizations/123456789012/roles/networkFirewallPoliciesAdmin"
  network_firewall_policies_viewer = "organizations/123456789012/roles/networkFirewallPoliciesViewer"
  ngfw_enterprise_admin            = "organizations/123456789012/roles/ngfwEnterpriseAdmin"
  ngfw_enterprise_viewer           = "organizations/123456789012/roles/ngfwEnterpriseViewer"
  organization_admin_viewer        = "organizations/123456789012/roles/organizationAdminViewer"
  service_project_network_admin    = "organizations/123456789012/roles/xpnServiceAdmin"
  storage_viewer                   = "organizations/123456789012/roles/storageViewer"
}
factories_config = {
  checklist_data = "checklist-data.json"
}
groups = {
  gcp-billing-admins      = "gcp-billing-admins",
  gcp-devops              = "gcp-devops",
  gcp-network-admins      = "gcp-vpc-network-admins",
  gcp-organization-admins = "gcp-organization-admins",
  gcp-security-admins     = "gcp-security-admins",
  gcp-support             = "gcp-support"
}
logging = {
  project_id = "fast-prod-log-audit-0"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
