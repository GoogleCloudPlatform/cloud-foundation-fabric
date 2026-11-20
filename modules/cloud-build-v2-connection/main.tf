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
  _bc  = var.connection_config.bitbucket_cloud
  _bdc = var.connection_config.bitbucket_data_center
  _gh  = var.connection_config.github
  _ghe = var.connection_config.github_enterprise
  _gl  = var.connection_config.gitlab
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  ctx_p      = "$"
  location   = lookup(local.ctx.locations, var.location, var.location)
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  name = (
    var.connection_create
    ? try(google_cloudbuildv2_connection.connection[0].name, null)
    : var.name
  )
  triggers = merge([
    for k1, v1 in var.repositories : {
      for k2, v2 in v1.triggers : "${k1}-${k2}" => merge(v2, {
        repository_name = k1
      })
    }
  ]...)
}


resource "google_cloudbuildv2_connection" "connection" {
  count       = var.connection_create ? 1 : 0
  location    = local.location
  project     = local.project_id
  name        = var.name
  annotations = var.annotations
  disabled    = var.disabled

  dynamic "bitbucket_cloud_config" {
    for_each = local._bc == null ? [] : [""]
    content {
      workspace = local._bc.workspace
      webhook_secret_secret_version = lookup(
        local.ctx.secrets,
        local._bc.webhook_secret_secret_version,
        local._bc.webhook_secret_secret_version
      )
      read_authorizer_credential {
        user_token_secret_version = lookup(
          local.ctx.secrets,
          local._bc.read_authorizer_credential_secret_version,
          local._bc.read_authorizer_credential_secret_version
        )
      }
      authorizer_credential {
        user_token_secret_version = lookup(
          local.ctx.secrets,
          local._bc.authorizer_credential_secret_version,
          local._bc.authorizer_credential_secret_version
        )
      }
    }
  }

  dynamic "bitbucket_data_center_config" {
    for_each = local._bdc == null ? [] : [""]
    content {
      host_uri = local._bdc.host_uri
      webhook_secret_secret_version = (
        local._bdc.webhook_secret_secret_version == null
        ? null
        : lookup(
          local.ctx.secrets,
          local._bdc.webhook_secret_secret_version,
          local._bdc.webhook_secret_secret_version
        )
      )
      read_authorizer_credential {
        user_token_secret_version = lookup(
          local.ctx.secrets,
          local._bdc.read_authorizer_credential_secret_version,
          local._bdc.read_authorizer_credential_secret_version
        )
      }
      authorizer_credential {
        user_token_secret_version = lookup(
          local.ctx.secrets,
          local._bdc.authorizer_credential_secret_version,
          local._bdc.authorizer_credential_secret_version
        )
      }
      dynamic "service_directory_config" {
        for_each = local._bdc.service == null ? [] : [""]
        content {
          service = local._bdc.service
        }
      }
      ssl_ca = local._bdc.ssl_ca
    }
  }
  dynamic "github_config" {
    for_each = local._gh == null ? [] : [""]
    content {
      app_installation_id = local._gh.app_installation_id
      authorizer_credential {
        oauth_token_secret_version = (
          local._gh.authorizer_credential_secret_version == null
          ? null
          : lookup(
            local.ctx.secrets,
            local._gh.authorizer_credential_secret_version,
            local._gh.authorizer_credential_secret_version
          )
        )
      }
    }
  }

  dynamic "github_enterprise_config" {
    for_each = local._ghe == null ? [] : [""]
    content {
      host_uri            = local._ghe.host_uri
      app_id              = local._ghe.app_id
      app_slug            = local._ghe.app_slug
      app_installation_id = local._ghe.app_installation_id
      private_key_secret_version = (
        local._ghe.private_key_secret_version == null
        ? null
        : lookup(
          local.ctx.secrets,
          local._ghe.private_key_secret_version,
          local._ghe.private_key_secret_version
        )
      )
      webhook_secret_secret_version = (
        local._ghe.webhook_secret_secret_version == null
        ? null
        : lookup(
          local.ctx.secrets,
          local._ghe.webhook_secret_secret_version,
          local._ghe.webhook_secret_secret_version
        )
      )
      ssl_ca = local._ghe.ssl_ca
      dynamic "service_directory_config" {
        for_each = local._ghe.service == null ? [] : [""]
        content {
          service = local._ghe.service
        }
      }
    }
  }

  dynamic "gitlab_config" {
    for_each = local._gl == null ? [] : [""]
    content {
      host_uri = local._gl.host_uri
      webhook_secret_secret_version = lookup(
        local.ctx.secrets,
        local._gl.webhook_secret_secret_version,
        local._gl.webhook_secret_secret_version
      )
      ssl_ca = local._gl.ssl_ca
      dynamic "authorizer_credential" {
        for_each = (
          local._gl.authorizer_credential_secret_version == null ? [] : [""]
        )
        content {
          user_token_secret_version = lookup(
            local.ctx.secrets,
            local._gl.authorizer_credential_secret_version,
            local._gl.authorizer_credential_secret_version
          )
        }
      }
      dynamic "read_authorizer_credential" {
        for_each = (
          local._gl.read_authorizer_credential_secret_version == null
          ? []
          : [""]
        )
        content {
          user_token_secret_version = lookup(
            local.ctx.secrets,
            local._gl.read_authorizer_credential_secret_version,
            local._gl.read_authorizer_credential_secret_version
          )
        }
      }
      dynamic "service_directory_config" {
        for_each = local._gl.service == null ? [] : [""]
        content {
          service = local._gl.service
        }
      }
    }

  }
}

resource "google_cloudbuildv2_repository" "repositories" {
  for_each          = var.repositories
  name              = each.key
  project           = local.project_id
  location          = local.location
  parent_connection = local.name
  remote_uri        = each.value.remote_uri
  annotations       = each.value.annotations
}

resource "google_cloudbuild_trigger" "triggers" {
  for_each    = local.triggers
  location    = local.location
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
  include_build_logs = each.value.include_build_logs
  tags               = each.value.tags
  substitutions      = each.value.substitutions
  service_account = (
    each.value.service_account == null
    ? null
    : lookup(
      local.ctx.service_account_ids,
      each.value.service_account,
      each.value.service_account
    )
  )
  filename = each.value.filename
  dynamic "approval_config" {
    for_each = each.value.approval_required == true ? [""] : []
    content {
      approval_required = true
    }
  }
}
