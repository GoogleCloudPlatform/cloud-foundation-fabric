/**
 * Copyright 2024 Google LLC
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

module "instance_monitor_function" {
  count       = var.enable_monitoring && length(var.apigee_config.instances) > 0 ? 1 : 0
  source      = "../../../modules/cloud-function-v2"
  project_id  = module.project.project_id
  name        = "instance-monitor"
  bucket_name = module.project.project_id
  bucket_config = {
  }
  bundle_config = {
    path = "${path.module}/functions/instance-monitor"
  }
  function_config = {
    entry_point = "writeMetric"
    runtime     = "nodejs20"
    timeout     = 180
  }
  trigger_config = {
    event_type = "google.cloud.audit.log.v1.written"
    region     = "global"
    event_filters = [
      {
        attribute = "serviceName"
        value     = "apigee.googleapis.com"
      },
      {
        attribute = "methodName"
        value     = "google.cloud.apigee.v1.RuntimeService.ReportInstanceStatus"
      },
    ]
    service_account_create = true
    retry_policy           = "RETRY_POLICY_DO_NOT_RETRY"
  }
  region                 = var.apigee_config.organization.analytics_region
  service_account_create = true
}
