# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# common variables used for examples

variable "bucket" {
  default = "bucket"
}

variable "billing_account_id" {
  default = "123456-123456-123456"
}

variable "ca_pool_id" {
  default = "ca-pool-id"
}

variable "group_email" {
  default = "organization-admins@example.org"
}

variable "organization_id" {
  default = "organizations/1122334455"
}

variable "folder_id" {
  default = "folders/1122334455"
}

variable "prefix" {
  default = "test"
}

variable "project_id" {
  default = "project-id"
}

variable "project_number" {
  default = "123"
}

variable "region" {
  default = "europe-west8"
}

variable "regions" {
  default = {
    primary   = "europe-west8"
    secondary = "europe-west9"
  }
}

variable "service_account" {
  default = {
    id        = "service_account_id"
    email     = "sa1@sa.example"
    iam_email = "serviceAccount:sa1@sa.example"
  }
}

variable "subnet" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "subnet_self_link"
  }
}

variable "subnets" {
  default = {
    primary = {
      name      = "primary"
      region    = "europe-west8"
      cidr      = "10.0.16.0/24"
      self_link = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west8/subnetworks/primary"
    }
    secondary = {
      name      = "secondary"
      region    = "europe-west89"
      cidr      = "10.0.16.0/24"
      self_link = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west9/subnetworks/secondary"
    }
  }
}

variable "subnet_psc_1" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west8/subnetworks/subnet"
  }
}

variable "subnet_psc_2" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "subnet_self_link"
  }
}

variable "subnet1" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "subnet_self_link"
  }
}

variable "subnet2" {
  default = {
    name      = "subnet_name"
    region    = "subnet_region"
    cidr      = "subnet_cidr"
    self_link = "subnet_self_link"
  }
}

variable "vpc" {
  default = {
    name      = "vpc-name"
    self_link = "projects/xxx/global/networks/aaa"
    id        = "projects/xxx/global/networks/aaa"
  }
}

variable "vpc1" {
  default = {
    name      = "vpc-name"
    self_link = "projects/xxx/global/networks/bbb"
  }
}

variable "vpc2" {
  default = {
    name      = "vpc2-name"
    self_link = "projects/xxx/global/networks/ccc"
  }
}

variable "zone" {
  default = "zone"
}
