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

# tfdoc:file:description Context locals and path resolution.

locals {
  ctx = var.context
  # resolve per-resource-type paths relative to basepath
  paths = {
    for k, v in var.factories_config.paths : k => try(pathexpand(
      var.factories_config.basepath == null || startswith(v, "/") || startswith(v, ".")
      ? v
      : "${var.factories_config.basepath}/${v}"
    ), null)
  }
  # context enrichments from factory-managed resources, each one is
  # only passed to modules in later phases to avoid dependency cycles
  # phase 1: service accounts and addresses
  ctx_addresses = merge(local.ctx.addresses, local.net_addresses)
  net_addresses = merge([
    for k, v in module.net-address : merge(
      { for kk, vv in v.external_addresses : kk => vv.address },
      { for kk, vv in v.global_addresses : kk => vv.address },
      { for kk, vv in v.internal_addresses : kk => vv.address },
      { for kk, vv in v.ipsec_interconnect_addresses : kk => vv.address },
      { for kk, vv in v.psa_addresses : kk => vv.address },
      { for kk, vv in v.psc_addresses : kk => vv.address }
    )
  ]...)
  ctx_iam_principals = merge(local.ctx.iam_principals, {
    for k, v in module.service-accounts :
    "service_accounts/${k}" => v.iam_email
  })
  ctx_service_account_ids = merge(local.ctx.service_account_ids, {
    for k, v in module.service-accounts :
    "service_accounts/${k}" => v.id
  })
  # phase 2: storage, messaging, data, security resources
  ctx_artifact_registries = merge(
    local.ctx.artifact_registries,
    { for k, v in module.artifact-registry : k => v.id },
    { for k, v in module.artifact-registry-virtual : k => v.id }
  )
  ctx_bigquery_datasets = merge(local.ctx.bigquery_datasets, {
    for k, v in module.bigquery :
    k => v.id
  })
  ctx_pubsub_topics = merge(local.ctx.pubsub_topics, {
    for k, v in module.pubsub :
    k => v.id
  })
  # secret ids are keyed by secret name, version ids by secret/version
  ctx_secrets = merge(
    local.ctx.secrets,
    merge([for k, v in module.secret-manager : v.ids]...),
    merge([for k, v in module.secret-manager : v.version_ids]...)
  )
  ctx_storage_buckets = merge(local.ctx.storage_buckets, {
    for k, v in module.gcs :
    k => v.name
  })
  # phase 3: compute resources
  ctx_instance_groups = merge(local.ctx.instance_groups, {
    for k, v in module.compute-vm :
    k => v.group.self_link if v.group != null
  })
  # context passed to phase 2 modules
  ctx_phase_2 = merge(local.ctx, {
    addresses           = local.ctx_addresses
    iam_principals      = local.ctx_iam_principals
    service_account_ids = local.ctx_service_account_ids
  })
  # context passed to phase 3 modules
  ctx_phase_3 = merge(local.ctx_phase_2, {
    artifact_registries = local.ctx_artifact_registries
    bigquery_datasets   = local.ctx_bigquery_datasets
    pubsub_topics       = local.ctx_pubsub_topics
    secrets             = local.ctx_secrets
    storage_buckets     = local.ctx_storage_buckets
  })
  # context passed to phase 4 modules
  ctx_phase_4 = merge(local.ctx_phase_3, {
    instance_groups = local.ctx_instance_groups
  })
}
