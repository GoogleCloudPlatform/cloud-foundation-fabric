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

resource "google_compute_autoscaler" "default" {
  provider    = google-beta
  count       = var.regional || var.autoscaler_config == null ? 0 : 1
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."
  zone        = var.location
  target      = google_compute_instance_group_manager.default.0.id

  autoscaling_policy {
    max_replicas    = var.autoscaler_config.max_replicas
    min_replicas    = var.autoscaler_config.min_replicas
    cooldown_period = var.autoscaler_config.cooldown_period

    dynamic "cpu_utilization" {
      for_each = (
        var.autoscaler_config.cpu_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.cpu_utilization_target
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = (
        var.autoscaler_config.load_balancing_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.load_balancing_utilization_target
      }
    }

    dynamic "metric" {
      for_each = (
        var.autoscaler_config.metric == null
        ? []
        : [var.autoscaler_config.metric]
      )
      iterator = config
      content {
        name                       = config.value.name
        single_instance_assignment = config.value.single_instance_assignment
        target                     = config.value.target
        type                       = config.value.type
        filter                     = config.value.filter
      }
    }
  }
}


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

resource "google_compute_region_autoscaler" "default" {
  provider    = google-beta
  count       = var.regional && var.autoscaler_config != null ? 1 : 0
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."
  region      = var.location
  target      = google_compute_region_instance_group_manager.default.0.id

  autoscaling_policy {
    max_replicas    = var.autoscaler_config.max_replicas
    min_replicas    = var.autoscaler_config.min_replicas
    cooldown_period = var.autoscaler_config.cooldown_period

    dynamic "cpu_utilization" {
      for_each = (
        var.autoscaler_config.cpu_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.cpu_utilization_target
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = (
        var.autoscaler_config.load_balancing_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.load_balancing_utilization_target
      }
    }

    dynamic "metric" {
      for_each = (
        var.autoscaler_config.metric == null
        ? []
        : [var.autoscaler_config.metric]
      )
      iterator = config
      content {
        name                       = config.value.name
        single_instance_assignment = config.value.single_instance_assignment
        target                     = config.value.target
        type                       = config.value.type
        filter                     = config.value.filter
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

resource "google_compute_health_check" "http" {
  provider    = google-beta
  count       = try(var.health_check_config.type, null) == "http" ? 1 : 0
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  http_health_check {
    host               = try(var.health_check_config.check.host, null)
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request_path       = try(var.health_check_config.check.request_path, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "https" {
  provider    = google-beta
  count       = try(var.health_check_config.type, null) == "https" ? 1 : 0
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  https_health_check {
    host               = try(var.health_check_config.check.host, null)
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request_path       = try(var.health_check_config.check.request_path, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "tcp" {
  provider    = google-beta
  count       = try(var.health_check_config.type, null) == "tcp" ? 1 : 0
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  tcp_health_check {
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request            = try(var.health_check_config.check.request, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "ssl" {
  provider    = google-beta
  count       = try(var.health_check_config.type, null) == "ssl" ? 1 : 0
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  ssl_health_check {
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request            = try(var.health_check_config.check.request, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "http2" {
  provider    = google-beta
  count       = try(var.health_check_config.type, null) == "http2" ? 1 : 0
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  http2_health_check {
    host               = try(var.health_check_config.check.host, null)
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request_path       = try(var.health_check_config.check.request_path, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}
