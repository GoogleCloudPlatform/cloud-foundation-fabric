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

module "host-target-projects-test" {
  source                    = "../../../../../../blueprints/cloud-operations/vm-migration/host-target-projects"
  project_create            = var.project_create
  migration_admin_users     = ["user:admin@example.com"]
  migration_viewer_users    = ["user:viewer@example.com"]
  migration_target_projects = ["${module.test-target-project.name}"]
  depends_on = [
    module.test-target-project
  ]
}

variable "project_create" {
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = {
    billing_account_id = "1234-ABCD-1234"
    parent             = "folders/1234563"
  }
}

#This is a dummy project created to run this test. The example, here tested, is expected to run on top of existing foundations.
module "test-target-project" {
  source          = "../../../../../../modules/project"
  billing_account = "1234-ABCD-1234"
  name            = "test-target-project"
  project_create  = true
}
