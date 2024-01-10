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
    cloudsql   = {
      host     = module.db.instances.primary.private_ip_address
      username = "sqlserver"
      password = module.db.user_passwords.gitlab
    }
    mail  = var.gitlab_config.mail
    redis = {
      host = google_redis_instance.cache.host
      port = google_redis_instance.cache.port
    }
    prefix   = var.prefix
    saml     = var.gitlab_config.saml
    hostname = var.gitlab_config.hostname
  })
  self_signed_ssl_certs_required = fileexists("${path.module}/certs/${var.gitlab_config.hostname}.crt") && fileexists("${path.module}/certs/${var.gitlab_config.hostname}.key") ? false : true
  gitlab_ssl_key = local.self_signed_ssl_certs_required ? local_file.gitlab_server_key.content : file("${path.module}/certs/${var.gitlab_config.hostname}.key")
  gitlab_ssl_crt = local.self_signed_ssl_certs_required ? local_file.gitlab_server_crt.content : file("${path.module}/certs/${var.gitlab_config.hostname}.crt")
}

module "gitlab-sa" {
  source       = "../../../../modules/iam-service-account"
  project_id   = module.project.project_id
  name         = "gitlab-0"
  display_name = "Gitlab instance service account"
  iam          = {
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
  boot_disk     = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-balanced"
    }
  }
  attached_disks = [
    {
      name    = "data"
      size    = 40
      options = {
        replica_zone = "${var.region}-c"
      }
    }
  ]
  network_interfaces = [
    {
      network    = var.vpc_self_links.dev-spoke-0
      subnetwork = var.subnet_self_links.dev-spoke-0["${var.region}/gitlab"]
    }
  ]
  tags     = ["http-server", "https-server", "ssh"]
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
  source        = "../../../../modules/net-lb-int"
  project_id    = module.project.project_id
  region        = var.region
  name          = "ilb"
  service_label = "ilb"
  vpc_config = {
    network    = var.vpc_self_links.dev-spoke-0
    subnetwork = var.subnet_self_links.dev-spoke-0["${var.region}/gitlab"]
  }
  group_configs = {
    gitlab = {
      zone = "${var.region}-b"
      instances = [
        module.gitlab-instance.self_link
      ]
    }
  }
  backends = [{
    group = module.ilb.groups.gitlab.self_link
  }]
  health_check_config = {
    https = {
      port = 443
    }
  }
}

module "private-dns" {
  source     = "../../../../modules/dns"
  project_id = module.project.project_id
  name       = "gitlab"
  zone_config = {
    domain = "example.com."
    private = {
      client_networks = [var.vpc_self_links.dev-spoke-0]
    }
  }
  recordsets = {
    "A gitlab" = { records = [module.ilb.forwarding_rule_addresses[""]] }
  }
}