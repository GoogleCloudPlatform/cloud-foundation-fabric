/**
 * Copyright 2023 Google LLC
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
  format_string = one([for k, v in var.format : k if v != null])
  mode_string   = one([for k, v in var.mode : k if v != null && v != false])
}

resource "google_artifact_registry_repository" "registry" {
  provider      = google-beta
  project       = var.project_id
  location      = var.location
  description   = var.description
  format        = upper(local.format_string)
  labels        = var.labels
  repository_id = var.name
  mode          = "${upper(local.mode_string)}_REPOSITORY"
  kms_key_name  = var.encryption_key

  cleanup_policy_dry_run = var.cleanup_policy_dry_run
  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies == null ? {} : var.cleanup_policies
    content {
      id     = cleanup_policies.key
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = (cleanup_policies.value.condition != null) ? [""] : []
        content {
          tag_state             = cleanup_policies.value.condition.tag_state
          tag_prefixes          = cleanup_policies.value.condition.tag_prefixes
          version_name_prefixes = cleanup_policies.value.condition.version_name_prefixes
          package_name_prefixes = cleanup_policies.value.condition.package_name_prefixes
          newer_than            = cleanup_policies.value.condition.newer_than
          older_than            = cleanup_policies.value.condition.older_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = (cleanup_policies.value.most_recent_versions != null) ? [""] : []
        content {
          package_name_prefixes = cleanup_policies.value.most_recent_versions.package_name_prefixes
          keep_count            = cleanup_policies.value.most_recent_versions.keep_count
        }
      }
    }
  }

  dynamic "docker_config" {
    # TODO: open a bug on the provider for this permadiff
    for_each = (
      local.format_string == "docker" && try(var.format.docker.immutable_tags, null) == true
      ? [""]
      : []
    )
    content {
      immutable_tags = var.format.docker.immutable_tags
    }
  }

  dynamic "maven_config" {
    for_each = local.format_string == "maven" ? [""] : []
    content {
      allow_snapshot_overwrites = var.format.maven.allow_snapshot_overwrites
      version_policy            = var.format.maven.version_policy
    }
  }

  dynamic "remote_repository_config" {
    for_each = local.mode_string == "remote" ? [""] : []
    content {
      dynamic "docker_repository" {
        for_each = local.format_string == "docker" ? [""] : []
        content {
          public_repository = "DOCKER_HUB"
        }
      }
      dynamic "maven_repository" {
        for_each = local.format_string == "maven" ? [""] : []
        content {
          public_repository = "MAVEN_CENTRAL"
        }
      }
      dynamic "npm_repository" {
        for_each = local.format_string == "npm" ? [""] : []
        content {
          public_repository = "NPMJS"
        }
      }
      dynamic "python_repository" {
        for_each = local.format_string == "python" ? [""] : []
        content {
          public_repository = "PYPI"
        }
      }
    }
  }

  dynamic "virtual_repository_config" {
    for_each = local.mode_string == "virtual" ? [""] : []
    content {
      dynamic "upstream_policies" {
        for_each = var.mode.virtual
        content {
          id         = upstream_policies.key
          repository = upstream_policies.value.repository
          priority   = upstream_policies.value.priority
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = local.mode_string != "remote" || contains(
        ["docker", "maven", "npm", "python"], local.format_string
      )
      error_message = "Invalid format for remote repository."
    }
  }

}

resource "google_artifact_registry_repository_iam_binding" "bindings" {
  provider   = google-beta
  for_each   = var.iam
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = each.key
  members    = each.value
}
