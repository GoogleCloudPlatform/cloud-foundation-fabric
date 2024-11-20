/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Organization or root node-level IAM bindings.

locals {
  # aggregated map of organization IAM additive bindings for stages
  iam_bindings_additive = merge(
    # stage 2 networking
    !var.fast_stage_2.networking.enabled ? {} : {
      sa_net_fw_policy_admin = {
        member = module.net-sa-rw[0].iam_email
        role   = "roles/compute.orgFirewallPolicyAdmin"
      }
      sa_net_xpn_admin = {
        member = module.net-sa-rw[0].iam_email
        role   = "roles/compute.xpnAdmin"
      }
    },
    # stage 2 network security
    !var.fast_stage_2.network_security.enabled ? {} : {
      sa_nsec_fw_policy_admin = {
        member = module.nsec-sa-rw[0].iam_email
        role   = "roles/compute.orgFirewallPolicyAdmin"
      }
      sa_net_nsec_ngfw_enterprise_admin = {
        member = module.nsec-sa-rw[0].iam_email
        role   = local.custom_roles["ngfw_enterprise_admin"],
      }
      sa_net_nsec_fw_policy_user = {
        member = module.nsec-sa-rw[0].iam_email
        role   = "roles/compute.orgFirewallPolicyUser"
      }
      sa_net_nsec_ro_ngfw_enterprise_viewer = {
        member = module.nsec-sa-ro[0].iam_email
        role   = local.custom_roles["ngfw_enterprise_viewer"],
      }
    },
    # stage 2 security
    !var.fast_stage_2.security.enabled ? {} : {
      sa_sec_asset_viewer = {
        member = module.sec-sa-rw[0].iam_email
        role   = "roles/cloudasset.viewer"
      }
    },
    # stage 2 project factory
    var.root_node != null || var.fast_stage_2.project_factory.enabled != true ? {} : {
      sa_pf_conditional_org_policy = {
        member = module.pf-sa-rw[0].iam_email
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title       = "org_policy_tag_pf_scoped"
          description = "Org policy tag scoped grant for project factory."
          expression  = <<-END
            resource.matchTag('${local.tag_root}/${var.tag_names.context}', 'project-factory')
          END
        }
      }
    },
    # stage 3
    {
      for v in local.stage3_sa_roles_in_org : join("/", values(v)) => {
        role = lookup(local.custom_roles, v.role, v.role)
        member = (
          v.sa == "rw"
          ? module.stage3-sa-rw[v.s3].iam_email
          : module.stage3-sa-ro[v.s3].iam_email
        )
        condition = {
          title      = "stage3 ${v.s3} ${v.env}"
          expression = <<-END
            resource.matchTag(
              '${local.tag_root}/${var.tag_names.environment}',
              '${v.env}'
            )
            &&
            resource.matchTag(
              '${local.tag_root}/${var.tag_names.context}',
              '${v.context}'
            )
          END
        }
      }
    },
    # billing for all stages
    local.billing_mode != "org" ? {} : local.billing_iam
  )
}
