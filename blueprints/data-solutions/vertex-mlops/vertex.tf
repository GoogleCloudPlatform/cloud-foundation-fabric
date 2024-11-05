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

resource "google_vertex_ai_metadata_store" "store" {
  provider    = google-beta
  project     = module.project.project_id
  name        = "default"
  description = "Vertex Ai Metadata Store"
  region      = var.region
  dynamic "encryption_spec" {
    for_each = var.service_encryption_keys.aiplatform == null ? [] : [""]

    content {
      kms_key_name = var.service_encryption_keys.aiplatform
    }
  }
  # `state` value will be decided automatically based on the result of the configuration
  lifecycle {
    ignore_changes = [state]
  }
}

module "service-account-notebook" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "notebook-sa"
}

resource "google_notebooks_runtime" "runtime" {
  for_each = { for k, v in var.notebooks : k => v if v.type == "MANAGED" }
  name     = "${var.prefix}-${each.key}"
  project  = module.project.project_id
  location = var.region
  access_config {
    access_type   = "SINGLE_USER"
    runtime_owner = try(var.notebooks[each.key].owner, null)
  }
  software_config {
    enable_health_monitoring = true
  }
  virtual_machine {
    virtual_machine_config {
      machine_type     = var.notebooks[each.key].machine_type
      network          = local.vpc
      subnet           = local.subnet
      internal_ip_only = var.notebooks[each.key].internal_ip_only
      dynamic "encryption_config" {
        for_each = var.service_encryption_keys.notebooks == null ? [] : [1]
        content {
          kms_key = var.service_encryption_keys.notebooks
        }
      }
      metadata = {
        notebook-disable-nbconvert = "false"
        notebook-disable-downloads = "true"
        notebook-disable-terminal  = "false"
        notebook-disable-root      = "true"
      }
      data_disk {
        initialize_params {
          disk_size_gb = "100"
          disk_type    = "PD_STANDARD"
        }
      }
    }
  }
}

resource "google_workbench_instance" "playground" {
  for_each = { for k, v in var.notebooks : k => v if v.type == "USER_MANAGED" }
  project  = module.project.project_id
  name     = "${var.prefix}-${each.key}"
  location = "${var.region}-b"

  gce_setup {
    machine_type = var.notebooks[each.key].machine_type
    container_image {
      repository = "gcr.io/deeplearning-platform-release/workbench-container"
      tag        = "latest"
    }
    boot_disk {
      disk_size_gb    = 150
      disk_type       = "PD_SSD"
      disk_encryption = var.service_encryption_keys.notebooks != null ? "CMEK" : null
      kms_key         = var.service_encryption_keys.notebooks
    }

    disable_public_ip = var.notebooks[each.key].internal_ip_only

    network_interfaces {
      network = local.vpc
      subnet  = local.subnet
    }
    service_accounts {
      email = module.service-account-notebook.email
    }
    # full list of supported metadata keys:
    # https://cloud.google.com/vertex-ai/docs/workbench/instances/manage-metadata
    metadata = {
      notebook-disable-nbconvert = "false"
      notebook-disable-downloads = "false"
      notebook-disable-terminal  = "false"
      notebook-disable-root      = "true"
    }
    tags = ["ssh"]
  }
  disable_proxy_access = true
  instance_owners      = try(tolist(var.notebooks[each.key].owner), null)


  depends_on = [
    google_project_iam_member.shared_vpc,
  ]
}
