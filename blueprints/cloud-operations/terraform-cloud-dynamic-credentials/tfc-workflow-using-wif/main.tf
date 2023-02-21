# Copyright 2023 Google LLC
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
#                        TEST RESOURCE TO VALIDATE WIF                        #
###############################################################################

resource "google_storage_bucket" "test-bucket" {
  project       = var.project_id
  name          = "${var.project_id}-test"
  location      = "US"
  force_destroy = true
}
