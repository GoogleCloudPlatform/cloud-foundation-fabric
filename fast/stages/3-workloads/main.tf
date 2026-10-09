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

# Natively provision scalable compute instances and GCS buckets inside your workload projects
# and connect them securely to your Shared VPC spokes.

provider "google" {
  # Runs under your active, highly-privileged gcloud CLI user (justin@placard.media),
  # bypassing any complicated platform service-account impersonation!
}

# 1. Scalable Compute Instance Factory
resource "google_compute_instance" "debian_micro" {
  for_each     = var.compute_instances
  project      = var.project_ids[each.value.project_key]
  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = each.value.image
      type  = each.value.type
      size  = each.value.size
    }
  }

  network_interface {
    subnetwork = var.subnet_self_links[each.value.vpc_key][each.value.subnet_key]
    # No public IP is assigned! It routes outbound internet traffic securely
    # through the VPC to your regional Cloud NAT gateway.
  }

  metadata = each.value.metadata
  labels   = each.value.labels
}

# 2. Scalable Cloud Storage Bucket Factory
resource "google_storage_bucket" "buckets" {
  for_each                    = var.gcs_buckets
  project                     = var.project_ids[each.value.project_key]
  name                        = each.key
  location                    = each.value.location
  storage_class               = each.value.class
  uniform_bucket_level_access = true
  force_destroy               = false
  labels                      = each.value.labels
}
