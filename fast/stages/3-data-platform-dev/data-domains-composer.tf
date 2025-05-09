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

locals {
  dd_composer = {
    for k, v in local.data_domains : k => merge(
      { region = var.location, short_name = v.short_name },
      try(v.deploy_config.composer, {})
    )
  }
  dd_composer_keys = {
    for k, v in local.dd_composer : k => try(
      v.encryption_key,
      var.encryption_keys.composer[v.region],
      null
    )
  }
}

module "dd-composer-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.dd_composer
  project_id  = module.dd-projects[each.key].project_id
  prefix      = local.prefix
  name        = "${each.value.short_name}-cmp-sa"
  description = "Composer Service Account."
}

resource "google_composer_environment" "default" {
  for_each = local.dd_composer
  project  = module.dd-projects-iam[each.key].project_id
  name     = "${var.prefix}-${each.key}"
  region   = each.value.region
  config {
    enable_private_builds_only = try(each.value.private_builds, true)
    enable_private_environment = try(each.value.private_environment, true)
    environment_size = try(
      each.value.environment_size,
      "ENVIRONMENT_SIZE_SMALL"
    )
    dynamic "encryption_config" {
      for_each = local.dd_composer_keys[each.key] == null ? [] : [""]
      content {
        kms_key_name = lookup(
          local.kms_keys,
          local.dd_composer_keys[each.key],
          local.dd_composer_keys[each.key]
        )
      }
    }
    # TODO: implement the same context fail mode used in the project factory
    node_config {
      service_account = try(
        each.value.node_config.service_account,
        module.dd-composer-sa[each.key].email
      )
      network = try(
        var.vpc_self_links[each.value.node_config.network],
        each.value.node_config.network,
        null
      )
      subnetwork = try(
        var.subnet_self_links[each.value.node_config.network][each.value.node_config.subnetwork],
        each.value.node_config.subnetwork,
        null
      )
    }
    software_config {
      image_version = "composer-3-airflow-2"
      cloud_data_lineage_integration {
        enabled = true
      }
    }
    workloads_config {
      dag_processor {
        cpu        = try(each.value.workloads_config.dag_processor.cpu, 0.5)
        memory_gb  = try(each.value.workloads_config.dag_processor.memory_gb, 2)
        storage_gb = try(each.value.workloads_config.dag_processor.storage_gb, 1)
        count      = try(each.value.workloads_config.dag_processor.count, 1)
      }
      scheduler {
        cpu        = try(each.value.workloads_config.scheduler.cpu, 0.5)
        memory_gb  = try(each.value.workloads_config.scheduler.memory_gb, 2)
        storage_gb = try(each.value.workloads_config.scheduler.storage_gb, 1)
        count      = try(each.value.workloads_config.scheduler.count, 1)
      }
      triggerer {
        cpu       = try(each.value.workloads_config.triggerer.cpu, 0.5)
        memory_gb = try(each.value.workloads_config.triggerer.memory_gb, 2)
        count     = try(each.value.workloads_config.triggerer.count, 1)
      }
      web_server {
        cpu        = try(each.value.workloads_config.web_server.cpu, 0.5)
        memory_gb  = try(each.value.workloads_config.web_server.memory_gb, 2)
        storage_gb = try(each.value.workloads_config.web_server.storage_gb, 1)
      }
      worker {
        cpu        = try(each.value.workloads_config.worker.cpu, 0.5)
        memory_gb  = try(each.value.workloads_config.worker.memory_gb, 2)
        storage_gb = try(each.value.workloads_config.worker.storage_gb, 1)
        min_count  = try(each.value.workloads_config.worker.min_count, 1)
        max_count  = try(each.value.workloads_config.worker.max_count, 1)
      }
    }
  }
}
