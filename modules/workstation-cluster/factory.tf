/**
 * Copyright 2025 Google LLC
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
  _f_files = try(fileset(local._f_paths.workstation_configs, "*.yaml"), [])
  _f_paths = {
    for k, v in var.factories_config : k => v == null ? null : pathexpand(v)
  }
  _f_raw = {
    for f in local._f_files : trimsuffix(f, ".yaml") => yamldecode(file(
      "${local._f_paths.workstation_configs}/${f}"
    ))
  }
  f_workstation_configs = {
    for k, v in local._f_raw : k => {
      annotations           = try(v.annotations, null)
      display_name          = try(v.display_name, null)
      enable_audit_agent    = try(v.enable_audit_agent, null)
      iam                   = try(v.iam, {})
      iam_bindings          = try(v.iam_bindings, {})
      iam_bindings_additive = try(v.iam_bindings_additive, {})
      labels                = try(v.labels, null)
      max_workstations      = try(v.max_workstations, null)
      replica_zones         = try(v.replica_zones, null)
      timeouts              = try(v.timeouts, {})
      container = (
        lookup(v, "container", null) == null ? null : {
          args        = try(v.container.args, [])
          command     = try(v.container.command, [])
          env         = try(v.container.env, {})
          image       = try(v.container.image, null)
          run_as_user = try(v.container.run_as_user, null)
          working_dir = try(v.container.working_dir, null)
        }
      )
      encryption_key = (
        lookup(v, "encryption_key", null) == null ? null : {
          kms_key                 = try(v.encryption_key.kms_key, null)
          kms_key_service_account = try(v.encryption_key.kms_key_service_account, null)
        }
      )
      gce_instance = (
        lookup(v, "gce_instance", null) == null ? null : {
          boot_disk_size_gb            = try(v.gce_instance.boot_disk_size_gb, null)
          disable_public_ip_addresses  = try(v.gce_instance.disable_public_ip_addresses, false)
          enable_confidential_compute  = try(v.gce_instance.enable_confidential_compute, false)
          enable_nested_virtualization = try(v.gce_instance.enable_nested_virtualization, false)
          machine_type                 = try(v.gce_instance.machine_type, null)
          pool_size                    = try(v.gce_instance.pool_size, null)
          service_account              = try(v.gce_instance.service_account, null)
          service_account_scopes       = try(v.gce_instance.service_account_scopes, null)
          tags                         = try(v.gce_instance.tags, null)
          accelerators                 = try(v.gce_instance.accelerators, [])
          shielded_instance_config = (
            try(v.gce_instance.shielded_instance_config, null) == null ? null : {
              enable_secure_boot = try(
                v.gce_instance.shielded_instance_config.enable_secure_boot, false
              )
              enable_vtpm = try(
                v.gce_instance.shielded_instance_config.enable_vtpm, false
              )
              enable_integrity_monitoring = try(
                v.gce_instance.shielded_instance_config.enable_integrity_monitoring, false
              )
            }
          )
        }
      )
      persistent_directories = [
        for vv in try(v.persistent_directories, []) : {
          mount_path = try(vv.mount_path, null)
          gce_pd = try(vv.gce_pd, null) == null ? null : {
            size_gb         = try(vv.gce_pd.size_gb, null)
            fs_type         = try(vv.gce_pd.fs_type, null)
            disk_type       = try(vv.gce_pd.disk_type, null)
            source_snapshot = try(vv.gce_pd.source_snapshot, null)
            reclaim_policy  = try(vv.gce_pd.reclaim_policy, null)
          }
        }
      ]
      workstations = {
        for kk, vv in try(v.workstations, {}) : kk => {
          annotations           = try(vv.annotations, null)
          display_name          = try(vv.display_name, null)
          env                   = try(vv.env, null)
          labels                = try(vv.labels, null)
          iam                   = try(vv.iam, {})
          iam_bindings          = try(vv.iam_bindings, {})
          iam_bindings_additive = try(vv.iam_bindings_additive, {})
        }
      }
    }
  }
}
