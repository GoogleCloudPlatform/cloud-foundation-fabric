automation = {
  federated_identity_pool      = null
  federated_identity_providers = null
  project_id                   = "fast-prod-automation"
  project_number               = 123456
  outputs_bucket               = "test"
  service_accounts = {
    resman   = "ldj-prod-resman-0@fast2-prod-iac-core-0.iam.gserviceaccount.com"
    resman-r = "ldj-prod-resman-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com"
  }
}
billing_account = {
  id = "000000-111111-222222"
}
custom_roles = {
  # organization_iam_admin = "organizations/123456789012/roles/organizationIamAdmin",
  gcve_network_admin              = "organizations/123456789012/roles/gcveNetworkAdmin"
  network_firewall_policies_admin = "organizations/123456789012/roles/networkFirewallPoliciesAdmin"
  ngfw_enterprise_admin           = "organizations/123456789012/roles/ngfwEnterpriseAdmin"
  organization_admin_viewer       = "organizations/123456789012/roles/organizationAdminViewer"
  service_project_network_admin   = "organizations/123456789012/roles/xpnServiceAdmin"
  storage_viewer                  = "organizations/123456789012/roles/storageViewer"
  tenant_network_admin            = "organizations/123456789012/roles/tenantNetworkAdmin"
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
org_policy_tags = {
  key_id   = "tagKeys/281480694641817"
  key_name = "org-policies"
  values = {
    "allowed-policy-member-domains-all" = "tagValues/281480211229353"
    "compute-require-oslogin-false"     = "tagValues/281476830880807"
  }
}
prefix    = "fast2"
root_node = "folders/1234567890"
tenant_configs = {
  s0 = {
    admin_principal  = "group:admins@example0.org"
    descriptive_name = "Simple 0"
  }
  s1 = {
    admin_principal = "group:admins@example1.org"
    billing_account = {
      # implicit no-iam
      id = "102345-102345-102345"
    }
    descriptive_name = "Simple 1"
    cloud_identity = {
      customer_id = "ABCDEFGH"
      domain      = "example1.org"
      id          = 1234567890
    }
    vpc_sc_policy_create = true
  }
  f0 = {
    admin_principal = "group:gcp-organization-admins@fast-0.example.org"
    billing_account = {
      # implicit use of org-level BA with IAM roles
      no_iam = false
    }
    descriptive_name = "Fast 0"
    cloud_identity = {
      domain      = "fast-0.example.org"
      id          = 12345678
      customer_id = "C0C0C0C0"
    }
    fast_config = {
      groups = {
        gcp-network-admins = "gcp-network-admins"
      }
      cicd_config = {
        identity_provider = "github"
        name              = "fast-0/resman"
        type              = "github"
        branch            = "main"
      }
      workload_identity_providers = {
        github = {
          attribute_condition = "attribute.repository_owner==\"fast-0\""
          issuer              = "github"
        }
      }
    }
    vpc_sc_policy_create = true
  }
  f1 = {
    admin_principal = "group:gcp-organization-admins@fast-1.example.org"
    # implicit use of org-level BA without IAM roles
    descriptive_name = "Fast 1"
    cloud_identity = {
      domain      = "fast-1.example.org"
      id          = 1234567
      customer_id = "D0D0D0D0"
    }
    fast_config = {
      groups = {
        gcp-network-admins = "gcp-network-admins"
      }
    }
  }
}
