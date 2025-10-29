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

resource "google_cloud_run_v2_service_iam_binding" "binding" {
  for_each = var.type == "SERVICE" ? var.iam : {}
  project  = local.resource.project
  location = local.resource.location
  name     = local.resource.name
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members  = [for member in each.value : lookup(local.ctx.iam_principals, member, member)]
}

resource "google_iap_web_cloud_run_service_iam_member" "member" {
  for_each               = var.service_config.iap_config == null ? toset([]) : toset(var.service_config.iap_config.iam_additive)
  project                = local.resource.project
  location               = local.resource.location
  cloud_run_service_name = local.resource.name
  role                   = "roles/iap.httpsResourceAccessor"
  member                 = lookup(local.ctx.iam_principals, each.key, each.key)
}

resource "google_iap_web_cloud_run_service_iam_binding" "binding" {
  for_each = (
    var.service_config.iap_config == null ? {}
    : length(var.service_config.iap_config.iam) == 0 ? {} : { 1 = 1 }
  )
  project                = local.resource.project
  location               = local.resource.location
  cloud_run_service_name = local.resource.name
  role                   = "roles/iap.httpsResourceAccessor"
  members                = [for member in var.service_config.iap_config.iam : lookup(local.ctx.iam_principals, member, member)]
}

# Event ARC for Cloud Run services
resource "google_eventarc_trigger" "audit_log_triggers" {
  for_each = coalesce(var.service_config.eventarc_triggers.audit_log, tomap({}))
  name     = "audit-log-${each.key}"
  location = local.resource.location
  project  = local.resource.project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }
  matching_criteria {
    attribute = "serviceName"
    value     = each.value.service
  }
  matching_criteria {
    attribute = "methodName"
    value     = each.value.method
  }
  destination {
    cloud_run_service {
      service = local.resource.name
      region  = local.resource.location
    }
  }
  service_account = var.service_config.eventarc_triggers.service_account_email
}

resource "google_eventarc_trigger" "pubsub_triggers" {
  for_each = coalesce(var.service_config.eventarc_triggers.pubsub, tomap({}))
  name     = "pubsub-${each.key}"
  location = local.resource.location
  project  = local.resource.project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  transport {
    pubsub {
      topic = each.value
    }
  }
  destination {
    cloud_run_service {
      service = local.resource.name
      region  = local.resource.location
    }
  }
  service_account = var.service_config.eventarc_triggers.service_account_email
}

resource "google_eventarc_trigger" "storage_triggers" {
  for_each = coalesce(var.service_config.eventarc_triggers.storage, tomap({}))
  name     = "storage-${each.key}"
  location = local.resource.location
  project  = local.resource.project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = each.value.bucket
  }
  destination {
    cloud_run_service {
      service = local.resource.name
      region  = local.resource.location
      path    = try(each.value.path, null)
    }
  }
  service_account = var.service_config.eventarc_triggers.service_account_email
}
