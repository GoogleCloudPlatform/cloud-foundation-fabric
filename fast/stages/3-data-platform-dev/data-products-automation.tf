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

# tfdoc:file:description Data product automation resources.

module "dp-automation-bucket" {
  source = "../../../modules/gcs"
  for_each = {
    for k, v in local.data_products :
    k => v if v.automation != null
  }
  project_id = module.dd-projects[each.value.dd].project_id
  prefix     = local.prefix
  name       = "${each.value.short_name}-state"
  location = try(
    each.value.automation.location,
    var.location
  )
  iam = {
    "roles/storage.admin" = [
      module.dp-automation-sa["${each.key}/rw"].iam_email
    ]
    "roles/storage.objectViewer" = concat(
      [
        module.dp-automation-sa["${each.key}/ro"].iam_email
      ],
      [
        for m in each.value.automation.impersonation_principals : lookup(
          var.factories_config.context.iam_principals, m, m
        )
      ]
    )
  }
}

module "dp-automation-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = { for v in local.dp_automation_sa : v.key => v }
  project_id  = module.dp-projects[each.value.dp].project_id
  prefix      = each.value.prefix
  name        = each.value.name
  description = each.value.description
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for m in each.value.impersonation_principals : lookup(
        var.factories_config.context.iam_principals, m, m
      )
    ]
  }
}
