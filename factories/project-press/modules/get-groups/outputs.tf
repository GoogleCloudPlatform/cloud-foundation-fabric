/**
 * Copyright 2021 Google LLC
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
  process_shared_vpc = { for k, v in merge(local.shared_vpc_groups...) : v => local.all_groups[v]... if v != "" }
  output_shared_vpc  = { for k, v in local.process_shared_vpc : k => v[0] }
  process_serverless = { for k, v in merge(local.serverless_groups...) : v => local.all_groups[v]... if v != "" }
  output_serverless  = { for k, v in local.process_serverless : k => v[0] }
  process_monitoring = { for k, v in merge(local.monitoring_groups...) : v => local.all_groups[v]... if v != "" }
  output_monitoring  = { for k, v in local.process_monitoring : k => v[0] }
}

output "shared_vpc_groups" {
  description = "Shared VPC group IDs"
  value       = local.output_shared_vpc
}

output "serverless_groups" {
  description = "Serverless group IDs"
  value       = local.output_serverless
}

output "monitoring_groups" {
  description = "Monitoring group IDs"
  value       = local.output_monitoring
}

output "groups" {
  description = "All group IDs"
  value       = merge(local.output_shared_vpc, local.output_serverless, local.output_monitoring)
}
