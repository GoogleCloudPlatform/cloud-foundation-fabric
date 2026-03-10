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
  # context enrichments from factory-created resources
  # phase 1: service accounts enrich iam_principals
  ctx_iam_principals = merge(local.ctx.iam_principals, {
    for k, v in module.service-accounts :
    k => v.iam_email
  })
  # phase 2: storage/messaging/data resources enrich their respective keys
  ctx_storage_buckets = merge(local.ctx.storage_buckets, {
    for k, v in module.gcs :
    k => v.name
  })
  ctx_pubsub_topics = merge(local.ctx.pubsub_topics, {
    for k, v in module.pubsub :
    k => v.id
  })
  ctx_datasets = merge(try(local.ctx.datasets, {}), {
    for k, v in module.bigquery :
    k => v.dataset_id
  })
  ctx_secrets = merge(try(local.ctx.secrets, {}), merge([
    for k, v in module.secret-manager : v.ids
  ]...))
  ctx_artifact_registries = merge(try(local.ctx.artifact_registries, {}), {
    for k, v in module.artifact-registry :
    k => v.id
  })
}
