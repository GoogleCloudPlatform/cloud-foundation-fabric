/**
 * Copyright 2022 Google LLC
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

variable "billing_account_id" {
  # tfdoc:variable:source 00-bootstrap
  description = "Billing account id."
  type        = string
}

variable "custom_adv" {
  description = "Custom advertisement definitions in name => range format."
  type        = map(string)
  default = {
    cloud_dns             = "35.199.192.0/19"
    googleapis_private    = "199.36.153.8/30"
    googleapis_restricted = "199.36.153.4/30"
    rfc_1918_10           = "10.0.0.0/8"
    rfc_1918_172          = "172.16.0.0/12"
    rfc_1918_192          = "192.168.0.0/16"
    landing_untrusted_ew1 = "10.128.0.0/16"
    landing_untrusted_ew4 = "10.129.0.0/16"
    landing_trusted_ew1   = "10.132.0.0/16"
    landing_trusted_ew4   = "10.133.0.0/16"
    spoke_prod_ew1        = "10.136.0.0/16"
    spoke_prod_ew4        = "10.137.0.0/16"
    spoke_dev_ew1         = "10.144.0.0/16"
    spoke_dev_ew4         = "10.145.0.0/16"
  }
}

variable "data_dir" {
  description = "Relative path for the folder storing configuration data for network resources."
  type        = string
  default     = "data"
}

variable "dns" {
  description = "Onprem DNS resolvers"
  type        = map(list(string))
  default = {
    onprem = ["10.0.200.3"]
  }
}

variable "folder_id" {
  # tfdoc:variable:source 01-resman
  description = "Folder to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created."
  type        = string
  default     = null
  validation {
    condition = (
      var.folder_id == null ||
      can(regex("folders/[0-9]{8,}", var.folder_id))
    )
    error_message = "Invalid folder_id. Should be in 'folders/nnnnnnnnnnn' format."
  }
}

variable "gke" {
  #tfdoc:variable:source 01-resman
  description = ""
  type = map(object({
    folder_id = string
    sa        = string
    gcs       = string
  }))
  default = {}
}

variable "l7ilb_subnets" {
  description = "Subnets used for L7 ILBs."
  type = map(list(object({
    ip_cidr_range = string
    region        = string
  })))
  default = {
    prod = [
      { ip_cidr_range = "10.136.240.0/24", region = "europe-west1" },
      { ip_cidr_range = "10.137.240.0/24", region = "europe-west4" }
    ]
    dev = [
      { ip_cidr_range = "10.144.240.0/24", region = "europe-west1" },
      { ip_cidr_range = "10.145.240.0/24", region = "europe-west4" }
    ]
  }
}

variable "organization" {
  # tfdoc:variable:source 00-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 00-bootstrap
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "project_factory_sa" {
  # tfdoc:variable:source 01-resman
  description = "IAM emails for project factory service accounts"
  type        = map(string)
  default     = {}
}

variable "psa_ranges" {
  description = "IP ranges used for Private Service Access (e.g. CloudSQL)."
  type        = map(map(string))
  default = {
    prod = {
      cloudsql-mysql     = "10.136.250.0/24"
      cloudsql-sqlserver = "10.136.251.0/24"
    }
    dev = {
      cloudsql-mysql     = "10.144.250.0/24"
      cloudsql-sqlserver = "10.144.251.0/24"
    }
  }
}

variable "router_configs" {
  description = "Configurations for CRs and onprem routers."
  type = map(object({
    adv = object({
      custom  = list(string)
      default = bool
    })
    asn = number
  }))
  default = {
    onprem-ew1 = {
      asn = "65534"
      adv = null
      # adv = { default = false, custom = [] }
    }
    landing-untrusted-ew1 = { asn = "64512", adv = null }
    landing-untrusted-ew4 = { asn = "64512", adv = null }
  }
}

variable "vpn_onprem_configs" {
  description = "VPN gateway configuration for onprem interconnection."
  type = map(object({
    adv = object({
      default = bool
      custom  = list(string)
    })
    session_range = string
    peer = object({
      address   = string
      asn       = number
      secret_id = string
    })
  }))
  default = {
    landing-untrusted-ew1 = {
      adv = {
        default = false
        custom = [
          "cloud_dns",
          "googleapis_restricted",
          "googleapis_private",
          "landing_trusted_ew1",
          "landing_trusted_ew4",
          "landing_untrusted_ew1",
          "landing_untrusted_ew4",
          "spoke_dev_ew1",
          "spoke_dev_ew4",
          "spoke_prod_ew1",
          "spoke_prod_ew4"
        ]
      }
      session_range = "169.254.1.0/29"
      peer = {
        address   = "8.8.8.8"
        asn       = 65534
        secret_id = "foobar"
      }
    }
  }
}
