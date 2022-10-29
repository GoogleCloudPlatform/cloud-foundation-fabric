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

resource "google_compute_instance_group_manager" "default" {
  provider           = google-beta
  count              = var.regional ? 0 : 1
  project            = var.project_id
  zone               = var.location
  name               = var.name
  base_instance_name = var.name
  description        = "Terraform-managed."
  target_size        = var.target_size
  target_pools       = var.target_pools
  wait_for_instances = var.wait_for_instances
  dynamic "auto_healing_policies" {
    for_each = var.auto_healing_policies == null ? [] : [var.auto_healing_policies]
    iterator = config
    content {
      health_check      = config.value.health_check
      initial_delay_sec = config.value.initial_delay_sec
    }
  }
  dynamic "stateful_disk" {
    for_each = try(var.stateful_config.mig_config.stateful_disks, {})
    iterator = config
    content {
      device_name = config.key
      delete_rule = config.value.delete_rule
    }
  }
  dynamic "update_policy" {
    for_each = var.update_policy == null ? [] : [var.update_policy]
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
  dynamic "named_port" {
    for_each = var.named_ports == null ? {} : var.named_ports
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
  version {
    instance_template = var.default_version.instance_template
    name              = var.default_version.name
  }
  dynamic "version" {
    for_each = var.versions == null ? {} : var.versions
    iterator = version
    content {
      name              = version.key
      instance_template = version.value.instance_template
      target_size {
        fixed = (
          version.value.target_type == "fixed" ? version.value.target_size : null
        )
        percent = (
          version.value.target_type == "percent" ? version.value.target_size : null
        )
      }
    }
  }
}

locals {
  instance_group_manager = (
    var.regional ?
    google_compute_region_instance_group_manager.default :
    google_compute_instance_group_manager.default
  )
}

resource "google_compute_per_instance_config" "default" {
  for_each = try(var.stateful_config.per_instance_config, {})
  #for_each = var.stateful_config && var.stateful_config.per_instance_config == null ? {} : length(var.stateful_config.per_instance_config)
  zone = var.location
  # terraform error, solved with locals
  #instance_group_manager           = var.regional ? google_compute_region_instance_group_manager.default : google_compute_instance_group_manager.default
  instance_group_manager           = local.instance_group_manager[0].id
  name                             = each.key
  project                          = var.project_id
  minimal_action                   = try(each.value.update_config.minimal_action, null)
  most_disruptive_allowed_action   = try(each.value.update_config.most_disruptive_allowed_action, null)
  remove_instance_state_on_destroy = try(each.value.update_config.remove_instance_state_on_destroy, null)
  preserved_state {

    metadata = each.value.metadata

    dynamic "disk" {
      for_each = try(each.value.stateful_disks, {})
      #for_each = var.stateful_config.mig_config.stateful_disks == null ? {} : var.stateful_config.mig_config.stateful_disks
      iterator = config
      content {
        device_name = config.key
        source      = config.value.source
        mode        = config.value.mode
        delete_rule = config.value.delete_rule
      }
    }
  }
}

resource "google_compute_region_instance_group_manager" "default" {
  provider           = google-beta
  count              = var.regional ? 1 : 0
  project            = var.project_id
  region             = var.location
  name               = var.name
  base_instance_name = var.name
  description        = "Terraform-managed."
  target_size        = var.target_size
  target_pools       = var.target_pools
  wait_for_instances = var.wait_for_instances
  dynamic "auto_healing_policies" {
    for_each = var.auto_healing_policies == null ? [] : [var.auto_healing_policies]
    iterator = config
    content {
      health_check      = config.value.health_check
      initial_delay_sec = config.value.initial_delay_sec
    }
  }
  dynamic "stateful_disk" {
    for_each = try(var.stateful_config.mig_config.stateful_disks, {})
    iterator = config
    content {
      device_name = config.key
      delete_rule = config.value.delete_rule
    }
  }

  dynamic "update_policy" {
    for_each = var.update_policy == null ? [] : [var.update_policy]
    iterator = config
    content {
      instance_redistribution_type = config.value.instance_redistribution_type
      type                         = config.value.type
      minimal_action               = config.value.minimal_action
      min_ready_sec                = config.value.min_ready_sec
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
  dynamic "named_port" {
    for_each = var.named_ports == null ? {} : var.named_ports
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
  version {
    instance_template = var.default_version.instance_template
    name              = var.default_version.name
  }
  dynamic "version" {
    for_each = var.versions == null ? {} : var.versions
    iterator = version
    content {
      name              = version.key
      instance_template = version.value.instance_template
      target_size {
        fixed = (
          version.value.target_type == "fixed" ? version.value.target_size : null
        )
        percent = (
          version.value.target_type == "percent" ? version.value.target_size : null
        )
      }
    }
  }
}
