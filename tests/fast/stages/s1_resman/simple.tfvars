# globals

billing_account = {
  id = "000000-111111-222222"
}
groups = {
  gcp-billing-admins      = "gcp-billing-admins",
  gcp-devops              = "gcp-devops",
  gcp-network-admins      = "gcp-vpc-network-admins",
  gcp-organization-admins = "gcp-organization-admins",
  gcp-security-admins     = "gcp-security-admins",
  gcp-support             = "gcp-support"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"

# stage 0

automation = {
  federated_identity_pool = "projects/1234567890/locations/global/workloadIdentityPools/ldj-bootstrap"
  federated_identity_providers = {
    gh-test = {
      audiences = [
        "https://iam.googleapis.com/projects/1234567890/locations/global/workloadIdentityPools/ldj-bootstrap/providers/ldj-bootstrap-github-ludomagno"
      ],
      issuer           = "github",
      issuer_uri       = "https://token.actions.githubusercontent.com"
      name             = "projects/1234567890/locations/global/workloadIdentityPools/ldj-bootstrap/providers/ldj-bootstrap-github-ludomagno"
      principal_branch = "principalSet://iam.googleapis.com/%s/attribute.fast_sub/repo:%s:ref:refs/heads/%s"
      principal_repo   = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
    gl-test = {
      audiences = [
        "https://iam.googleapis.com/projects/1234567890/locations/global/workloadIdentityPools/ldj-bootstrap/providers/ldj-bootstrap-gitlab-ludomagno"
      ]
      issuer           = "gitlab"
      issuer_uri       = "https://gitlab.com"
      name             = "projects/1234567890/locations/global/workloadIdentityPools/ldj-bootstrap/providers/ldj-bootstrap-gitlab-ludomagno"
      principal_branch = "principalSet://iam.googleapis.com/%s/attribute.sub/project_path:%s:ref_type:branch:ref:%s"
      principal_repo   = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
  },
  outputs_bucket = "fast2-prod-iac-core-outputs"
  project_id     = "fast2-prod-automation"
  project_number = 123456
  service_accounts = {
    resman-r = "fast2-prod-resman-0r@fast2-prod-iac-core-0.iam.gserviceaccount.com"
  }
}
custom_roles = {
  # organization_iam_admin = "organizations/123456789012/roles/organizationIamAdmin",
  billing_viewer                  = "organizations/123456789012/roles/billingViewer"
  gcve_network_admin              = "organizations/123456789012/roles/gcveNetworkAdmin"
  gcve_network_viewer             = "organizations/123456789012/roles/gcveNetworkViewer"
  network_firewall_policies_admin = "organizations/123456789012/roles/networkFirewallPoliciesAdmin"
  ngfw_enterprise_admin           = "organizations/123456789012/roles/ngfwEnterpriseAdmin"
  ngfw_enterprise_viewer          = "organizations/123456789012/roles/ngfwEnterpriseViewer"
  organization_admin_viewer       = "organizations/123456789012/roles/organizationAdminViewer"
  project_iam_viewer              = "organizations/123456789012/roles/projectIamViewer"
  service_project_network_admin   = "organizations/123456789012/roles/xpnServiceAdmin"
  storage_viewer                  = "organizations/123456789012/roles/storageViewer"
}
environments = {
  dev = {
    is_default = false
    name       = "Development"
    tag_name   = "development"
  }
  prod = {
    is_default = true
    name       = "Production"
    tag_name   = "production"
  }
}
logging = {
  project_id = "fast-prod-log-audit-0"
}

# stage variables

fast_stage_2 = {
  networking = {
    cicd_config = {
      identity_provider = "gh-test"
      repository = {
        branch = "main"
        name   = "test/00-networking"
        type   = "github"
      }
    }
  }
  security = {
    cicd_config = {
      identity_provider = "gl-test"
      repository = {
        name = "test/00-security"
        type = "gitlab"
      }
    }
  }
}
tags = {
  context = {
    values = {
      data-platform = {}
      gcve          = {}
      gke           = {}
      nsec          = {}
      sandbox       = {}
    }
  }
  environment = {
    values = {
      development = {
        iam = {
          "roles/resourcemanager.tagUser"   = ["project-factory-dev"]
          "roles/resourcemanager.tagViewer" = ["project-factory-dev-r"]
        }
      }
      production = {
        iam = {
          "roles/resourcemanager.tagUser"   = ["project-factory-prod"]
          "roles/resourcemanager.tagViewer" = ["project-factory-prod-r"]
        }
      }
    }
  }
}
top_level_folders = {
  tenants = {
    name = "Tenants"
    automation = {
      enable = false
    }
    iam_by_principals = {}
  }
}
