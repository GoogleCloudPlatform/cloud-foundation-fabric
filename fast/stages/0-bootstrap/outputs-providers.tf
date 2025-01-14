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

# tfdoc:file:description Locals for provider output files.

locals {
  providers = merge(
    # this stage's providers
    {
      "0-bootstrap" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.automation-tf-bootstrap-gcs.name
        name          = "bootstrap"
        sa            = module.automation-tf-bootstrap-sa.email
      })
      "0-bootstrap-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.automation-tf-bootstrap-gcs.name
        name          = "bootstrap"
        sa            = module.automation-tf-bootstrap-r-sa.email
      })
    },
    # stage 1 providers
    {
      "1-resman" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.automation-tf-resman-gcs.name
        name          = "resman"
        sa            = module.automation-tf-resman-sa.email
      })
      "1-resman-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.automation-tf-resman-gcs.name
        name          = "resman"
        sa            = module.automation-tf-resman-r-sa.email
      })
      "1-vpcsc" = templatefile(local._tpl_providers, {
        backend_extra = "prefix = \"vpcsc\""
        bucket        = module.automation-tf-vpcsc-gcs.name
        name          = "vpcsc"
        sa            = module.automation-tf-vpcsc-sa.email
      })
      "1-vpcsc-r" = templatefile(local._tpl_providers, {
        backend_extra = "prefix = \"vpcsc\""
        bucket        = module.automation-tf-vpcsc-gcs.name
        name          = "vpcsc"
        sa            = module.automation-tf-vpcsc-r-sa.email
      })
    },
    # stage 1 addons
    {
      for k, v in var.fast_addon :
      "${v.parent_stage}-${k}" => templatefile(local._tpl_providers, {
        backend_extra = "prefix = \"addons/${k}\""
        name          = "${v.parent_stage}-${k}"
        bucket = (
          v.parent_stage == "resman"
          ? module.automation-tf-resman-gcs.name
          : module.automation-tf-vpcsc-gcs.name
        )
        sa = (
          v.parent_stage == "resman"
          ? module.automation-tf-resman-sa.name
          : module.automation-tf-vpcsc-sa.name
        )
      })
    },
    {
      for k, v in var.fast_addon :
      "${v.parent_stage}-${k}-r" => templatefile(local._tpl_providers, {
        backend_extra = "prefix = \"addons/${k}\""
        name          = "${v.parent_stage}-${k}"
        bucket = (
          v.parent_stage == "resman"
          ? module.automation-tf-resman-gcs.name
          : module.automation-tf-vpcsc-gcs.name
        )
        sa = (
          v.parent_stage == "resman"
          ? module.automation-tf-resman-r-sa.name
          : module.automation-tf-vpcsc-r-sa.name
        )
      })
    }
  )
}
