# Copyright 2020 Google LLC
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

variable "datamart_bq_datasets" {
  description = "Datamart Bigquery datasets"
  type        = map(any)
  default = {
    bq_datamart_dataset = {
      id       = "bq_datamart_dataset"
      location = "EU",
    }
  }
}

variable "dwh_bq_datasets" {
  description = "DWH Bigquery datasets"
  type        = map(any)
  default = {
    bq_raw_dataset = {
      id       = "bq_raw_dataset"
      location = "EU",
    }
  }
}

variable "landing_buckets" {
  description = "List of landing buckets to create"
  type        = map(any)
  default = {
    raw-data = {
      name     = "raw-data"
      location = "EU"
    },
    data-schema = {
      name     = "data-schema"
      location = "EU"
    },
  }
}

variable "landing_pubsub" {
  description = "List of landing pubsub topics and subscriptions to create"
  type        = map(any)
  default = {
    landing_1 = {
      name = "landing-1"
      subscriptions = {
        sub1 = {
          labels = {},
          options = {
            ack_deadline_seconds       = null
            message_retention_duration = null
            retain_acked_messages      = false
            expiration_policy_ttl      = null
          }
        },
        sub2 = {
          labels = {},
          options = {
            ack_deadline_seconds       = null
            message_retention_duration = null
            retain_acked_messages      = false
            expiration_policy_ttl      = null
          }
        },
      }
      subscription_iam = {
        sub1 = {
          "roles/pubsub.subscriber" = []
        }
        sub2 = {
          "roles/pubsub.subscriber" = []
        }
      }
    }
  }
}

variable "landing_service_account" {
  description = "landing service accounts list."
  type        = string
  default     = "sa-landing"
}

variable "project_ids" {
  description = "Project IDs."
  type = object({
    datamart       = string
    dwh            = string
    landing        = string
    services       = string
    transformation = string
  })
}


variable "project_service_account" {
  description = "Project service accounts list."
  type = object({
    datamart       = string
    dwh            = string
    landing        = string
    services       = string
    transformation = string
  })
  default = {
    datamart       = "sa-datamart"
    dwh            = "sa-datawh"
    landing        = "sa-landing"
    services       = "sa-services"
    transformation = "sa-transformation"
  }
}

variable "transformation_buckets" {
  description = "List of transformation buckets to create"
  type        = map(any)
  default = {
    temp = {
      name     = "temp"
      location = "EU"
    },
    templates = {
      name     = "templates"
      location = "EU"
    },
  }
}

variable "transformation_subnets" {
  description = "List of subnets to create in the transformation Project."
  type        = list(any)
  default = [
    {
      name               = "transformation-subnet",
      ip_cidr_range      = "10.1.0.0/20",
      secondary_ip_range = {},
      region             = "europe-west3"
    },
  ]
}

variable "transformation_vpc_name" {
  description = "Name of the VPC created in the transformation Project."
  type        = string
  default     = "transformation-vpc"
}
