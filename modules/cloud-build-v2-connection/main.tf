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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p      = "$"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  name       = var.connection_create ? try(google_cloudbuildv2_connection.connection[0].name, null) : var.name
  triggers = merge([for k1, v1 in var.repositories : { for k2, v2 in v1.triggers : "${k1}-${k2}" => merge(v2, {
    repository_name = k1
  }) }]...)
}


resource "google_cloudbuildv2_connection" "connection" {
  count       = var.connection_create ? 1 : 0
  location    = var.location
  project     = var.project_id
  name        = var.name
  annotations = var.annotations
  disabled    = var.disabled

  dynamic "bitbucket_cloud_config" {
    for_each = var.connection_config.bitbucket_cloud == null ? [] : [""]
    content {
      workspace                     = var.connection_config.bitbucket_cloud.workspace
      webhook_secret_secret_version = var.connection_config.bitbucket_cloud.webhook_secret_secret_version
      read_authorizer_credential {
        user_token_secret_version = var.connection_config.bitbucket_cloud.read_authorizer_credential_secret_version
      }
      authorizer_credential {
        user_token_secret_version = var.connection_config.bitbucket_cloud.authorizer_credential_secret_version
      }
    }
  }

  dynamic "bitbucket_data_center_config" {
    for_each = var.connection_config.bitbucket_data_center == null ? [] : [""]
    content {
      host_uri                      = var.connection_config.bitbucket_data_center.host_uri
      webhook_secret_secret_version = var.connection_config.bitbucket_data_center.webhook_secret_secret_version
      read_authorizer_credential {
        user_token_secret_version = var.connection_config.bitbucket_data_center.read_authorizer_credential_secret_version
      }
      authorizer_credential {
        user_token_secret_version = var.connection_config.bitbucket_data_center.authorizer_credential_secret_version
      }
      dynamic "service_directory_config" {
        for_each = var.connection_config.bitbucket_data_center.service == null ? [] : [""]
        content {
          service = var.connection_config.bitbucket_data_center.service
        }
      }
      ssl_ca = var.connection_config.bitbucket_data_center.ssl_ca
    }
  }
  dynamic "github_config" {
    for_each = var.connection_config.github == null ? [] : [""]
    content {
      app_installation_id = var.connection_config.github.app_installation_id
      authorizer_credential {
        oauth_token_secret_version = var.connection_config.github.authorizer_credential_secret_version
      }
    }
  }

  dynamic "github_enterprise_config" {
    for_each = var.connection_config.github_enterprise == null ? [] : [""]
    content {
      host_uri                      = var.connection_config.github_enterprise.host_uri
      app_id                        = var.connection_config.github_enterprise.app_id
      app_slug                      = var.connection_config.github_enterprise.app_slug
      app_installation_id           = var.connection_config.github_enterprise.app_installation_id
      private_key_secret_version    = var.connection_config.github_enterprise.private_key_secret_version
      webhook_secret_secret_version = var.connection_config.github_enterprise.webhook_secret_secret_version
      ssl_ca                        = var.connection_config.github_enterprise.ssl_ca
      dynamic "service_directory_config" {
        for_each = var.connection_config.github_enterprise.service == null ? [] : [""]
        content {
          service = var.connection_config.github_enterprise.service
        }
      }
    }
  }

  dynamic "gitlab_config" {
    for_each = var.connection_config.gitlab == null ? [] : [""]
    content {
      host_uri                      = var.connection_config.gitlab.host_uri
      webhook_secret_secret_version = var.connection_config.gitlab.webhook_secret_secret_version
      ssl_ca                        = var.connection_config.gitlab.ssl_ca
      dynamic "authorizer_credential" {
        for_each = var.connection_config.gitlab.authorizer_credential_secret_version == null ? [] : [""]
        content {
          user_token_secret_version = var.connection_config.gitlab.authorizer_credential_secret_version
        }
      }
      dynamic "read_authorizer_credential" {
        for_each = var.connection_config.gitlab.read_authorizer_credential_secret_version == null ? [] : [""]
        content {
          user_token_secret_version = var.connection_config.gitlab.read_authorizer_credential_secret_version
        }
      }
      dynamic "service_directory_config" {
        for_each = var.connection_config.gitlab.service == null ? [] : [""]
        content {
          service = var.connection_config.gitlab.service
        }
      }
    }

  }
}

resource "google_cloudbuildv2_repository" "repositories" {
  for_each          = var.repositories
  name              = each.key
  project           = local.project_id
  location          = var.location
  parent_connection = local.name
  remote_uri        = each.value.remote_uri
  annotations       = each.value.annotations
}

resource "google_cloudbuild_trigger" "triggers" {
  for_each    = local.triggers
  location    = var.location
  name        = each.key
  project     = local.project_id
  description = each.value.description
  disabled    = each.value.disabled
  repository_event_config {
    repository = google_cloudbuildv2_repository.repositories[each.value.repository_name].id
    dynamic "push" {
      for_each = try(each.value.push, null) == null ? [] : [""]
      content {
        branch       = each.value.push.branch
        invert_regex = each.value.push.invert_regex
        tag          = each.value.push.tag
      }
    }
    dynamic "pull_request" {
      for_each = try(each.value.pull_request, null) == null ? [] : [""]
      content {
        branch          = each.value.pull_request.branch
        invert_regex    = each.value.pull_request.invert_regex
        comment_control = each.value.pull_request.comment_control
      }
    }
  }

  filename = each.value.filename
}