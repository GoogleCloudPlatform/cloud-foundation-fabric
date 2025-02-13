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
  # output file definitions for enabled stage 2s
  _stage2_outputs_attrs = merge(
    var.fast_stage_2["networking"].enabled != true ? {} : {
      networking = {
        bucket = module.net-bucket[0].name
        sa = {
          apply = module.net-sa-rw[0].email
          plan  = module.net-sa-ro[0].email
        }
      }
    },
    var.fast_stage_2["project_factory"].enabled != true ? {} : {
      project_factory = {
        bucket = module.pf-bucket[0].name
        sa = {
          apply = module.pf-sa-rw[0].email
          plan  = module.pf-sa-ro[0].email
        }
      }
    },
    var.fast_stage_2["security"].enabled != true ? {} : {
      security = {
        bucket = module.sec-bucket[0].name
        sa = {
          apply = module.sec-sa-rw[0].email
          plan  = module.sec-sa-ro[0].email
        }
      }
    },
    # TODO: use ${parent_stage}-${key} for the addon file output names
    # addons, conditions are repeated to prevent inconsistent result type error
    var.fast_stage_2["networking"].enabled != true ? {} : {
      for k, v in local.stage_addons : "networking-${k}" => {
        bucket        = module.net-bucket[0].name
        backend_extra = "prefix = \"addons/${k}\""
        sa = {
          apply = module.net-sa-rw[0].email
          plan  = module.net-sa-ro[0].email
        }
      } if v.parent_stage == "2-networking"
    },
    var.fast_stage_2["project_factory"].enabled != true ? {} : {
      for k, v in local.stage_addons : "pf-${k}" => {
        bucket        = module.pf-bucket[0].name
        backend_extra = "prefix = \"addons/${k}\""
        sa = {
          apply = module.pf-sa-rw[0].email
          plan  = module.pf-sa-ro[0].email
        }
      } if v.parent_stage == "2-project-factory"
    },
    var.fast_stage_2["security"].enabled != true ? {} : {
      for k, v in local.stage_addons : "security-${k}" => {
        bucket        = module.sec-bucket[0].name
        backend_extra = "prefix = \"addons/${k}\""
        sa = {
          apply = module.sec-sa-rw[0].email
          plan  = module.sec-sa-ro[0].email
        }
      } if v.parent_stage == "2-security"
    }
  )
  # render provider files from template
  providers = merge(
    # stage 2
    {
      for k, v in local._stage2_outputs_attrs :
      "2-${replace(k, "_", "-")}" => templatefile(local._tpl_providers, {
        backend_extra = lookup(v, "backend_extra", null)
        bucket        = v.bucket
        name          = k
        sa            = v.sa.apply
      })
    },
    {
      for k, v in local._stage2_outputs_attrs :
      "2-${replace(k, "_", "-")}-r" => templatefile(local._tpl_providers, {
        backend_extra = lookup(v, "backend_extra", null)
        bucket        = v.bucket
        name          = k
        sa            = v.sa.plan
      })
    },
    # stage 3
    {
      for k, v in local.stage3 :
      "3-${k}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage3-bucket[k].name
        name          = k
        sa            = module.stage3-sa-rw[k].email
      })
    },
    {
      for k, v in local.stage3 :
      "3-${k}-r" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage3-bucket[k].name
        name          = k
        sa            = module.stage3-sa-ro[k].email
      })
    },
    # top-level folders
    {
      for k, v in module.top-level-sa :
      "1-resman-folder-${k}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.top-level-bucket[k].name
        name          = k
        sa            = v.email
      })
    },
  )
}
