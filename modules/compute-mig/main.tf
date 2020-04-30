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

resource "google_compute_autoscaler" "default" {
  provider    = google-beta
  count       = var.region == null && var.autoscaler_config != null ? 1 : 0
  name        = var.name
  description = "Terraform managed."
  zone        = var.zone
  target      = google_compute_instance_group_manager.default.0.id

  autoscaling_policy {
    max_replicas    = var.autoscaler_config.max_replicas
    min_replicas    = var.autoscaler_config.min_replicas
    cooldown_period = var.autoscaler_config.cooldown_period

    dynamic cpu_utilization {
      for_each = (
        var.autoscaler_config.cpu_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.cpu_utilization_target
      }
    }

    dynamic load_balancing_utilization {
      for_each = (
        var.autoscaler_config.load_balancing_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.load_balancing_utilization_target
      }
    }

    dynamic metric {
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
  count              = var.region == null ? 1 : 0
  project            = var.project_id
  zone               = var.zone
  name               = var.name
  base_instance_name = var.name
  description        = "Terraform-managed."
  target_size        = var.target_size
  target_pools       = var.target_pools
  wait_for_instances = var.wait_for_instances
  dynamic auto_healing_policies {
    for_each = var.auto_healing_policies == null ? [] : [var.auto_healing_policies]
    iterator = config
    content {
      health_check      = config.value.health_check
      initial_delay_sec = config.value.initial_delay_sec
    }
  }
  dynamic update_policy {
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
  dynamic named_port {
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
  dynamic version {
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


resource "google_compute_region_autoscaler" "default" {
  provider    = google-beta
  count       = var.region != null && var.autoscaler_config != null ? 1 : 0
  name        = var.name
  description = "Terraform managed."
  region      = var.region
  target      = google_compute_region_instance_group_manager.default.0.id

  autoscaling_policy {
    max_replicas    = var.autoscaler_config.max_replicas
    min_replicas    = var.autoscaler_config.min_replicas
    cooldown_period = var.autoscaler_config.cooldown_period

    dynamic cpu_utilization {
      for_each = (
        var.autoscaler_config.cpu_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.cpu_utilization_target
      }
    }

    dynamic load_balancing_utilization {
      for_each = (
        var.autoscaler_config.load_balancing_utilization_target == null ? [] : [""]
      )
      content {
        target = var.autoscaler_config.load_balancing_utilization_target
      }
    }

    dynamic metric {
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
  count              = var.region != null ? 1 : 0
  project            = var.project_id
  region             = var.region
  name               = var.name
  base_instance_name = var.name
  description        = "Terraform-managed."
  target_size        = var.target_size
  target_pools       = var.target_pools
  wait_for_instances = var.wait_for_instances
  dynamic auto_healing_policies {
    for_each = var.auto_healing_policies == null ? [] : [var.auto_healing_policies]
    iterator = config
    content {
      health_check      = config.value.health_check
      initial_delay_sec = config.value.initial_delay_sec
    }
  }
  dynamic update_policy {
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
  dynamic named_port {
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
  dynamic version {
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

resource "google_compute_health_check" "default" {
  provider    = google-beta
  count       = var.health_check_config == null ? 0 : 1
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  dynamic http_health_check {
    for_each = (
      try(var.health_check_config.type, null) == "http"
      ? [var.health_check_config.check]
      : []
    )
    iterator = check
    content {
      host               = try(check.value.host, null)
      port               = try(check.value.port, null)
      port_name          = try(check.value.port_name, null)
      port_specification = try(check.value.port_specification, null)
      proxy_header       = try(check.value.proxy_header, null)
      request_path       = try(check.value.request_path, null)
      response           = try(check.value.response, null)
    }
  }

  dynamic https_health_check {
    for_each = (
      try(var.health_check_config.type, null) == "https"
      ? [var.health_check_config.check]
      : []
    )
    iterator = check
    content {
      host               = try(check.value.host, null)
      port               = try(check.value.port, null)
      port_name          = try(check.value.port_name, null)
      port_specification = try(check.value.port_specification, null)
      proxy_header       = try(check.value.proxy_header, null)
      request_path       = try(check.value.request_path, null)
      response           = try(check.value.response, null)
    }
  }

  dynamic tcp_health_check {
    for_each = (
      try(var.health_check_config.type, null) == "tcp"
      ? [var.health_check_config.check]
      : []
    )
    iterator = check
    content {
      port               = try(check.value.port, null)
      port_name          = try(check.value.port_name, null)
      port_specification = try(check.value.port_specification, null)
      proxy_header       = try(check.value.proxy_header, null)
      request            = try(check.value.request, null)
      response           = try(check.value.response, null)
    }
  }

  dynamic ssl_health_check {
    for_each = (
      try(var.health_check_config.type, null) == "ssl"
      ? [var.health_check_config.check]
      : []
    )
    iterator = check
    content {
      port               = try(check.value.port, null)
      port_name          = try(check.value.port_name, null)
      port_specification = try(check.value.port_specification, null)
      proxy_header       = try(check.value.proxy_header, null)
      request            = try(check.value.request, null)
      response           = try(check.value.response, null)
    }
  }

  dynamic http2_health_check {
    for_each = (
      try(var.health_check_config.type, null) == "http2"
      ? [var.health_check_config.check]
      : []
    )
    iterator = check
    content {
      host               = try(check.value.host, null)
      port               = try(check.value.port, null)
      port_name          = try(check.value.port_name, null)
      port_specification = try(check.value.port_specification, null)
      proxy_header       = try(check.value.proxy_header, null)
      request_path       = try(check.value.request_path, null)
      response           = try(check.value.response, null)
    }
  }

  dynamic log_config {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }

}
