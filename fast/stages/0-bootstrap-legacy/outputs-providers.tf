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

# TODO: templates should probably use provider::terraform::encode_expr
# (not jsonencode) to encode extras

locals {
  _parent_stage_resources = {
    "1-resman" = {
      bucket = module.automation-tf-resman-gcs.name
      sa     = module.automation-tf-resman-sa.email
      sa_r   = module.automation-tf-resman-r-sa.email
    }
    "1-vpcsc" = {
      bucket = module.automation-tf-vpcsc-gcs.name
      sa     = module.automation-tf-vpcsc-sa.email
      sa_r   = module.automation-tf-vpcsc-r-sa.email
    }
  }
  providers = merge(
    # this stage's providers
    {
      "0-bootstrap" = templatefile(local._tpl_providers, {
        bucket        = module.automation-tf-bootstrap-gcs.name
        name          = "bootstrap"
        sa            = module.automation-tf-bootstrap-sa.email
        backend_extra = null
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
      "0-bootstrap-r" = templatefile(local._tpl_providers, {
        bucket        = module.automation-tf-bootstrap-gcs.name
        name          = "bootstrap"
        sa            = module.automation-tf-bootstrap-r-sa.email
        backend_extra = null
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
    },
    # stage 1 providers
    {
      "1-resman" = templatefile(local._tpl_providers, {
        bucket        = module.automation-tf-resman-gcs.name
        name          = "resman"
        sa            = module.automation-tf-resman-sa.email
        backend_extra = null
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
      "1-resman-r" = templatefile(local._tpl_providers, {
        bucket        = module.automation-tf-resman-gcs.name
        name          = "resman"
        sa            = module.automation-tf-resman-r-sa.email
        backend_extra = null
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
      "1-vpcsc" = templatefile(local._tpl_providers, {
        bucket = module.automation-tf-vpcsc-gcs.name
        name   = "vpcsc"
        sa     = module.automation-tf-vpcsc-sa.email
        backend_extra = {
          prefix = "vpcsc"
        }
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
      "1-vpcsc-r" = templatefile(local._tpl_providers, {
        bucket = module.automation-tf-vpcsc-gcs.name
        name   = "vpcsc"
        sa     = module.automation-tf-vpcsc-r-sa.email
        backend_extra = {
          prefix = "vpcsc"
        }
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
    },
    # stage 1 addons
    {
      for k, v in var.fast_addon :
      "${v.parent_stage}-${k}" => templatefile(local._tpl_providers, {
        name   = "${v.parent_stage}-${k}"
        bucket = local._parent_stage_resources[v.parent_stage].bucket
        sa     = local._parent_stage_resources[v.parent_stage].sa
        backend_extra = {
          prefix = "addons/${k}"
        }
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
    },
    {
      for k, v in var.fast_addon :
      "${v.parent_stage}-${k}-r" => templatefile(local._tpl_providers, {
        name   = "${v.parent_stage}-${k}"
        bucket = local._parent_stage_resources[v.parent_stage].bucket
        sa     = local._parent_stage_resources[v.parent_stage].sa_r
        backend_extra = {
          prefix = "addons/${k}"
        }
        provider_extra = var.universe == null ? null : {
          universe_domain = var.universe.domain
        }
      })
    }
  )
}
