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

locals {
  _fs_paths = {
    config = "/etc/gitlab"
    data   = "/var/opt/gitlab"
    logs   = "/var/log/gitlab"
  }
  _mounts = [
    for k, v in var.mounts : {
      create_source = v.device_name == null
      source = (
        v.device_name == null
        ? "/run/gitlab/${coalesce(v.fs_path, k)}"
        : "/mnt/disks/gitlab-${v.device_name}/${coalesce(v.fs_path, "")}"
      )
      mountpoint = local._fs_paths[k]
    }
  ]
  cloud_config = templatefile(local.template, merge(var.config_variables, {
    create_sources = [
      for m in local._mounts : m.source if m.create_source
    ]
    disks = toset([
      for k, v in var.mounts : v.device_name if v.device_name != null
    ])
    env      = var.env,
    env_file = var.env_file,
    hostname = var.hostname
    image    = var.image
    mounts   = local._mounts
  }))
  template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )
}
