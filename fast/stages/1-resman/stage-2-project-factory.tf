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
  _pf_short_names = (
    var.fast_stage_2.project_factory.enabled
    ? toset(var.fast_stage_2.project_factory.short_name)
    : toset([])
  )
}

# automation service accounts

module "pf-sa-rw" {
  source     = "../../../modules/iam-service-account"
  for_each   = local._pf_short_names
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-pf_rw"], {
    name = each.value
  })
  display_name = "Terraform resman project factory main service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.cicd-sa-rw[k].iam_email if v.stage == "project-factory"
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "pf-sa-ro" {
  source     = "../../../modules/iam-service-account"
  for_each   = local._pf_short_names
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-pf_ro"], {
    name = each.value
  })
  display_name = "Terraform resman project factory main service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      for k, v in local.cicd_repositories :
      module.cicd-sa-ro[k].iam_email if v.stage == "project-factory"
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "pf-bucket" {
  source     = "../../../modules/gcs"
  for_each   = local._pf_short_names
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["gcs-pf"], {
    name = each.value
  })
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.pf-sa-rw[each.value].iam_email]
    "roles/storage.objectViewer" = [module.pf-sa-ro[each.value].iam_email]
  }
}
