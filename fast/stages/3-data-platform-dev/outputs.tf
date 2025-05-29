# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Stage outputs.

locals {
  central_project = {
    id     = module.central-project.project_id
    number = module.central-project.number
  }
  dd_attrs = {
    for k, v in local.data_domains : k => {
      automation = v.automation == null ? null : {
        bucket = module.dd-automation-bucket[k].name
        service_accounts = {
          ro = module.dd-automation-sa["${k}/ro"].email
          rw = module.dd-automation-sa["${k}/rw"].email
        }
      }
      deployments = {
        composer = lookup(local.dd_composer, k, null) == null ? null : {
          airflow_uri = try(
            google_composer_environment.default[k].config[0].airflow_uri, null
          )
          dag_gcs_prefix = try(
            google_composer_environment.default[k].config[0].dag_gcs_prefix, null
          )
        }
      }
      data_products = {
        for pk in lookup(local.dp_by_dd, k, []) :
        split("/", pk)[1] => {
          for kk, kv in local.dp_attrs[pk] : kk => kv if kk != "automation"
        }
      }
      folder_ids = {
        domain   = module.dd-folders[k].id
        products = module.dd-dp-folders[k].id
      }
      project = {
        id     = module.dd-projects[k].project_id
        number = module.dd-projects[k].number
      }
      service_accounts = {
        for sk in keys(v.service_accounts) :
        sk => module.dd-service-accounts["${k}/${sk}"].email
      }
    }
  }
  dp_attrs = {
    for k, v in local.data_products : k => {
      automation = local.data_products[k].automation == null ? null : {
        bucket = module.dp-automation-bucket[k].name
        service_accounts = {
          ro = module.dp-automation-sa["${k}/ro"].email
          rw = module.dp-automation-sa["${k}/rw"].email
        }
      }
      exposure = {
        bigquery = {
          for vv in lookup(local.exp_datasets_by_dp, k, []) :
          split("/", vv)[2] => module.dp-datasets[vv].id
        }
        storage = {
          for vv in lookup(local.exp_buckets_by_dp, k, []) :
          split("/", vv)[2] => module.dp-buckets[vv].id
        }
      }
      project = {
        id     = module.dp-projects[k].project_id
        number = module.dp-projects[k].number
      }
      service_accounts = {
        for sk in keys(v.service_accounts) :
        sk => module.dp-service-accounts["${k}/${sk}"].email
      }
    }
  }
  dp_by_dd = {
    for k, v in local.data_products :
    v.dd => k...
  }
  exp_buckets_by_dp = {
    for k, v in module.dp-buckets :
    join("/", slice(split("/", k), 0, 2)) => k...
  }
  exp_datasets_by_dp = {
    for k, v in module.dp-datasets :
    join("/", slice(split("/", k), 0, 2)) => k...
  }
  files_prefix = "3-${var.stage_config.name}"
  providers = merge(
    {
      for k, v in local.dd_attrs :
      "${k}-providers.tf" => templatefile("templates/providers.tf.tpl", {
        backend_extra = null
        bucket        = v.automation.bucket
        name          = k
        sa            = v.automation.service_accounts.rw
      }) if v.automation != null
    },
    {
      for k, v in local.dd_attrs :
      "${k}-r-providers.tf" => templatefile("templates/providers.tf.tpl", {
        backend_extra = null
        bucket        = v.automation.bucket
        name          = k
        sa            = v.automation.service_accounts.ro
      }) if v.automation != null
    },
    {
      for k, v in local.dp_attrs :
      "${replace(k, "/", "-")}-providers.tf" => templatefile("templates/providers.tf.tpl", {
        backend_extra = null
        bucket        = v.automation.bucket
        name          = k
        sa            = v.automation.service_accounts.rw
      }) if v.automation != null
    },
    {
      for k, v in local.dp_attrs :
      "${replace(k, "/", "-")}-r-providers.tf" => templatefile("templates/providers.tf.tpl", {
        backend_extra = null
        bucket        = v.automation.bucket
        name          = k
        sa            = v.automation.service_accounts.ro
      }) if v.automation != null
    }
  )
  tfvars = {
    aspect_types    = module.central-aspect-types.ids
    central_project = local.central_project
    policy_tags     = module.central-policy-tags.tags
    secure_tags = {
      for k, v in module.central-project.tag_values : k => v.id
    }
  }
  tfvars_dd = {
    for k, v in local.data_domains : k => merge(local.tfvars, {
      for kk, vv in local.dd_attrs[k] :
      kk => vv if kk != "automation"
    })
  }
}

# tfvars files for data domains and products

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : local.tfvars_dd
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/${local.files_prefix}/${each.key}.auto.tfvars.json"
  content         = jsonencode(each.value)
}

resource "google_storage_bucket_object" "tfvars" {
  for_each = local.tfvars_dd
  bucket   = var.automation.outputs_bucket
  name     = "tfvars/${local.files_prefix}/${each.key}.auto.tfvars.json"
  content  = jsonencode(each.value)
}

# provider files for data domains and products

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : local.providers
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/providers/${local.files_prefix}/${each.key}"
  content         = each.value
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.providers
  bucket   = var.automation.outputs_bucket
  name     = "providers/${local.files_prefix}/${each.key}"
  content  = each.value
}

resource "google_storage_bucket_object" "version" {
  count  = fileexists("fast_version.txt") ? 1 : 0
  bucket = var.automation.outputs_bucket
  name   = "versions/3-${var.stage_config.name}-version.txt"
  source = "fast_version.txt"
}

# regular outputs

output "aspect_types" {
  description = "Aspect types defined in central project."
  value       = local.tfvars.aspect_types
}

output "central_project" {
  description = "Central project attributes."
  value       = local.central_project
}

output "data_domains" {
  description = "Data domain attributes."
  value       = local.dd_attrs
}

output "policy_tags" {
  description = "Policy tags defined in central project."
  value       = local.tfvars.policy_tags
}

output "secure_tags" {
  description = "Secure tags defined in central project."
  value       = local.tfvars.secure_tags
}
