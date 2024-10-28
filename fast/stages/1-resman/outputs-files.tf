/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Output files persistence to local filesystem.

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
    var.fast_stage_2["network_security"].enabled != true ? {} : {
      network_security = {
        bucket = module.nsec-bucket[0].name
        sa = {
          apply = module.nsec-sa-rw[0].email
          plan  = module.nsec-sa-ro[0].email
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
    }
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
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  cicd_workflows = {
    for k, v in local._cicd_workflow_attrs : k => templatefile(
      "${path.module}/templates/workflow-${v.repository.type}.yaml", v
    )
  }
  outputs_location = try(pathexpand(var.outputs_location), "")
  # render provider files from template
  providers = merge(
    # stage 2
    {
      for k, v in local._stage2_outputs_attrs :
      "2-${replace(k, "_", "-")}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = v.bucket
        name          = "networking"
        sa            = v.sa.apply
      })
    },
    {
      for k, v in local._stage2_outputs_attrs :
      "2-${replace(k, "_", "-")}-r" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = v.bucket
        name          = "networking"
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

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : local.providers
  file_permission = "0644"
  filename        = "${local.outputs_location}/providers/${each.key}-providers.tf"
  content         = try(each.value, null)
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${local.outputs_location}/tfvars/1-resman.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "local_file" "workflows" {
  for_each        = var.outputs_location == null ? {} : local.cicd_workflows
  file_permission = "0644"
  filename        = "${local.outputs_location}/workflows/${replace(each.key, "_", "-")}-workflow.yaml"
  content         = try(each.value, null)
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.providers
  bucket   = var.automation.outputs_bucket
  name     = "providers/${each.key}-providers.tf"
  content  = each.value
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/1-resman.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "workflows" {
  for_each = local.cicd_workflows
  bucket   = var.automation.outputs_bucket
  name     = "workflows/${replace(each.key, "_", "-")}-workflow.yaml"
  content  = each.value
}
