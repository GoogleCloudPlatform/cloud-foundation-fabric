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
  _logging_metrics_factory_data_raw = merge([
    for f in try(fileset(var.factories_config.logging_metrics, "*.yaml"), []) :
    yamldecode(file("${var.factories_config.logging_metrics}/${f}"))
  ]...)
  _logging_metrics_factory_data = {
    for k, v in local._logging_metrics_factory_data_raw :
    k => merge({
      name             = k
      description      = null
      filter           = null
      value_extractor  = null
      label_extractors = null
      bucket_name      = null
      disabled         = null
      metric_descriptor = {
        metric_kind = null
        value_type  = null
        labels = {
          key         = null
          description = null
          value_type  = null
        }
      }
      bucket_options = {}
    }, v)
  }
  metrics = merge(local._logging_metrics_factory_data, var.logging_metrics)
}

resource "google_logging_metric" "default" {
  for_each    = local.metrics
  project     = local.project.project_id
  filter      = each.value.filter
  name        = each.value.name
  disabled    = each.value.disabled
  description = each.value.description
  bucket_name = each.value.bucket_name
  metric_descriptor {
    metric_kind = try(each.value.metric_descriptor.metric_kind, null)
    value_type  = try(each.value.metric_descriptor.value_type, null)
    unit        = try(each.value.metric_descriptor.unit, 1)
    dynamic "labels" {
      for_each = try(each.value.metric_descriptor.labels, {})
      content {
        key         = labels.value.key
        description = labels.value.description
        value_type  = labels.value.value_type
      }
    }
  }
  value_extractor  = each.value.value_extractor
  label_extractors = each.value.label_extractors
  dynamic "bucket_options" {
    for_each = try(each.value.bucket_options, {})
    content {
      dynamic "linear_buckets" {
        for_each = lookup(each.value.bucket_options, "linear_buckets", null)[*]
        content {
          num_finite_buckets = each.value.bucket_options.linear_buckets.num_finite_buckets
          width              = each.value.bucket_options.linear_buckets.width
          offset             = each.value.bucket_options.linear_buckets.offset
        }
      }
      dynamic "exponential_buckets" {
        for_each = lookup(each.value.bucket_options, "exponential_buckets", null)[*]
        content {
          num_finite_buckets = each.value.bucket_options.exponential_buckets.num_finite_buckets
          growth_factor      = each.value.bucket_options.exponential_buckets.growth_factor
          scale              = each.value.bucket_options.exponential_buckets.scale
        }
      }
      dynamic "explicit_buckets" {
        for_each = lookup(each.value.bucket_options, "explicit_buckets", null)[*]
        content {
          bounds = each.value.bucket_options.explicit_buckets.bounds
        }
      }
    }
  }
}
