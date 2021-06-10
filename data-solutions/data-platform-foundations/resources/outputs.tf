/**
 * Copyright 2020 Google LLC
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

output "datamart-datasets" {
  description = "List of bigquery datasets created for the datamart project."
  value = [
    for k, datasets in module.datamart-bq : datasets.dataset_id
  ]
}

output "dwh-datasets" {
  description = "List of bigquery datasets created for the dwh project."
  value       = [for k, datasets in module.dwh-bq : datasets.dataset_id]
}

output "landing-buckets" {
  description = "List of buckets created for the landing project."
  value       = [for k, bucket in module.landing-buckets : bucket.name]
}

output "landing-pubsub" {
  description = "List of pubsub topics and subscriptions created for the landing project."
  value = {
    for t in module.landing-pubsub : t.topic.name => {
      id            = t.topic.id
      subscriptions = { for s in t.subscriptions : s.name => s.id }
    }
  }
}

output "transformation-buckets" {
  description = "List of buckets created for the transformation project."
  value       = [for k, bucket in module.transformation-buckets : bucket.name]
}

output "transformation-vpc" {
  description = "Transformation VPC details"
  value = {
    name = module.vpc-transformation.name
    subnets = {
      for k, s in module.vpc-transformation.subnets : k => {
        ip_cidr_range = s.ip_cidr_range
        region        = s.region
      }
    }
  }
}
