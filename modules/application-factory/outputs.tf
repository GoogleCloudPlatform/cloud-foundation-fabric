/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Module outputs.

output "artifact_registry" {
  description = "Artifact Registry repositories."
  value = {
    for k, v in merge(
      module.artifact-registry, module.artifact-registry-virtual
      ) : k => {
      id   = v.id
      name = v.name
      url  = v.url
    }
  }
}

output "bigquery" {
  description = "BigQuery datasets."
  value = {
    for k, v in module.bigquery : k => {
      dataset_id            = v.dataset_id
      id                    = v.id
      materialized_view_ids = v.materialized_view_ids
      routine_ids           = v.routine_ids
      self_link             = v.self_link
      table_ids             = v.table_ids
      view_ids              = v.view_ids
    }
  }
}

output "cloud_run" {
  description = "Cloud Run services, jobs and worker pools."
  value = {
    for k, v in module.cloud-run : k => {
      id                        = v.id
      service_account_email     = v.service_account_email
      service_account_iam_email = v.service_account_iam_email
      service_name              = v.service_name
      service_uri               = v.service_uri
      vpc_connector             = v.vpc_connector
    }
  }
}

output "cloudsql" {
  description = "Cloud SQL instances."
  value = {
    for k, v in module.cloudsql : k => {
      connection_name              = v.connection_name
      connection_names             = v.connection_names
      dns_name                     = v.dns_name
      dns_names                    = v.dns_names
      id                           = v.id
      ids                          = v.ids
      ip                           = v.ip
      ips                          = v.ips
      name                         = v.name
      names                        = v.names
      psc_service_attachment_link  = v.psc_service_attachment_link
      psc_service_attachment_links = v.psc_service_attachment_links
      self_link                    = v.self_link
      self_links                   = v.self_links
    }
  }
}

output "compute_vm" {
  description = "Compute instances."
  value = {
    for k, v in module.compute-vm : k => {
      external_ip               = v.external_ip
      group_self_link           = try(v.group.self_link, null)
      id                        = v.id
      internal_ip               = v.internal_ip
      internal_ips              = v.internal_ips
      self_link                 = v.self_link
      service_account_email     = v.service_account_email
      service_account_iam_email = v.service_account_iam_email
      template_name             = v.template_name
    }
  }
}

output "context" {
  description = "Context enriched with factory-managed resources, for use in downstream modules."
  value       = local.ctx_phase_4
}

output "gcs" {
  description = "GCS buckets."
  value = {
    for k, v in module.gcs : k => {
      id   = v.id
      name = v.name
      url  = v.url
    }
  }
}

output "net_address" {
  description = "Reserved IP addresses, keyed by address name."
  value       = local.net_addresses
}

output "net_lb_app_int" {
  description = "Internal application load balancers."
  value = {
    for k, v in module.net-lb-app-int : k => {
      address               = v.address
      backend_service_ids   = v.backend_service_ids
      forwarding_rule_id    = try(v.forwarding_rule.id, null)
      group_ids             = v.group_ids
      health_check_ids      = v.health_check_ids
      id                    = v.id
      neg_ids               = v.neg_ids
      service_attachment_id = v.service_attachment_id
      url_map_id            = v.url_map_id
    }
  }
}

output "net_lb_int" {
  description = "Internal passthrough network load balancers."
  value = {
    for k, v in module.net-lb-int : k => {
      backend_service_id         = v.backend_service_id
      forwarding_rule_addresses  = v.forwarding_rule_addresses
      forwarding_rule_self_links = v.forwarding_rule_self_links
      group_self_links           = v.group_self_links
      health_check_id            = v.health_check_id
      id                         = v.id
      service_attachment_ids     = v.service_attachment_ids
    }
  }
}

output "pubsub" {
  description = "Pub/Sub topics."
  value = {
    for k, v in module.pubsub : k => {
      id              = v.id
      subscription_id = v.subscription_id
    }
  }
}

output "secret_manager" {
  description = "Secret Manager secrets."
  value = {
    for k, v in module.secret-manager : k => {
      ids         = v.ids
      version_ids = v.version_ids
    }
  }
}

output "service_accounts" {
  description = "Service accounts."
  value = {
    for k, v in module.service-accounts : k => {
      email     = v.email
      iam_email = v.iam_email
      id        = v.id
      name      = v.name
    }
  }
}
