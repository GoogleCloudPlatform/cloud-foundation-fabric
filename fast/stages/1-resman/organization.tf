/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Organization policies.

locals {
  all_drs_domains = concat(
    [var.organization.customer_id],
    try(local.policy_configs.allowed_policy_member_domains, [])
  )

  policy_configs = (
    var.organization_policy_configs == null
    ? {}
    : var.organization_policy_configs
  )
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  # IAM additive bindings, granted via the restricted Organization Admin custom
  # role assigned in stage 00; they need to be additive to avoid conflicts
  iam_additive = merge(
    {
      "roles/accesscontextmanager.policyAdmin" = [
        module.branch-security-sa.iam_email
      ]
      "roles/compute.orgFirewallPolicyAdmin" = [
        module.branch-network-sa.iam_email
      ]
      "roles/compute.xpnAdmin" = [
        module.branch-network-sa.iam_email
      ]
    },
    local.billing_mode == "org" ? {
      "roles/billing.costsManager" = concat(
        local.branch_optional_sa_lists.pf-dev,
        local.branch_optional_sa_lists.pf-prod
      )
      "roles/billing.user" = concat(
        [
          module.branch-network-sa.iam_email,
          module.branch-security-sa.iam_email,
        ],
        local.branch_optional_sa_lists.dp-dev,
        local.branch_optional_sa_lists.dp-prod,
        local.branch_optional_sa_lists.gke-dev,
        local.branch_optional_sa_lists.gke-prod,
        local.branch_optional_sa_lists.pf-dev,
        local.branch_optional_sa_lists.pf-prod,
      )
    } : {}
  )

  # sample subset of useful organization policies, edit to suit requirements
  org_policies = {
    "iam.allowedPolicyMemberDomains" = {
      rules = [
        { allow = { values = local.all_drs_domains } }
      ]
    }

    #"gcp.resourceLocations" = {
    #   allow = { values = local.allowed_regions }
    # }
    # "iam.workloadIdentityPoolProviders" = {
    #   allow =  {
    #     values = [
    #       for k, v in coalesce(var.automation.federated_identity_providers, {}) :
    #       v.issuer_uri
    #     ]
    #   }
    # }
  }
  org_policies_data_path = "${var.data_dir}/org-policies"

  # do not assign tagViewer or tagUser roles here on tag keys and values as
  # they are managed authoritatively and will break multitenant stages

  tags = {
    (var.tag_names.context) = {
      description = "Resource management context."
      iam         = {}
      values = {
        data       = null
        gke        = null
        networking = null
        sandbox    = null
        security   = null
        teams      = null
      }
    }
    (var.tag_names.environment) = {
      description = "Environment definition."
      iam         = {}
      values = {
        development = null
        production  = null
      }
    }
    (var.tag_names.tenant) = {
      description = "Organization tenant."
    }
  }
}

# organization policy  conditional roles are in the relevant branch files
