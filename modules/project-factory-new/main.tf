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

# tfdoc:file:description Projects and billing budgets factory resources.

locals {
  ctx = var.context
}

resource "terraform_data" "defaults_preconditions" {
  lifecycle {
    precondition {
      condition = (
        var.data_defaults.storage_location != null ||
        var.data_overrides.storage_location != null
      )
      error_message = "No default storage location defined in defaults or ovverides variables."
    }
  }
}
