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
  apt_remote_registries = {
    for v in var.apt_remote_registries : (v.path) => merge(v, {
      name = element(split("/", split(" ", v.path)[1]), -1)
    })
  }
}

module "registries" {
  source     = "../../../modules/artifact-registry"
  for_each   = local.apt_remote_registries
  project_id = var.project_id
  location   = var.location
  name       = "${var.name}-${each.value.name}"
  format = {
    apt = {
      remote = {
        public_repository = each.value.path
      }
    }
  }
  iam = {
    "roles/artifactregistry.writer" = each.value.writer_principals
  }
}
