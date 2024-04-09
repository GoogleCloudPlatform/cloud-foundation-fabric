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

# tfdoc:file:description GCVE private cloud for development environment.
locals {
  groups_gcve = {
    for k, v in var.groups_gcve : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }
  peer_network = {
    for k, v in var.vpc_self_links : k => (
      trimprefix(v, "https://www.googleapis.com/compute/v1/")
    )
  }
}

module "gcve-pc" {
  source             = "../../../../blueprints/gcve/pc-minimal"
  billing_account_id = var.billing_account.id
  folder_id          = var.folder_ids.gcve-prod
  project_id         = "gcve-2"
  groups             = local.groups_gcve
  iam                = var.iam
  labels             = merge(var.labels, { environment = "prod" })
  prefix             = "${var.prefix}-prod"
  project_services   = var.project_services

  network_peerings = {
    prod-spoke-ven = {
      peer_network           = local.peer_network.prod-spoke-0
      peer_project_id        = var.host_project_ids.prod-spoke-0
      configure_peer_network = true
      custom_routes = {
        export_to_peer   = true
        import_from_peer = true
        export_to_ven    = true
        import_from_ven  = true
      }
    }
  }

  private_cloud_configs = var.private_cloud_configs


  gcve_monitoring = var.gcve_monitoring

  /*
  gcve_monitoring = {
    vm_mon_name = var.gcve_monitoring.vm_mon_name
    vm_mon_type = var.gcve_monitoring.vm_mon_type
    vm_mon_zone = var.gcve_monitoring.vm_mon_zone
    subnetwork = var.gcve_monitoring.subnetwork
    sa_gcve_monitoring = var.gcve_monitoring.subnetwork
    secret_vsphere_server = var.gcve_monitoring.secret_vsphere_server 
    secret_vsphere_user = var.gcve_monitoring.secret_vsphere_user
    secret_vsphere_password = var.gcve_monitoring.secret_vsphere_password
    gcve_region = var.gcve_monitoring.gcve_region
    hc_interval_sec = var.gcve_monitoring.hc_interval_sec
    hc_timeout_sec = var.gcve_monitoring.hc_timeout_sec
    hc_healthy_threshold = var.gcve_monitoring.hc_healthy_threshold
    hc_unhealthy_threshold = var.gcve_monitoring.hc_unhealthy_threshold
    initial_delay_sec = var.gcve_monitoring.initial_delay_sec
    create_dashboards = var.gcve_monitoring.create_dashboards
    network_project_id = var.host_project_ids.prod-spoke-0
    network_self_link = var.vpc_self_links.prod-spoke-0
  }
  */
}
