# Copyright 2022 Google LLC
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

# tfdoc:file:description common project.

locals {
  group_iam_exp = {
    #TODO add group => role mapping to asign on exposure project
  }
  iam_exp = {
    #TODO add role => service account mapping to assign roles on exposure project
  }
  prefix_exp = "${var.prefix}-exp"
}

# Project

module "exp-prj" {
  source          = "../../../modules/project"
  name            = var.project_id["exposure"]
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_exp : {}
  iam_additive = var.project_create == null ? local.iam_exp : {}
  group_iam    = local.group_iam_exp
  services = concat(var.project_services, [
  ])
}
