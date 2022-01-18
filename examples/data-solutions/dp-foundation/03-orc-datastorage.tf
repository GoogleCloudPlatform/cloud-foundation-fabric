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

###############################################################################
#                                   GCS                                       #
###############################################################################

module "orc-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.orc-prj.project_id
  name           = "orc-cs-0"
  prefix         = local.prefix_orc
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? try(module.kms[0].keys.key-gcs.id, null) : null
}
