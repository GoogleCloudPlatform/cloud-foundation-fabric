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
  gitlab_rb = templatefile("assets/config.rb", {
    project_id = module.project.project_id
    cloudsql = {
      host     = module.db.instances.primary.private_ip_address
      username = "sqlserver"
      password = module.db.user_passwords.sqlserver
    }
    redis = {
      host = google_redis_instance.cache.host
      port = google_redis_instance.cache.port
    }
  })
}

module "gitlab-sa" {
  source       = "../../../../modules/iam-service-account"
  project_id   = module.project.project_id
  name         = "gitlab-0"
  display_name = "Gitlab instance service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [module.gitlab-sa.iam_email]
  }
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/storage.admin"
    ]
  }
}

module "gitlab-instance" {
  source        = "../../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = "${var.region}-b"
  name          = "gitlab-0"
  instance_type = "e2-standard-2"
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-balanced"
    }
  }
  attached_disks = [{
    name = "data"
    size = 20
    options = {
      replica_zone = "${var.region}-c"
    }
  }]
  network_interfaces = [{
    network    = var.vpc_self_links.dev-spoke-0
    subnetwork = var.subnet_self_links.dev-spoke-0["${var.region}/gce"]
  }]
  tags = ["http-server", "https-server", "ssh"]
  metadata = {
    user-data = templatefile("assets/cloud-config.yaml", {
      gitlab_config      = var.gitlab_config
      gitlab_rb          = indent(6, local.gitlab_rb)
      gitlab_sshd_config = indent(6, file("assets/sshd_config"))
    })
  }
  service_account = {
    email = module.gitlab-sa.email
  }
}
