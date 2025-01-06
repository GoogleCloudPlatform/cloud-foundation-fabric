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
  # output file definitions for stage 1 addons
  _stage1_output_attrs = {
    for k, v in local.stage_addons : "${v.stage.name}-${k}" => {
      bucket        = var.automation.state_buckets[v.stage.name]
      backend_extra = "prefix = \"addons/${k}\""
      sa = {
        apply = var.automation.service_accounts[v.stage.name]
        plan  = var.automation.service_accounts["${v.stage.name}-r"]
      }
    } if v.stage.level == "1" && contains(["resman", "vpcsc"], v.stage.name)
  }
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
    # addons, conditions are repeated to prevent inconsistent result type error
    var.fast_stage_2["networking"].enabled != true ? {} : {
      for k, v in local.stage_addons : "networking-${k}" => {
        bucket        = module.net-bucket[0].name
        backend_extra = "prefix = \"addons/${k}\""
        sa = {
          apply = module.net-sa-rw[0].email
          plan  = module.net-sa-ro[0].email
        }
      } if v.stage.level == "2" && v.stage.name == "networking"
    },
    var.fast_stage_2["project_factory"].enabled != true ? {} : {
      for k, v in local.stage_addons : "pf-${k}" => {
        bucket        = module.pf-bucket[0].name
        backend_extra = "prefix = \"addons/${k}\""
        sa = {
          apply = module.pf-sa-rw[0].email
          plan  = module.pf-sa-ro[0].email
        }
      } if v.stage.level == "2" && v.stage.name == "project-factory"
    },
    var.fast_stage_2["security"].enabled != true ? {} : {
      for k, v in local.stage_addons : "security-${k}" => {
        bucket        = module.sec-bucket[0].name
        backend_extra = "prefix = \"addons/${k}\""
        sa = {
          apply = module.sec-sa-rw[0].email
          plan  = module.sec-sa-ro[0].email
        }
      } if v.stage.level == "2" && v.stage.name == "security"
    },
  )
  # CI/CD workflow definitions for enabled stages
  _cicd_workflow_attrs = merge(
    # stage 2s
    {
      for k, v in local._stage2_outputs_attrs : k => {
        audiences = try(
          local.identity_providers[local.cicd_repositories[k].identity_provider].audiences, null
        )
        identity_provider = try(
          local.identity_providers[local.cicd_repositories[k].identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        service_accounts = {
          apply = try(module.cicd-sa-rw[k].email, "")
          plan  = try(module.cicd-sa-ro[k].email, "")
        }
        repository = local.cicd_repositories[k].repository
        stage_name = k
        tf_providers_files = {
          apply = "2-${replace(k, "_", "-")}-providers.tf"
          plan  = "2-${replace(k, "_", "-")}-r-providers.tf"
        }
        tf_var_files = local.cicd_workflow_files.stage_2
      } if lookup(local.cicd_repositories, k, null) != null
    },
    # stage 3
    {
      for k, v in local.cicd_repositories : "${v.lvl}-${k}" => {
        audiences = try(
          local.identity_providers[v.identity_provider].audiences, null
        )
        identity_provider = try(
          local.identity_providers[v.identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        repository     = v.repository
        service_accounts = {
          apply = module.cicd-sa-rw[0].email
          plan  = module.cicd-sa-ro[0].email
        }
        stage_name = v.short_name
        tf_providers_files = {
          apply = "${v.lvl}-${k}-providers.tf"
          plan  = "${v.lvl}-${k}-r-providers.tf"
        }
        tf_var_files = local.cicd_workflow_files.stage_3
      } if v.lvl == 3
    }
  )
}
