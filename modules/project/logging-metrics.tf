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
  _logging_metrics_factory_data_raw = merge([
    for k in local.observability_factory_data_raw :
    lookup(k, "logging_metrics", {})
  ]...)
  _logging_metrics_factory_data = {
    for k, v in local._logging_metrics_factory_data_raw :
    k => {
      filter           = v.filter
      bucket_name      = try(v.bucket_name, null)
      description      = try(v.description, null)
      disabled         = try(v.disabled, null)
      label_extractors = try(v.label_extractors, null)
      value_extractor  = try(v.value_extractor, null)
      bucket_options = !can(v.bucket_options) ? null : {
        explicit_buckets = !can(v.bucket_options.explicit_buckets) ? null : {
          bounds = v.bucket_options.explicit_buckets.bounds
        }
        exponential_buckets = !can(v.bucket_options.exponential_buckets) ? null : {
          num_finite_buckets = v.bucket_options.exponential_buckets.num_finite_buckets
          growth_factor      = v.bucket_options.exponential_buckets.growth_factor
          scale              = v.bucket_options.exponential_buckets.scale
        }
        linear_buckets = !can(v.bucket_options.linear_buckets) ? null : {
          num_finite_buckets = v.bucket_options.linear_buckets.num_finite_buckets
          width              = v.bucket_options.linear_buckets.width
          offset             = v.bucket_options.linear_buckets.offset
        }
      }
      metric_descriptor = !can(v.metric_descriptor) ? null : {
        metric_kind  = v.metric_descriptor.metric_kind
        value_type   = v.metric_descriptor.value_type
        display_name = try(v.metric_descriptor.display_name, null)
        unit         = try(v.metric_descriptor.unit, null)
        labels = !can(v.metric_descriptor.labels) ? [] : [
          for vv in v.metric_descriptor.labels :
          {
            key         = vv.key
            description = try(vv.description, null)
            value_type  = try(vv.value_type, null)
          }
        ]
      }
    }
  }
  metrics = merge(local._logging_metrics_factory_data, var.logging_metrics)
}

resource "google_logging_metric" "metrics" {
  for_each         = local.metrics
  project          = local.project.project_id
  name             = each.key
  filter           = each.value.filter
  description      = each.value.description
  disabled         = each.value.disabled
  bucket_name      = each.value.bucket_name
  value_extractor  = each.value.value_extractor
  label_extractors = each.value.label_extractors

  dynamic "bucket_options" {
    for_each = each.value.bucket_options[*]
    content {
      dynamic "explicit_buckets" {
        for_each = bucket_options.value.explicit_buckets[*]
        content {
          bounds = explicit_buckets.value.bounds
        }
      }
      dynamic "exponential_buckets" {
        for_each = bucket_options.value.exponential_buckets[*]
        content {
          num_finite_buckets = exponential_buckets.value.num_finite_buckets
          growth_factor      = exponential_buckets.value.growth_factor
          scale              = exponential_buckets.value.scale
        }
      }
      dynamic "linear_buckets" {
        for_each = bucket_options.value.linear_buckets[*]
        content {
          num_finite_buckets = linear_buckets.value.num_finite_buckets
          width              = linear_buckets.value.width
          offset             = linear_buckets.value.offset
        }
      }
    }
  }
  dynamic "metric_descriptor" {
    for_each = each.value.metric_descriptor[*]
    content {
      metric_kind  = metric_descriptor.value.metric_kind
      value_type   = metric_descriptor.value.value_type
      display_name = metric_descriptor.value.display_name
      unit         = metric_descriptor.value.unit
      dynamic "labels" {
        for_each = metric_descriptor.value.labels
        content {
          key         = labels.value.key
          description = labels.value.description
          value_type  = labels.value.value_type
        }
      }
    }
  }
}
