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
  # render provider files from template
  providers = merge(
    # stage 2
    {
      for k, v in local.stage2 :
      "2-${k}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage2-bucket[k].name
        name          = k
        sa            = module.stage2-sa-rw[k].email
      })
    },
    {
      for k, v in local.stage2 :
      "2-${k}-r" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage2-bucket[k].name
        name          = k
        sa            = module.stage2-sa-ro[k].email
      })
    },
    # stage 2 addons
    {
      for k, v in local.stage_addons :
      "${v.parent_stage}-${v.short_name}" => templatefile(local._tpl_providers, {
        backend_extra = "prefix = \"addons/${k}\""
        bucket        = module.stage2-bucket[v.stage.name].name
        name          = "${v.stage.name}-${v.short_name}"
        sa            = module.stage2-sa-rw[v.stage.name].email
      }) if lookup(local.stage2, v.stage.name, null) != null
    },
    {
      for k, v in local.stage_addons :
      "${v.parent_stage}-${v.short_name}-r" => templatefile(local._tpl_providers, {
        backend_extra = "prefix = \"addons/${k}\""
        bucket        = module.stage2-bucket[v.stage.name].name
        name          = "${v.stage.name}-${v.short_name}"
        sa            = module.stage2-sa-ro[v.stage.name].email
      }) if lookup(local.stage2, v.stage.name, null) != null
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
