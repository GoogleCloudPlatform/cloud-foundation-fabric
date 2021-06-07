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


###############################################################################
#                                  Network                                    #
###############################################################################

output "transformation-vpc-info" {
  description = "Transformation VPC details"
  value = {
    name = module.vpc-transformation.name
    subnets = {
      for s in module.vpc-transformation.subnets : s.name => {
        gateway_address          = s.gateway_address
        ip_cidr_range            = s.ip_cidr_range
        private_ip_google_access = s.private_ip_google_access
        region                   = s.region
      }
    }
  }
}

###############################################################################
#                                   GCS                                       #
###############################################################################

output "landing-bucket-names" {
  description = "List of buckets created for the landing project"
  value       = [for k, bucket in module.bucket-landing : "${bucket.name}"]
}

output "transformation-bucket-names" {
  description = "List of buckets created for the transformation project"
  value       = [for k, bucket in module.bucket-transformation : "${bucket.name}"]
}

###############################################################################
#                                 Bigquery                                    #
###############################################################################

output "dwh-bigquery-datasets-list" {
  description = "List of bigquery datasets created for the dwh project"
  value       = [for k, datasets in module.bigquery-datasets-dwh : "${datasets.dataset_id}"]
}

output "datamart-bigquery-datasets-list" {
  description = "List of bigquery datasets created for the datamart project"
  value       = [for k, datasets in module.bigquery-datasets-datamart : "${datasets.dataset_id}"]
}

###############################################################################
#                                Pub/Sub                                      #
###############################################################################

output "landing-pubsub-list" {
  description = "List of pubsub topics and subscriptions created for the landing project"
  value = {
    for t in module.pubsub-landing : t.topic.name => {
      name = t.topic.name
      id   = t.topic.id
      subscriptions = {
        for s in t.subscriptions : s.name => {
          name = s.name
          id   = s.id
        }
      }
    }
  }
}
