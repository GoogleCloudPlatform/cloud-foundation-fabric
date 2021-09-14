/**
 * Copyright 2021 Google LLC
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
  descriptive_name = var.descriptive_name != null ? var.descriptive_name : "${local.prefix}${var.name}"
  group_iam_roles  = distinct(flatten(values(var.group_iam)))
  group_iam = {
    for r in local.group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local.group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local.group_iam[role], [])
    )
  }
  iam_additive_pairs = flatten([
    for role, members in var.iam_additive : [
      for member in members : { role = role, member = member }
    ]
  ])
  iam_additive_member_pairs = flatten([
    for member, roles in var.iam_additive_members : [
      for role in roles : { role = role, member = member }
    ]
  ])
  iam_additive = {
    for pair in concat(local.iam_additive_pairs, local.iam_additive_member_pairs) :
    "${pair.role}-${pair.member}" => pair
  }
  parent_type = var.parent == null ? null : split("/", var.parent)[0]
  parent_id   = var.parent == null ? null : split("/", var.parent)[1]
  prefix      = var.prefix == null ? "" : "${var.prefix}-"
  project = (
    var.project_create
    ? try(google_project.project.0, null)
    : try(data.google_project.project.0, null)
  )
  logging_sinks = coalesce(var.logging_sinks, {})
  sink_type_destination = {
    gcs      = "storage.googleapis.com"
    bigquery = "bigquery.googleapis.com"
    pubsub   = "pubsub.googleapis.com"
    logging  = "logging.googleapis.com"
  }
  sink_bindings = {
    for type in ["gcs", "bigquery", "pubsub", "logging"] :
    type => {
      for name, sink in local.logging_sinks :
      name => sink
      if sink.iam && sink.type == type
    }
  }
  service_encryption_key_ids = flatten([
    for service in keys(var.service_encryption_key_ids) : [
      for key in var.service_encryption_key_ids[service] : {
        service = service
        key     = key
      } if key != null
    ]
  ])
}


data "google_project" "project" {
  count      = var.project_create ? 0 : 1
  project_id = "${local.prefix}${var.name}"
}

resource "google_project" "project" {
  count               = var.project_create ? 1 : 0
  org_id              = local.parent_type == "organizations" ? local.parent_id : null
  folder_id           = local.parent_type == "folders" ? local.parent_id : null
  project_id          = "${local.prefix}${var.name}"
  name                = local.descriptive_name
  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network
  labels              = var.labels
}

resource "google_project_iam_custom_role" "roles" {
  for_each    = var.custom_roles
  project     = local.project.project_id
  role_id     = each.key
  title       = "Custom role ${each.key}"
  description = "Terraform-managed"
  permissions = each.value
}

resource "google_compute_project_metadata_item" "oslogin_meta" {
  count   = var.oslogin ? 1 : 0
  project = local.project.project_id
  key     = "enable-oslogin"
  value   = "TRUE"
  # depend on services or it will fail on destroy
  depends_on = [google_project_service.project_services]
}

resource "google_resource_manager_lien" "lien" {
  count        = var.lien_reason != "" ? 1 : 0
  parent       = "projects/${local.project.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "created-by-terraform"
  reason       = var.lien_reason
}

resource "google_project_service" "project_services" {
  for_each                   = toset(var.services)
  project                    = local.project.project_id
  service                    = each.value
  disable_on_destroy         = var.service_config.disable_on_destroy
  disable_dependent_services = var.service_config.disable_dependent_services
}

# IAM notes:
# - external users need to have accepted the invitation email to join
# - oslogin roles also require role to list instances
# - additive (non-authoritative) roles might fail due to dynamic values

resource "google_project_iam_binding" "authoritative" {
  for_each = local.iam
  project  = local.project.project_id
  role     = each.key
  members  = each.value
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}

resource "google_project_iam_member" "additive" {
  for_each = (
    length(var.iam_additive) + length(var.iam_additive_members) > 0
    ? local.iam_additive
    : {}
  )
  project = local.project.project_id
  role    = each.value.role
  member  = each.value.member
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}

resource "google_project_iam_member" "oslogin_iam_serviceaccountuser" {
  for_each = var.oslogin ? toset(distinct(concat(var.oslogin_admins, var.oslogin_users))) : toset([])
  project  = local.project.project_id
  role     = "roles/iam.serviceAccountUser"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_compute_viewer" {
  for_each = var.oslogin ? toset(distinct(concat(var.oslogin_admins, var.oslogin_users))) : toset([])
  project  = local.project.project_id
  role     = "roles/compute.viewer"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_admins" {
  for_each = var.oslogin ? toset(var.oslogin_admins) : toset([])
  project  = local.project.project_id
  role     = "roles/compute.osAdminLogin"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_users" {
  for_each = var.oslogin ? toset(var.oslogin_users) : toset([])
  project  = local.project.project_id
  role     = "roles/compute.osLogin"
  member   = each.value
}

resource "google_project_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  project    = local.project.project_id
  constraint = each.key

  dynamic "boolean_policy" {
    for_each = each.value == null ? [] : [each.value]
    iterator = policy
    content {
      enforced = policy.value
    }
  }

  dynamic "restore_policy" {
    for_each = each.value == null ? [""] : []
    content {
      default = true
    }
  }
}

resource "google_project_organization_policy" "list" {
  for_each   = var.policy_list
  project    = local.project.project_id
  constraint = each.key

  dynamic "list_policy" {
    for_each = each.value.status == null ? [] : [each.value]
    iterator = policy
    content {
      inherit_from_parent = policy.value.inherit_from_parent
      suggested_value     = policy.value.suggested_value
      dynamic "allow" {
        for_each = policy.value.status ? [""] : []
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
      dynamic "deny" {
        for_each = policy.value.status ? [] : [""]
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
    }
  }

  dynamic "restore_policy" {
    for_each = each.value.status == null ? [true] : []
    content {
      default = true
    }
  }
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count   = try(var.shared_vpc_host_config.enabled, false) ? 1 : 0
  project = local.project.project_id
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each = (
    try(var.shared_vpc_host_config.enabled, false)
    ? toset(coalesce(var.shared_vpc_host_config.service_projects, []))
    : toset([])
  )
  host_project    = local.project.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.shared_vpc_host]
}

resource "google_compute_shared_vpc_service_project" "shared_vpc_service" {
  count           = try(var.shared_vpc_service_config.attach, false) ? 1 : 0
  host_project    = var.shared_vpc_service_config.host_project
  service_project = local.project.project_id
}

resource "google_logging_project_sink" "sink" {
  for_each = local.logging_sinks
  name     = each.key
  #description = "${each.key} (Terraform-managed)"
  project                = local.project.project_id
  destination            = "${local.sink_type_destination[each.value.type]}/${each.value.destination}"
  filter                 = each.value.filter
  unique_writer_identity = each.value.unique_writer

  dynamic "exclusions" {
    for_each = each.value.exclusions
    iterator = exclusion
    content {
      name   = exclusion.key
      filter = exclusion.value
    }
  }
}

resource "google_storage_bucket_iam_member" "gcs-sinks-binding" {
  for_each = local.sink_bindings["gcs"]
  bucket   = each.value.destination
  role     = "roles/storage.objectCreator"
  member   = google_logging_project_sink.sink[each.key].writer_identity
}

resource "google_bigquery_dataset_iam_member" "bq-sinks-binding" {
  for_each   = local.sink_bindings["bigquery"]
  project    = split("/", each.value.destination)[1]
  dataset_id = split("/", each.value.destination)[3]
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.sink[each.key].writer_identity
}

resource "google_pubsub_topic_iam_member" "pubsub-sinks-binding" {
  for_each = local.sink_bindings["pubsub"]
  project  = split("/", each.value.destination)[1]
  topic    = split("/", each.value.destination)[3]
  role     = "roles/pubsub.publisher"
  member   = google_logging_project_sink.sink[each.key].writer_identity
}

resource "google_project_iam_member" "bucket-sinks-binding" {
  for_each = local.sink_bindings["logging"]
  project  = split("/", each.value.destination)[1]
  role     = "roles/logging.bucketWriter"
  member   = google_logging_project_sink.sink[each.key].writer_identity
  # TODO(jccb): use a condition to limit writer-identity only to this
  # bucket
}

resource "google_logging_project_exclusion" "logging-exclusion" {
  for_each    = coalesce(var.logging_exclusions, {})
  name        = each.key
  project     = local.project.project_id
  description = "${each.key} (Terraform-managed)"
  filter      = each.value
}

resource "google_essential_contacts_contact" "contact" {
  provider                            = google-beta
  for_each                            = var.contacts
  parent                              = "projects/${local.project.project_id}"
  email                               = each.key
  language_tag                        = "en"
  notification_category_subscriptions = each.value
}

resource "google_access_context_manager_service_perimeter_resource" "service-perimeter-resource-standard" {
  count = var.service_perimeter_standard != null ? 1 : 0

  # If used, remember to uncomment 'lifecycle' block in the
  # modules/vpc-sc/google_access_context_manager_service_perimeter resource.
  perimeter_name = var.service_perimeter_standard
  resource       = "projects/${local.project.number}"
}

resource "google_access_context_manager_service_perimeter_resource" "service-perimeter-resource-bridges" {
  for_each = toset(var.service_perimeter_bridges != null ? var.service_perimeter_bridges : [])

  # If used, remember to uncomment 'lifecycle' block in the
  # modules/vpc-sc/google_access_context_manager_service_perimeter resource.
  perimeter_name = each.value
  resource       = "projects/${local.project.number}"
}

resource "google_kms_crypto_key_iam_member" "crypto_key" {
  for_each = {
    for service_key in local.service_encryption_key_ids : "${service_key.service}.${service_key.key}" => service_key if service_key != service_key.key
  }
  crypto_key_id = each.value.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${local.service_accounts_robots[each.value.service]}"
  depends_on = [
    google_project.project,
    google_project_service.project_services,
    google_project_service_identity.jit_si,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_project.project,
    data.google_storage_project_service_account.gcs_sa,
  ]
}
