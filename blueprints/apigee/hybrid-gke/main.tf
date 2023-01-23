/**
 * Copyright 2023 Google LLC
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

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  project_create = var.project_create != null
  name           = var.project_id
  services = [
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "pubsub.googleapis.com"
  ]
  iam = {
    "roles/apigee.admin"                    = [module.mgmt_server.service_account_iam_email]
    "roles/container.admin"                 = [module.mgmt_server.service_account_iam_email]
    "roles/resourcemanager.projectIamAdmin" = [module.mgmt_server.service_account_iam_email]
    "roles/iam.serviceAccountAdmin"         = [module.mgmt_server.service_account_iam_email]
    "roles/iam.serviceAccountKeyAdmin"      = [module.mgmt_server.service_account_iam_email]
    "roles/monitoring.metricWriter"         = [module.sas["apigee-metrics"].iam_email]
    "roles/storage.objectAdmin"             = [module.sas["apigee-cassandra"].iam_email]
    "roles/apigeeconnect.Agent"             = [module.sas["apigee-mart"].iam_email]
    "roles/apigee.runtimeAgent"             = [module.sas["apigee-watcher"].iam_email]
    "roles/apigee.analyticsAgent"           = [module.sas["apigee-udca"].iam_email]
    "roles/apigee.synchronizerManager"      = [module.sas["apigee-synchronizer"].iam_email]
    "roles/cloudtrace.agent"                = [module.sas["apigee-runtime"].iam_email]
  }
}
