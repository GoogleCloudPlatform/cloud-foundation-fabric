/**
 * Copyright 2025 Google LLC
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
      for k, v in local.iam_principal_bindings : k => {
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
  org_policies_tag_name = "${var.organization.id}/${var.org_policies_config.tag_name}"
  iam_principals = {
    for k, v in local.iam_principal_bindings : k => v.authoritative
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

# TODO: add a check block to ensure our custom roles exist in the factory files

# import org policy constraints enabled by default in new orgs since February 2024
import {
  for_each = (
    !var.org_policies_config.import_defaults || var.bootstrap_user != null
    ? toset([])
    : toset([
      # source: https://cloud.google.com/resource-manager/docs/secure-by-default-organizations#organization_policies_enforced_on_organization_resources
      # listed in the order as on page
      "iam.disableServiceAccountKeyCreation",
      "iam.disableServiceAccountKeyUpload",
      "iam.automaticIamGrantsForDefaultServiceAccounts",
      "iam.allowedPolicyMemberDomains",
      "essentialcontacts.allowedContactDomains",
      "storage.uniformBucketLevelAccess",
      "compute.setNewProjectDefaultToZonalDNSOnly",         # Verified as of 2024-09-13
      "compute.restrictProtocolForwardingCreationForTypes", # Verified as of 2025-02-13
    ])
  )
  id = "organizations/${var.organization.id}/policies/${each.key}"
  to = module.organization.google_org_policy_policy.default[each.key]
}

module "organization-logging" {
  # Preconfigure organization-wide logging settings to ensure project
  # log buckets (_Default, _Required) are created in the location
  # specified by `var.locations.logging`. This separate
  # organization-block prevents circular dependencies with later
  # project creation.
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  logging_settings = {
    storage_location = var.locations.logging
  }
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = module.organization-logging.id
  # human (groups) IAM bindings
  iam_by_principals = {
    for key in distinct(concat(
      keys(local.iam_principals),
      keys(var.iam_by_principals),
    )) :
    key => distinct(concat(
      lookup(local.iam_principals, key, []),
      lookup(var.iam_by_principals, key, []),
    ))
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
  iam_bindings = merge(
    {
      organization_iam_admin_conditional = {
        members = [module.automation-tf-resman-sa.iam_email]
        role    = module.organization.custom_role_id["organization_iam_admin"]
        condition = {
          expression = (
            format(
              <<-EOT
              api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])
              || api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])
              || api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])
              EOT
              , join(",", formatlist("'%s'", [
                "roles/accesscontextmanager.policyEditor",
                "roles/accesscontextmanager.policyReader",
                "roles/cloudasset.viewer",
                "roles/compute.orgFirewallPolicyAdmin",
                "roles/compute.orgFirewallPolicyUser",
                "roles/compute.xpnAdmin",
                "roles/orgpolicy.policyAdmin",
                "roles/orgpolicy.policyViewer",
                "roles/resourcemanager.organizationViewer",
              ]))
              , join(",", formatlist("'%s'", [
                "roles/iam.workforcePoolAdmin",
                "roles/iam.workforcePoolViewer"
              ]))
              , join(",", formatlist("'%s'", [
                module.organization.custom_role_id["billing_viewer"],
                module.organization.custom_role_id["network_firewall_policies_admin"],
                module.organization.custom_role_id["ngfw_enterprise_admin"],
                module.organization.custom_role_id["ngfw_enterprise_viewer"],
                module.organization.custom_role_id["service_project_network_admin"],
                module.organization.custom_role_id["tenant_network_admin"]
              ]))
            )
          )
          title       = "automation_sa_delegated_grants"
          description = "Automation service account delegated grants."
        }
      }
    },
    local.billing_mode != "org" ? {} : {
      organization_billing_conditional = {
        members = [module.automation-tf-resman-sa.iam_email]
        role    = module.organization.custom_role_id["organization_iam_admin"]
        condition = {
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            join(",", formatlist("'%s'", [
              "roles/billing.admin",
              "roles/billing.costsManager",
              "roles/billing.user",
            ]))
          )
          title       = "automation_sa_delegated_grants"
          description = "Automation service account delegated grants."
        }
      }
    }
  )
  custom_roles = var.custom_roles
  factories_config = {
    custom_roles = var.factories_config.custom_roles
    org_policy_custom_constraints = (
      var.bootstrap_user != null ? null : var.factories_config.custom_constraints
    )
    org_policies = (
      var.bootstrap_user != null ? null : var.factories_config.org_policies
    )
    context = {
      org_policies = {
        organization = var.organization
        tags = {
          org_policies_tag_name = local.org_policies_tag_name
        }
      }
    }
  }
  logging_sinks = {
    for name, attrs in var.log_sinks : name => {
      bq_partitioned_table = attrs.type == "bigquery"
      destination          = local.log_sink_destinations[name].id
      filter               = attrs.filter
      type                 = attrs.type
      disabled             = attrs.disabled
      exclusions           = attrs.exclusions
    }
  }
  tags = {
    (var.org_policies_config.tag_name) = {
      description = "Organization policy conditions."
      iam         = {}
      values = merge(
        {
          allowed-essential-contacts-domains-all = {}
          allowed-policy-member-domains-all      = {}
        },
        var.org_policies_config.tag_values
      )
    }
  }
}
