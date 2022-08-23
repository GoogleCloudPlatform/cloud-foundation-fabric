/**
 * Copyright 2022 Google LLC
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
  list_allow = {
    inherit_from_parent = false
    suggested_value     = null
    status              = true
    values              = []
  }
  list_deny = {
    inherit_from_parent = false
    suggested_value     = null
    status              = false
    values              = []
  }
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
    local.billing_org ? {
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
        local.branch_optional_sa_lists.pf-dev,
        local.branch_optional_sa_lists.pf-prod,
      )
    } : {}
  )
  # sample subset of useful organization policies, edit to suit requirements
  policy_boolean = {
    # "constraints/cloudfunctions.requireVPCConnector"              = true
    # "constraints/compute.disableGuestAttributesAccess" = true
    # "constraints/compute.disableInternetNetworkEndpointGroup"     = true
    # "constraints/compute.disableNestedVirtualization"             = true
    # "constraints/compute.disableSerialPortAccess"                 = true
    "constraints/compute.requireOsLogin" = true
    # "constraints/compute.restrictXpnProjectLienRemoval"           = true
    "constraints/compute.skipDefaultNetworkCreation" = true
    # "constraints/compute.setNewProjectDefaultToZonalDNSOnly"      = true
    "constraints/iam.automaticIamGrantsForDefaultServiceAccounts" = true
    "constraints/iam.disableServiceAccountKeyCreation"            = true
    # "constraints/iam.disableServiceAccountKeyUpload"              = true
    "constraints/sql.restrictPublicIp"             = true
    "constraints/sql.restrictAuthorizedNetworks"   = true
    "constraints/storage.uniformBucketLevelAccess" = true
  }
  policy_list = {
    # "constraints/cloudfunctions.allowedIngressSettings" = merge(
    #   local.list_allow, { values = ["is:ALLOW_INTERNAL_ONLY"] }
    # )
    # "constraints/cloudfunctions.allowedVpcConnectorEgressSettings" = merge(
    #   local.list_allow, { values = ["is:PRIVATE_RANGES_ONLY"] }
    # )
    "constraints/compute.restrictLoadBalancerCreationForTypes" = merge(
      local.list_allow, { values = ["in:INTERNAL"] }
    )
    "constraints/compute.vmExternalIpAccess" = local.list_deny
    "constraints/iam.allowedPolicyMemberDomains" = merge(
      local.list_allow, {
        values = concat(
          [var.organization.customer_id],
          try(local.policy_configs.allowed_policy_member_domains, [])
        )
    })
    "constraints/run.allowedIngress" = merge(
      local.list_allow, { values = ["is:internal"] }
    )
    # "constraints/run.allowedVPCEgress" = merge(
    #   local.list_allow, { values = ["is:private-ranges-only"] }
    # )
    # "constraints/compute.restrictCloudNATUsage"                      = local.list_deny
    # "constraints/compute.restrictDedicatedInterconnectUsage"         = local.list_deny
    # "constraints/compute.restrictPartnerInterconnectUsage"           = local.list_deny
    # "constraints/compute.restrictProtocolForwardingCreationForTypes" = local.list_deny
    # "constraints/compute.restrictSharedVpcHostProjects"              = local.list_deny
    # "constraints/compute.restrictSharedVpcSubnetworks"               = local.list_deny
    # "constraints/compute.restrictVpcPeering" = local.list_deny
    # "constraints/compute.restrictVpnPeerIPs" = local.list_deny
    # "constraints/compute.vmCanIpForward"     = local.list_deny
    # "constraints/gcp.resourceLocations" = {
    #   inherit_from_parent = false
    #   suggested_value     = null
    #   status              = true
    #   values              = local.allowed_regions
    # }
    # https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#restrict
    # "constraints/iam.workloadIdentityPoolProviders" = merge(
    #   local.list_allow, { values = [
    #     for k, v in coalesce(var.automation.federated_identity_providers, {}) :
    #     v.issuer_uri
    #   ] }
    # )
    # "constraints/iam.workloadIdentityPoolAwsAccounts" = merge(
    #   local.list_allow, { values = [
    #
    #   ] }
    # )
  }
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
  }
}

# organization policy admin role assigned with a condition on tags

resource "google_organization_iam_member" "org_policy_admin_dp" {
  for_each = !var.fast_features.data_platform ? {} : {
    data-dev  = ["data", "development", module.branch-dp-dev-sa.0.iam_email]
    data-prod = ["data", "production", module.branch-dp-prod-sa.0.iam_email]
  }
  org_id = var.organization.id
  role   = "roles/orgpolicy.policyAdmin"
  member = each.value.2
  condition {
    title       = "org_policy_tag_dp_scoped"
    description = "Org policy tag scoped grant for ${each.value.0}/${each.value.1}."
    expression  = <<-END
    resource.matchTag('${var.organization.id}/${var.tag_names.context}', '${each.value.0}')
    &&
    resource.matchTag('${var.organization.id}/${var.tag_names.environment}', '${each.value.1}')
    END
  }
}

resource "google_organization_iam_member" "org_policy_admin_pf" {
  for_each = !var.fast_features.project_factory ? {} : {
    pf-dev  = ["teams", "development", module.branch-pf-dev-sa.0.iam_email]
    pf-prod = ["teams", "production", module.branch-pf-prod-sa.0.iam_email]
  }
  org_id = var.organization.id
  role   = "roles/orgpolicy.policyAdmin"
  member = each.value.2
  condition {
    title       = "org_policy_tag_pf_scoped"
    description = "Org policy tag scoped grant for ${each.value.0}/${each.value.1}."
    expression  = <<-END
    resource.matchTag('${var.organization.id}/${var.tag_names.context}', '${each.value.0}')
    &&
    resource.matchTag('${var.organization.id}/${var.tag_names.environment}', '${each.value.1}')
    END
  }
}
