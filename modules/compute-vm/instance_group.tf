/**
 * Copyright 2019 Google LLC
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

resource "google_compute_instance_group" "unmanaged" {
  count = (
    var.group != null && ! var.use_instance_template ? 1 : 0
  )
  project = var.project_id
  network = (
    length(var.network_interfaces) > 0
    ? var.network_interfaces.0.network
    : ""
  )
  zone        = var.zone
  name        = var.name
  description = "Terraform-managed."
  instances = [
    for name, instance in google_compute_instance.default : instance.self_link
  ]
  dynamic named_port {
    for_each = var.group.named_ports != null ? var.group.named_ports : {}
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
}

resource "google_compute_instance_group_manager" "managed" {
  count = (
    var.group_manager != null && var.use_instance_template
    ? var.group_manager.regional ? 0 : 1
    : 0
  )
  project            = var.project_id
  zone               = var.zone
  name               = var.name
  base_instance_name = var.name
  description        = "Terraform-managed."
  target_size        = var.group_manager.target_size
  target_pools = (
    var.group_manager.options == null
    ? null
    : var.group_manager.options.target_pools
  )
  wait_for_instances = (
    var.group_manager.options == null
    ? null
    : var.group_manager.options.wait_for_instances
  )
  dynamic auto_healing_policies {
    for_each = (
      var.group_manager.auto_healing_policies == null
      ? []
      : [var.group_manager.auto_healing_policies]
    )
    iterator = config
    content {
      health_check      = config.value.health_check
      initial_delay_sec = config.value.initial_delay_sec
    }
  }
  dynamic update_policy {
    for_each = (
      var.group_manager.update_policy == null
      ? []
      : [var.group_manager.update_policy]
    )
    iterator = config
    content {
      type           = config.value.type
      minimal_action = config.value.minimal_action
      min_ready_sec  = config.value.min_ready_sec
      max_surge_fixed = (
        config.value.max_surge_type == "fixed" ? config.value.max_surge : null
      )
      max_surge_percent = (
        config.value.max_surge_type == "percent" ? config.value.max_surge : null
      )
      max_unavailable_fixed = (
        config.value.max_unavailable_type == "fixed" ? config.value.max_unavailable : null
      )
      max_unavailable_percent = (
        config.value.max_unavailable_type == "percent" ? config.value.max_unavailable : null
      )
    }
  }
  dynamic named_port {
    for_each = var.group_manager.named_ports != null ? var.group_manager.named_ports : {}
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
  version {
    name              = "${var.name}-default"
    instance_template = google_compute_instance_template.default.0.self_link
  }
  dynamic version {
    for_each = (
      var.group_manager.versions == null ? [] : [var.group_manager.versions]
    )
    iterator = config
    content {
      name              = config.value.name
      instance_template = config.value.instance_template
      target_size {
        fixed   = config.value.target_type == "fixed" ? config.value.target_size : null
        percent = config.value.target_type == "percent" ? config.value.target_size : null
      }
    }
  }
}

resource "google_compute_region_instance_group_manager" "managed" {
  count = (
    var.group_manager != null && var.use_instance_template
    ? var.group_manager.regional ? 1 : 0
    : 0
  )
  project            = var.project_id
  region             = var.region
  name               = var.name
  base_instance_name = var.name
  description        = "Terraform-managed."
  target_size        = var.group_manager.target_size
  target_pools = (
    var.group_manager.options == null
    ? null
    : var.group_manager.options.target_pools
  )
  wait_for_instances = (
    var.group_manager.options == null
    ? null
    : var.group_manager.options.wait_for_instances
  )
  dynamic auto_healing_policies {
    for_each = (
      var.group_manager.auto_healing_policies == null
      ? []
      : [var.group_manager.auto_healing_policies]
    )
    iterator = config
    content {
      health_check      = config.value.health_check
      initial_delay_sec = config.value.initial_delay_sec
    }
  }
  dynamic update_policy {
    for_each = (
      var.group_manager.update_policy == null
      ? []
      : [var.group_manager.update_policy]
    )
    iterator = config
    content {
      type           = config.value.type
      minimal_action = config.value.minimal_action
      min_ready_sec  = config.value.min_ready_sec
      max_surge_fixed = (
        config.value.max_surge_type == "fixed" ? config.value.max_surge : null
      )
      max_surge_percent = (
        config.value.max_surge_type == "percent" ? config.value.max_surge : null
      )
      max_unavailable_fixed = (
        config.value.max_unavailable_type == "fixed" ? config.value.max_unavailable : null
      )
      max_unavailable_percent = (
        config.value.max_unavailable_type == "percent" ? config.value.max_unavailable : null
      )
    }
  }
  dynamic named_port {
    for_each = var.group.named_ports
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
  version {
    name              = "${var.name}-default"
    instance_template = google_compute_instance_template.default.0.self_link
  }
  dynamic version {
    for_each = (
      var.group_manager.versions == null ? [] : [var.group_manager.versions]
    )
    iterator = config
    content {
      name              = config.value.name
      instance_template = config.value.instance_template
      target_size {
        fixed   = config.value.target_type == "fixed" ? config.value.target_size : null
        percent = config.value.target_type == "percent" ? config.value.target_size : null
      }
    }
  }
}
