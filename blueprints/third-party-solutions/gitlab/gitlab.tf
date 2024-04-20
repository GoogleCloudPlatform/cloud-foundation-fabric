/**
 * Copyright 2024 Google LLC
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
  gitlab_rb = templatefile("${path.module}/assets/config.rb.tpl", {
    project_id = module.project.project_id
    cloudsql = {
      host     = module.db.instances.primary.private_ip_address
      password = module.db.user_passwords.gitlab
    }
    mail = var.gitlab_config.mail
    redis = {
      host = google_redis_instance.cache.host
      port = google_redis_instance.cache.port
    }
    prefix   = var.prefix
    saml     = var.gitlab_config.saml
    hostname = var.gitlab_config.hostname
  })
  gitlab_ssl_crt                 = local.self_signed_ssl_certs_required ? tls_locally_signed_cert.gitlab_server_singed_cert[0].cert_pem : file("${path.module}/certs/${var.gitlab_config.hostname}.crt")
  gitlab_ssl_key                 = local.self_signed_ssl_certs_required ? tls_private_key.gitlab_server_key[0].private_key_pem : file("${path.module}/certs/${var.gitlab_config.hostname}.key")
  gitlab_ssl_ca_crt              = local.self_signed_ssl_certs_required ? tls_self_signed_cert.gitlab_ca_cert[0].cert_pem : file("${path.module}/certs/${var.gitlab_config.hostname}.ca.crt")
  gitlab_ssl_ca_key              = local.self_signed_ssl_certs_required ? tls_private_key.gitlab_ca_private_key[0].private_key_pem : ""
  self_signed_ssl_certs_required = fileexists("${path.module}/certs/${var.gitlab_config.hostname}.crt") && fileexists("${path.module}/certs/${var.gitlab_config.hostname}.key") && fileexists("${path.module}/certs/${var.gitlab_config.hostname}.ca.crt") ? false : true
  gitlab_user_data = templatefile("${path.module}/assets/cloud-config.yaml", {
    gitlab_config      = var.gitlab_config
    gitlab_rb          = indent(6, local.gitlab_rb)
    gitlab_sshd_config = indent(6, file("${path.module}/assets/sshd_config"))
    gitlab_cert_name   = var.gitlab_config.hostname
    gitlab_ssl_key     = indent(6, base64encode(local.gitlab_ssl_key))
    gitlab_ssl_crt     = indent(6, base64encode(local.gitlab_ssl_crt))
  })
}

module "gitlab-sa" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.project.project_id
  name         = var.gitlab_instance_config.name
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
  source        = "../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = var.gitlab_instance_config.zone
  name          = var.gitlab_instance_config.name
  instance_type = var.gitlab_instance_config.instance_type
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      size  = var.gitlab_instance_config.boot_disk.size
      type  = var.gitlab_instance_config.boot_disk.type
    }
  }
  attached_disks = [
    {
      name = "data"
      size = var.gitlab_instance_config.data_disk.size
      type = var.gitlab_instance_config.data_disk.type
      options = {
        replica_zone = var.gitlab_instance_config.replica_zone
      }
    }
  ]
  network_interfaces = [
    {
      network    = var.network_config.network_self_link
      subnetwork = var.network_config.subnet_self_link
    }
  ]
  tags = var.gitlab_instance_config.network_tags
  metadata = {
    user-data              = local.gitlab_user_data
    google-logging-enabled = "true"
  }
  service_account = {
    email = module.gitlab-sa.email
  }
}

module "ilb" {
  source        = "../../../modules/net-lb-int"
  project_id    = module.project.project_id
  region        = var.region
  name          = "ilb"
  service_label = "ilb"
  vpc_config = {
    network    = var.network_config.network_self_link
    subnetwork = var.network_config.subnet_self_link
  }
  group_configs = {
    gitlab = {
      zone = var.gitlab_instance_config.zone
      instances = [
        module.gitlab-instance.self_link
      ]
    }
  }
  backends = [
    { group = module.ilb.groups.gitlab.self_link }
  ]
  health_check_config = {
    https = {
      port = 443
    }
  }
}
