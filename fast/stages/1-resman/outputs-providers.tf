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

locals {
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  providers = merge(
    # stage 2
    !var.fast_stage_2.networking.enabled ? {} : {
      "2-networking" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.net-bucket[0].name
        name          = "networking"
        sa            = module.net-sa-rw[0].email
      })
      "2-networking-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.net-bucket[0].name
        name          = "networking"
        sa            = module.net-sa-ro[0].email
      })
    },
    !var.fast_stage_2.security.enabled ? {} : {
      "2-security" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.sec-bucket[0].name
        name          = "security"
        sa            = module.sec-sa-rw[0].email
      })
      "2-security-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.sec-bucket[0].name
        name          = "security"
        sa            = module.sec-sa-ro[0].email
      })
    },
    !var.fast_stage_2.project_factory.enabled ? {} : {
      "2-project-factory" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.pf-bucket[0].name
        name          = "project-factory"
        sa            = module.pf-sa-rw[0].email
      })
      "2-project-factory-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.pf-bucket[0].name
        name          = "project-factory"
        sa            = module.pf-sa-ro[0].email
      })
    },
    # stage 3
    {
      for k, v in var.fast_stage_3 :
      "3-${k}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage3-bucket[k].name
        name          = k
        sa            = module.stage3-sa-rw[k].email
      })
    },
    {
      for k, v in var.fast_stage_3 :
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
