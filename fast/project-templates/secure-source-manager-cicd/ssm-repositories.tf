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

# the SSM service agent mints tokens for the repository BYOSA

# module "ssm-repo-sa" {
#   source     = "../../../modules/iam-service-account"
#   project_id = var.project_ids.ssm
#   name       = "ssm-repo-test-0"
#   prefix     = var.prefix
#   iam = {
#     "roles/iam.serviceAccountTokenCreator" = [
#       "serviceAccount:service-${var.project_numbers.ssm}@gcp-sa-sourcemanager.iam.gserviceaccount.com"
#     ]
#   }
#   iam_sa_roles = {
#     (module.build-sa-test.id) = ["roles/iam.serviceAccountUser"]
#   }
#   # builds are created in the pool project, so the Cloud Build roles land there
#   iam_project_roles = {
#     (var.project_ids.build) = [
#       "roles/cloudbuild.builds.editor",
#       "roles/cloudbuild.workerPoolUser",
#       "roles/serviceusage.serviceUsageConsumer",
#     ]
#   }
# }
