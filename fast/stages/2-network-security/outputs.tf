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

locals {
  security_profile_group_ids = {
    dev = format(
      "//networksecurity.googleapis.com/%s",
      try(google_network_security_security_profile_group.dev.id, "")
    )
    prod = format(
      "//networksecurity.googleapis.com/%s",
      try(google_network_security_security_profile_group.prod.id, "")
    )
  }
  tfvars = {
    association_ids = {
      dev = {
        for k, v in google_network_security_firewall_endpoint_association.dev :
        k => v.id
      }
      prod = {
        for k, v in google_network_security_firewall_endpoint_association.prod :
        k => v.id
      }
    }
    endpoint_ids = {
      for _, v in google_network_security_firewall_endpoint.firewall_endpoint
      : v.location => v.id
    }
    firewall_policy_ids = {
      dev  = module.dev-spoke-firewall-policy.id
      prod = module.prod-spoke-firewall-policy.id
    }
    security_profile_group_ids = local.security_profile_group_ids
    quota_project_id           = module.ngfw-quota-project.id
  }
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/2-nsec.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/2-nsec.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

# outputs

output "ngfw_enterprise_endpoint_ids" {
  description = "The NGFW Enterprise endpoint ids."
  value       = local.tfvars.endpoint_ids
}

output "ngfw_enterprise_endpoints_quota_project" {
  description = "The NGFW Enterprise endpoints quota project."
  value       = module.ngfw-quota-project.id
}
