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
    try(local.policy_configs.allowed_policy_member_domains, []),
    compact([for k, v in var.tenants : try(v.organization.customer_id, "")])
  )
  policy_configs = (
    var.organization_policy_configs == null
    ? {}
    : var.organization_policy_configs
  )
  tags = {
    for k, v in var.tags : k => merge(v, {
      values = {
        for vk, vv in v.values : vk => merge(vv, {
          iam = {
            for rk, rv in vv.iam : rk => [
              for rm in rv : (
                contains(keys(local.service_accounts), rm)
                ? "serviceAccount:${local.service_accounts[rm]}"
                : rm
              )
            ]
          }
        })
      }
    })
  }
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  # additive bindings via delegated IAM grant set in stage 0
  iam_bindings_additive = local.iam_bindings_additive
  # sample subset of useful organization policies, edit to suit requirements
  org_policies = {
    "iam.allowedPolicyMemberDomains" = {
      rules = [
        {
          allow = { values = local.all_drs_domains }
          condition = {
            expression = "!resource.matchTag('${var.organization.id}/${var.tag_names.org-policies}', 'allowed-policy-member-domains-all')"
          }
        },
        {
          allow = { all = true }
          condition = {
            expression = "resource.matchTag('${var.organization.id}/${var.tag_names.org-policies}', 'allowed-policy-member-domains-all')"
            title      = "allow-all"
          }
        },
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
  tags = merge(local.tags, {
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
        tenant     = null
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
    (var.tag_names.org-policies) = {
      description = "Organization policy conditions."
      iam         = {}
      values = {
        allowed-policy-member-domains-all = merge({}, try(
          local.tags[var.tag_names.org-policies].values.allowed-policy-member-domains-all,
          {}
        ))
      }
    }
    (var.tag_names.tenant) = {
      description = "Organization tenant."
      values = {
        for k, v in var.tenants : k => {
          description = v.descriptive_name
          iam = {
            "roles/resourcemanager.tagViewer" = local.tenant_iam[k]
          }
        }
      }
    }
  })
}
