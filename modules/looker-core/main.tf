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
  bootstrap_oauth_client = var.oauth_config.client_secret == null || var.oauth_config.client_id == null
  looker_instance_name   = "${local.prefix}${var.name}"
  oauth_client_id        = local.bootstrap_oauth_client ? google_iap_client.looker_client[0].client_id : var.oauth_config.client_id
  oauth_client_secret    = local.bootstrap_oauth_client ? google_iap_client.looker_client[0].secret : var.oauth_config.client_secret
  prefix                 = var.prefix == null ? "" : "${var.prefix}-"
}

resource "google_looker_instance" "looker" {
  project            = var.project_id
  name               = local.looker_instance_name
  consumer_network   = try(var.network_config.psa_config.network, null)
  platform_edition   = var.platform_edition
  private_ip_enabled = try(var.network_config.psa_config.enable_private_ip, null)
  public_ip_enabled  = coalesce(var.network_config.public, false) || try(var.network_config.psa_config.enable_public_ip, false)
  region             = var.region
  reserved_range     = try(var.network_config.psa_config.allocated_ip_range, null)

  oauth_config {
    client_id     = local.oauth_client_id
    client_secret = local.oauth_client_secret
  }

  dynamic "admin_settings" {
    for_each = var.admin_settings != null ? [""] : []
    content {
      allowed_email_domains = var.admin_settings.allowed_email_domains
    }
  }
  dynamic "custom_domain" {
    for_each = var.custom_domain != null ? [""] : []
    content {
      domain = var.custom_domain
    }
  }
  dynamic "deny_maintenance_period" {
    for_each = var.maintenance_config.deny_maintenance_period != null ? [1] : []
    content {
      start_date {
        year  = var.maintenance_config.deny_maintenance_period.start_date.year
        month = var.maintenance_config.deny_maintenance_period.start_date.month
        day   = var.maintenance_config.deny_maintenance_period.start_date.day
      }
      end_date {
        year  = var.maintenance_config.deny_maintenance_period.start_date.year
        month = var.maintenance_config.deny_maintenance_period.start_date.month
        day   = var.maintenance_config.deny_maintenance_period.start_date.day
      }
      time {
        hours   = var.maintenance_config.deny_maintenance_period.start_times.hours
        minutes = var.maintenance_config.deny_maintenance_period.start_times.minutes
        seconds = var.maintenance_config.deny_maintenance_period.start_times.seconds
        nanos   = var.maintenance_config.deny_maintenance_period.start_times.nanos
      }
    }
  }
  dynamic "encryption_config" {
    for_each = var.encryption_config != null ? [""] : []
    content {
      kms_key_name = var.encryption_config.kms_key_name
    }
  }
  dynamic "maintenance_window" {
    for_each = var.maintenance_config.maintenance_window != null ? [""] : []
    content {
      day_of_week = var.maintenance_config.maintenance_window.day
      start_time {
        hours   = var.maintenance_config.maintenance_window.start_times.hours
        minutes = var.maintenance_config.maintenance_window.start_times.minutes
        seconds = var.maintenance_config.maintenance_window.start_times.seconds
        nanos   = var.maintenance_config.maintenance_window.start_times.nanos
      }
    }
  }
  lifecycle {
    ignore_changes = [
      oauth_config # do not replace target oauth client updated on the console with default one
    ]
  }
}


# Only "Organization Internal" brands can be created programmatically via API. To convert it into an external brands please use the GCP Console.
resource "google_iap_brand" "looker_brand" {
  count         = local.bootstrap_oauth_client ? 1 : 0
  support_email = var.oauth_config.support_email
  #  application_title = "Looker Core Application"
  application_title = "Cloud IAP protected Application"
  project           = var.project_id
}

# Only internal org clients can be created via declarative tools. External clients must be manually created via the GCP console.
# This is a temporary IAP oauth client to be replaced after Looker Core is provisioned.
resource "google_iap_client" "looker_client" {
  count        = local.bootstrap_oauth_client ? 1 : 0
  display_name = "Looker Core default oauth client."
  brand        = google_iap_brand.looker_brand[0].name
}
