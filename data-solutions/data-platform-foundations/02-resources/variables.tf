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
  type = map(object({
    iam      = map(list(string))
    location = string
  }))
  default = {
    bq_datamart_dataset = {
      location = "EU"
      iam = {
        # "roles/bigquery.dataOwner"  = []
        # "roles/bigquery.dataEditor" = []
        # "roles/bigquery.dataViewer" = []
      }
    }
  }
}

variable "dwh_bq_datasets" {
  description = "DWH Bigquery datasets"
  type = map(object({
    location = string
    iam      = map(list(string))
  }))
  default = {
    bq_raw_dataset = {
      iam      = {}
      location = "EU"
    }
  }
}

variable "landing_buckets" {
  description = "List of landing buckets to create"
  type = map(object({
    location = string
    name     = string
  }))
  default = {
    raw-data = {
      location = "EU"
      name     = "raw-data"
    }
    data-schema = {
      location = "EU"
      name     = "data-schema"
    }
  }
}

variable "landing_pubsub" {
  description = "List of landing pubsub topics and subscriptions to create"
  type = map(map(object({
    iam    = map(list(string))
    labels = map(string)
    options = object({
      ack_deadline_seconds       = number
      message_retention_duration = number
      retain_acked_messages      = bool
      expiration_policy_ttl      = number
    })
  })))
  default = {
    landing-1 = {
      sub1 = {
        iam = {
          # "roles/pubsub.subscriber" = []
        }
        labels  = {}
        options = null
      }
      sub2 = {
        iam     = {}
        labels  = {},
        options = null
      },
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


variable "service_account_names" {
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
  type = map(object({
    location = string
    name     = string
  }))
  default = {
    temp = {
      location = "EU"
      name     = "temp"
    },
    templates = {
      location = "EU"
      name     = "templates"
    },
  }
}

variable "transformation_subnets" {
  description = "List of subnets to create in the transformation Project."
  type = list(object({
    ip_cidr_range      = string
    name               = string
    region             = string
    secondary_ip_range = map(string)
  }))
  default = [
    {
      ip_cidr_range      = "10.1.0.0/20"
      name               = "transformation-subnet"
      region             = "europe-west3"
      secondary_ip_range = {}
    },
  ]
}

variable "transformation_vpc_name" {
  description = "Name of the VPC created in the transformation Project."
  type        = string
  default     = "transformation-vpc"
}

variable "service_encryption_key_ids" {
  description = "Cloud KMS encryption key in {LOCATION => [KEY_URL]} format. Keys belong to existing project."
  type = object({
    multiregional = string
    global        = string
  })
  default = {
    multiregional = null
    global        = null
  }
}
