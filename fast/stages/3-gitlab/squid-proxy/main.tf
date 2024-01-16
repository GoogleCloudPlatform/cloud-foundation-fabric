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


################################################################################
##                               SQUID RESOURCES                               #
################################################################################

locals {
  squid_conf_path = "${path.module}/squid.conf"
}

module "service-account-squid" {
  source            = "../../../../modules/iam-service-account"
  project_id        = var.project_id
  name              = "svc-squid"
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "squid-vm" {
  source             = "../../../../modules/compute-vm"
  project_id         = var.project_id
  zone               = "${var.region}-b"
  name               = "squid-vm"
  instance_type      = "e2-medium"
  create_template    = false
  network_interfaces = [
    {
      network    = var.network_config.network_self_link
      subnetwork = var.network_config.proxy_subnet_self_link
      nat        = var.enable_public_ip
    }
  ]
  boot_disk = {
    initialize_params = {
      image = "debian-cloud/debian-11"
    }
  }
  service_account        = {
    email = module.service-account-squid.email
  }
  metadata               = {
    startup-script = <<EOF
apt-get update
apt -y install squid
cat <<EOT > /etc/squid/squid.conf
${file(local.squid_conf_path)}
EOF
  }
}
