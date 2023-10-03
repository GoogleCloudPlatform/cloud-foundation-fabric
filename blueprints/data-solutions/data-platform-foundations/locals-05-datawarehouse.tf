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

locals {
  _dwh_iam = flatten([
    for principal, roles in local.dwh_iam : [
      for role in roles : {
        key       = "${principal}-${role}"
        principal = principal
        role      = role
      }
    ]
  ])
  _lnd_iam = flatten([
    for principal, roles in local.lnd_iam : [
      for role in roles : {
        key       = "${principal}-${role}"
        principal = principal
        role      = role
      }
    ]
  ])
  dwh_iam_additive = {
    for binding in local._dwh_iam : binding.key => {
      role   = binding.role
      member = local.iam_principals[binding.principal]
    }
  }
  dwh_iam_auth = {
    for binding in local._dwh_iam :
    binding.role => local.iam_principals[binding.principal]...
  }
  dwh_services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "datalineage.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ])
  lnd_iam_additive = {
    for binding in local._lnd_iam : binding.key => {
      role   = binding.role
      member = local.iam_principals[binding.principal]
    }
  }
  lnd_iam_auth = {
    for binding in local._lnd_iam :
    binding.role => local.iam_principals[binding.principal]...
  }
}
