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
    # stage 2
    merge([
      for k, v in local.stage2 :
      v.organization_config.iam_bindings_additive
    ]...),
    # stage 3
    {
      for v in local.stage3_sa_roles_in_org : join("/", values(v)) => {
        role = lookup(var.custom_roles, v.role, v.role)
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
