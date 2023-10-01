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

# tfdoc:file:description Organization-level IAM.

locals {
  # reassemble logical bindings into the formats expected by the module
  _iam_bindings = merge(
    local.iam_domain_bindings,
    local.iam_sa_bindings,
    local.iam_user_bootstrap_bindings,
    {
      for k, v in local.iam_group_bindings : "group:${k}" => {
        authoritative = []
        additive      = v.additive
      }
    }
  )
  _iam_bindings_auth = flatten([
    for member, data in local._iam_bindings : [
      for role in data.authoritative : {
        member = member
        role   = role
      }
    ]
  ])
  _iam_bindings_add = flatten([
    for member, data in local._iam_bindings : [
      for role in data.additive : {
        member = member
        role   = role
      }
    ]
  ])
  drs_domains = concat(
    [var.organization.customer_id],
    var.org_policies_config.constraints.allowed_policy_member_domains
  )
  drs_tag_name = "${var.organization.id}/${var.org_policies_config.tag_name}"
  group_iam = {
    for k, v in local.iam_group_bindings : k => v.authoritative
  }
  iam = merge(
    {
      for r in local.iam_delete_roles : r => []
    },
    {
      for b in local._iam_bindings_auth : b.role => b.member...
    }
  )
  iam_bindings_additive = {
    for b in local._iam_bindings_add : "${b.role}-${b.member}" => {
      member = b.member
      role   = b.role
    }
  }
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  # human (groups) IAM bindings
  group_iam = {
    for k, v in local.group_iam :
    k => distinct(concat(v, lookup(var.group_iam, k, [])))
  }
  # machine (service accounts) IAM bindings
  iam = merge(
    {
      for k, v in local.iam : k => distinct(concat(v, lookup(var.iam, k, [])))
    },
    {
      for k, v in var.iam : k => v if lookup(local.iam, k, null) == null
    }
  )
  # additive bindings, used for roles co-managed by different stages
  iam_bindings_additive = merge(
    local.iam_bindings_additive,
    var.iam_bindings_additive
  )
  # delegated role grant for resource manager service account
  iam_bindings = {
    organization_iam_admin_conditional = {
      members = [module.automation-tf-resman-sa.iam_email]
      role    = module.organization.custom_role_id[var.custom_role_names.organization_iam_admin]
      condition = {
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
          join(",", formatlist("'%s'", concat(
            [
              "roles/accesscontextmanager.policyAdmin",
              "roles/compute.orgFirewallPolicyAdmin",
              "roles/compute.xpnAdmin",
              "roles/orgpolicy.policyAdmin",
              "roles/resourcemanager.organizationViewer",
              module.organization.custom_role_id[var.custom_role_names.tenant_network_admin]
            ],
            local.billing_mode == "org" ? [
              "roles/billing.admin",
              "roles/billing.costsManager",
              "roles/billing.user",
            ] : []
          )))
        )
        title       = "automation_sa_delegated_grants"
        description = "Automation service account delegated grants."
      }
    }
  }
  custom_roles = merge(var.custom_roles, {
    # this is needed for use in additive IAM bindings, to avoid conflicts
    (var.custom_role_names.organization_iam_admin) = [
      "resourcemanager.organizations.get",
      "resourcemanager.organizations.getIamPolicy",
      "resourcemanager.organizations.setIamPolicy"
    ]
    (var.custom_role_names.service_project_network_admin) = [
      "compute.globalOperations.get",
      # compute.networks.updatePeering and compute.networks.get are
      # used by automation service accounts who manage service
      # projects where peering creation might be needed (e.g. GKE). If
      # you remove them your network administrators should create
      # peerings for service projects
      "compute.networks.updatePeering",
      "compute.networks.get",
      "compute.organizations.disableXpnResource",
      "compute.organizations.enableXpnResource",
      "compute.projects.get",
      "compute.subnetworks.getIamPolicy",
      "compute.subnetworks.setIamPolicy",
      "dns.networks.bindPrivateDNSZone",
      "resourcemanager.projects.get",
    ]
    (var.custom_role_names.tenant_network_admin) = [
      "compute.globalOperations.get",
    ]
  })
  logging_sinks = {
    for name, attrs in var.log_sinks : name => {
      bq_partitioned_table = attrs.type == "bigquery"
      destination          = local.log_sink_destinations[name].id
      filter               = attrs.filter
      type                 = attrs.type
    }
  }
  org_policies_data_path = (
    var.bootstrap_user != null
    ? null
    : var.factories_config.org_policy_data_path
  )
  org_policies = var.bootstrap_user != null ? {} : {
    "iam.allowedPolicyMemberDomains" = {
      rules = [
        {
          allow = { values = local.drs_domains }
          condition = {
            expression = (
              "!resource.matchTag('${local.drs_tag_name}', 'allowed-policy-member-domains-all')"
            )
          }
        },
        {
          allow = { all = true }
          condition = {
            expression = (
              "resource.matchTag('${local.drs_tag_name}', 'allowed-policy-member-domains-all')"
            )
            title = "allow-all"
          }
        },
      ]
    }
    # "gcp.resourceLocations" = {}
    # "iam.workloadIdentityPoolProviders" = {}
  }
  tags = {
    (var.org_policies_config.tag_name) = {
      description = "Organization policy conditions."
      iam         = {}
      values = merge(
        {
          allowed-policy-member-domains-all = {}
        },
        var.org_policies_config.tag_values
      )
    }
  }
}
