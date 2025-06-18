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


resource "google_clouddeploy_target" "target" {
  for_each = {
    for name, target in var.targets :
    name => target if target.create_target == true
  }

  project           = coalesce(each.value.project_id, var.project_id)
  location          = coalesce(each.value.region, var.region)
  name              = each.value.name
  deploy_parameters = each.value.target_deploy_parameters
  description       = each.value.description

  dynamic "execution_configs" {
    for_each = each.value.execution_configs_usages == null && each.value.execution_configs_timeout == null ? [] : [""]
    iterator = each_exec_config

    content {
      usages            = each.value.execution_configs_usages
      execution_timeout = each.value.execution_configs_timeout
    }
  }

  dynamic "multi_target" {
    for_each = each.value.multi_target_target_ids == null ? [] : [""]
    iterator = each_multi_target

    content {
      target_ids = each.value.multi_target_target_ids
    }
  }

  dynamic "run" {
    for_each = each.value.cloud_run_configs == null ? [] : [""]

    content {
      location = "projects/${coalesce(each.value.cloud_run_configs.project_id, each.value.project_id, var.project_id)}/locations/${coalesce(each.value.cloud_run_configs.region, each.value.region, var.region)}"
    }
  }


  require_approval = each.value.require_approval

  annotations = each.value.annotations

  labels = each.value.labels
}

