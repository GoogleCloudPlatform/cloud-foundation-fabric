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
  self_signed_ssl_certs_required = fileexists("${path.module}/certs/${var.gitlab_config.hostname}.crt") && fileexists("${path.module}/certs/${var.gitlab_config.hostname}.key") && fileexists("${path.module}/certs/${var.gitlab_config.hostname}.ca.crt") ? false : true
  gitlab_ssl_key                 = local.self_signed_ssl_certs_required ? tls_private_key.gitlab_server_key.0.private_key_pem : file("${path.module}/certs/${var.gitlab_config.hostname}.key")
  gitlab_ssl_crt                 = local.self_signed_ssl_certs_required ? tls_locally_signed_cert.gitlab_server_singed_cert.0.cert_pem : file("${path.module}/certs/${var.gitlab_config.hostname}.crt")
  gitlab_ssl_ca_crt              = local.self_signed_ssl_certs_required ? tls_self_signed_cert.gitlab_ca_cert.0.cert_pem : file("${path.module}/certs/${var.gitlab_config.hostname}.ca.crt")
}

module "gitlab-sa" {
  source       = "../../../modules/iam-service-account"
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
  source        = "../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = "${var.regions.primary}-b"
  name          = "gitlab-0"
  instance_type = "e2-standard-2"
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-balanced"
    }
  }
  attached_disks = [
    {
      name = "data"
      size = 40
      options = {
        replica_zone = "${var.regions.primary}-c"
      }
    }
  ]
  network_interfaces = [
    {
      network    = var.vpc_self_links.prod-landing
      subnetwork = var.subnet_self_links.prod-landing["${var.regions.primary}/landing-gitlab-server-ew1"]
    }
  ]
  tags = ["http-server", "https-server", "ssh"]
  metadata = {
    user-data = templatefile("assets/cloud-config.yaml", {
      gitlab_config      = var.gitlab_config
      gitlab_rb          = indent(6, local.gitlab_rb)
      gitlab_sshd_config = indent(6, file("assets/sshd_config"))
      gitlab_cert_name   = var.gitlab_config.hostname
      gitlab_ssl_key     = indent(6, base64encode(local.gitlab_ssl_key))
      gitlab_ssl_crt     = indent(6, base64encode(local.gitlab_ssl_crt))
    })
  }
  service_account = {
    email = module.gitlab-sa.email
  }
}

module "ilb" {
  source        = "../../../modules/net-lb-int"
  project_id    = module.project.project_id
  region        = var.regions.primary
  name          = "ilb"
  service_label = "ilb"
  vpc_config = {
    network    = var.vpc_self_links.prod-landing
    subnetwork = var.subnet_self_links.prod-landing["${var.regions.primary}/landing-gitlab-server-ew1"]
  }
  group_configs = {
    gitlab = {
      zone = "${var.regions.primary}-b"
      instances = [
        module.gitlab-instance.self_link
      ]
    }
  }
  backends = [
    {
      group = module.ilb.groups.gitlab.self_link
    }
  ]
  health_check_config = {
    https = {
      port = 443
    }
  }
}

# TODO we should move this into networking stage

data "google_dns_managed_zone" "landing_dns_priv_gcp" {
  project = var.host_project_ids.prod-landing
  name    = "gcp-example-com"
}

resource "google_dns_record_set" "gitlab_server" {
  project = var.host_project_ids.prod-landing
  name    = "gitlab.${data.google_dns_managed_zone.landing_dns_priv_gcp.dns_name}"
  type    = "A"
  ttl     = 300

  managed_zone = data.google_dns_managed_zone.landing_dns_priv_gcp.name

  rrdatas = [
    module.ilb.forwarding_rule_addresses[""]
  ]
}