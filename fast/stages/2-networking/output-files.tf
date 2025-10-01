/**
 * Copyright 2022 Google LLC
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

# Output files generation for 2-networking stage
locals {
  # Governed by var.output_files + local.output_files - merges variable config with defaults.yaml values
  of_output_files = merge(
    {
      enabled = var.output_files.enabled        # From var.output_files.enabled
      local_path = var.output_files.local_path  # From var.output_files.local_path
      storage_bucket = var.output_files.storage_bucket  # From var.output_files.storage_bucket
    },
    local.output_files  # Override with defaults.yaml values if present (from local._defaults.output_files)
  )

  # Governed by local.of_output_files.local_path - expands path for local file generation
  of_path = (
    local.of_output_files.local_path == null
    ? null
    : pathexpand(local.of_output_files.local_path)  # Expand ~ and relative paths to absolute
  )

  # Governed by local.of_output_files.storage_bucket - GCS bucket for tfvars upload
  of_outputs_bucket = local.of_output_files.storage_bucket

  # Governed by input variables + module outputs - generates tfvars structure for downstream stages
  of_tfvars = {
    # Governed by global input variables - pass through globals unchanged
    globals = {
      billing_account = var.billing_account  # From globals tfvars
      groups         = var.groups           # From globals tfvars
      locations      = var.locations        # From globals tfvars
      organization   = var.organization     # From globals tfvars
      prefix         = var.prefix           # From globals tfvars
    }

    # Governed by previous stage variables + networking module outputs - networking stage outputs for downstream consumption
    "2-networking" = {
      # Governed by individual tfvars variables - pass through all previous stage context
      automation       = var.automation       # From 1-resman stage outputs
      custom_roles     = var.custom_roles     # From 1-resman stage outputs
      folder_ids       = var.folder_ids       # From 1-resman stage outputs
      iam_principals   = var.iam_principals   # From 1-resman stage outputs
      logging          = var.logging          # From 1-resman stage outputs
      project_ids      = var.project_ids      # From 1-resman stage outputs
      project_numbers  = var.project_numbers  # From 1-resman stage outputs
      service_accounts = var.service_accounts # From 1-resman stage outputs
      storage_buckets  = var.storage_buckets  # From 1-resman stage outputs
      tag_values       = var.tag_values       # From 1-resman stage outputs

      # Governed by module.network_factory outputs - simplified for current structure
      # vpc_configs = module.network_factory.context.vpc_configs      # VPC configuration details

      # Governed by module.project_factory outputs - projects from project factory (commented out since project_factory is commented out)
      # projects = module.project_factory.projects  # Project details from project factory
    }
  }
}

# Generate local tfvars files
resource "local_file" "tfvars" {
  for_each        = toset(local.of_path == null ? [] : keys(local.of_tfvars))
  file_permission = "0644"
  filename        = "${local.of_path}/tfvars/2-${each.key}.auto.tfvars.json"
  content         = jsonencode(local.of_tfvars[each.key])
}

# Upload tfvars to GCS bucket (if configured)
# resource "google_storage_bucket_object" "tfvars" {
#   for_each = toset(local.of_outputs_bucket == null ? [] : keys(local.of_tfvars))
#   bucket   = local.of_outputs_bucket
#   name     = "tfvars/2-${each.key}.auto.tfvars.json"
#   content  = jsonencode(local.of_tfvars[each.key])
# }