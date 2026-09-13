/**
 * Copyright 2026 Google LLC
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
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  # name of the reserved load balancer address
  ssm_lb_ip = "${local.prefix}dev-0-ssm-lb"
}

module "build-sa-test" {
  source     = "../../../modules/iam-service-account"
  project_id = var.project_ids.build
  name       = "build-test-0"
  prefix     = var.prefix
  iam_project_roles = {
    (var.project_ids.build) = [
      "roles/logging.logWriter",
      "roles/cloudbuild.workerPoolUser",
    ]
  }
}
