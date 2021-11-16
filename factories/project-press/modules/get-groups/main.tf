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

data "google_cloud_identity_groups" "groups" {
  parent = format("customers/%s", var.config.cloudIdentityCustomerId)
}

locals {
  folders = keys(var.config.folders)

  shared_vpc_groups = flatten([for env in var.environments :
    {
      for folder in local.folders : "${env}-${folder}" =>
      format("%s%s", var.config.sharedVpcGroups[folder][env], var.config.domain != "" ? format("@%s", var.config.domain) : "") if var.config.sharedVpcGroups[folder][env] != ""
    }
  ])

  serverless_groups = flatten([for env in var.environments :
    {
      for folder in local.folders : "${env}-${folder}" =>
      format("%s%s", var.config.sharedVpcServerlessGroups[folder][env], var.config.domain != "" ? format("@%s", var.config.domain) : "") if var.config.sharedVpcServerlessGroups[folder][env] != ""
    }
  ])

  monitoring_groups = flatten([for env in var.environments :
    {
      for folder in local.folders : "${env}-${folder}" =>
      format("%s%s", var.config.monitoringGroups[folder][env], var.config.domain != "" ? format("@%s", var.config.domain) : "") if var.config.monitoringGroups[folder][env] != ""
    }
  ])

  all_groups = { for group in data.google_cloud_identity_groups.groups.groups : group.group_key[0].id => group.name }
}


