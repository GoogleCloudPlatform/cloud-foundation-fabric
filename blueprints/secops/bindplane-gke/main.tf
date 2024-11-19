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
  fleet_host = join("", [
    "https://connectgateway.googleapis.com/v1/",
    "projects/${module.project.number}/",
    "locations/global/gkeMemberships/bindplane"
  ])
}

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  prefix         = var.prefix
  project_create = var.project_create != null
  name           = var.project_id
  services = concat([
    "compute.googleapis.com",
    "iap.googleapis.com",
    "stackdriver.googleapis.com",
    "chronicle.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "connectgateway.googleapis.com",
    "gkeconnect.googleapis.com"
  ])
  iam = {
    "roles/pubsub.editor" = ["principal://iam.googleapis.com/projects/${module.project.number}/locations/global/workloadIdentityPools/${module.project.project_id}.svc.id.goog/subject/ns/bindplane/sa/bindplane"]
  }
}

module "fleet" {
  source     = "../../../modules/gke-hub"
  project_id = module.project.project_id
  clusters = {
    "bindplane" = module.bindplane-cluster.id
  }
}

module "bindplane-cluster" {
  source              = "../../../modules/gke-cluster-autopilot"
  project_id          = module.project.project_id
  name                = var.cluster_config.cluster_name
  location            = var.region
  deletion_protection = false
  vpc_config = {
    network    = var.network_config.network_self_link
    subnetwork = var.network_config.subnet_self_link
    secondary_range_names = {
      pods     = var.network_config.secondary_pod_range_name
      services = var.network_config.secondary_services_range_name
    }
    master_ipv4_cidr_block   = var.network_config.ip_range_gke_master
    master_authorized_ranges = var.cluster_config.master_authorized_ranges
  }
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = true
  }
  enable_features = {
    gateway_api = true
  }
  logging_config = {
    enable_api_server_logs         = true
    enable_scheduler_logs          = true
    enable_controller_manager_logs = true
  }
  monitoring_config = {
    enable_daemonset_metrics          = true
    enable_deployment_metrics         = true
    enable_hpa_metrics                = true
    enable_pod_metrics                = true
    enable_statefulset_metrics        = true
    enable_storage_metrics            = true
    enable_api_server_metrics         = true
    enable_controller_manager_metrics = true
    enable_scheduler_metrics          = true
  }
}

module "db" {
  source     = "../../../modules/cloudsql-instance"
  project_id = module.project.project_id
  databases  = ["bindplane"]
  network_config = {
    connectivity = {
      psc_allowed_consumer_projects = [module.project.project_id]
    }
  }
  prefix            = var.prefix
  name              = "bindplane"
  region            = var.region
  availability_type = var.postgresql_config.availability_type
  database_version  = var.postgresql_config.database_version
  tier              = var.postgresql_config.tier

  users = {
    bindplane = {
      password = null
      type     = "BUILT_IN"
    }
  }

  gcp_deletion_protection       = false
  terraform_deletion_protection = false
}

module "addresses" {
  source     = "../../../modules/net-address"
  project_id = module.project.project_id
  internal_addresses = {
    ingress = {
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = var.region
      subnetwork = var.network_config.subnet_self_link
    }
  }
  psc_addresses = {
    postgresql = {
      address          = ""
      region           = var.region
      subnet_self_link = var.network_config.subnet_self_link
      service_attachment = {
        psc_service_attachment_link = module.db.psc_service_attachment_link
        global_access = true
      }
    }
  }
}

module "dns" {
  source     = "../../../modules/dns"
  count      = var.dns_config.bootstrap_private_zone ? 1 : 0
  project_id = module.project.project_id
  name       = "bindplane"
  zone_config = {
    domain = "${var.dns_config.domain}."
    private = {
      client_networks = [var.network_config.network_self_link]
    }
  }
  recordsets = {
    "A ${var.dns_config.hostname}" = { ttl = 600, records = [module.addresses.internal_addresses["ingress"].address] }
  }
}

module "pubsub" {
  source     = "../../../modules/pubsub"
  project_id = module.project.project_id
  name       = "bindplane"
}

module "bindplane-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "bindplane"
  iam        = {
    "roles/iam.workloadIdentityUser" = ["serviceAccount:${module.project.project_id}.svc.id.goog[bindplane/bindplane]"]
  }
  iam_project_roles = {
    "${module.project.project_id}" = [
      "roles/pubsub.editor"
    ]
  }
}

module "bindplane-deployment" {
  source            = "./bindplane-deployment"
  depends_on        = [module.bindplane-cluster]
  bindplane_secrets = var.bindplane_secrets
  bindplane_tls = {
    cer = coalesce(var.bindplane_config.tls_certificate_cer, try(tls_locally_signed_cert.server_singed_cert.0.cert_pem,null))
    key = coalesce(var.bindplane_config.tls_certificate_key, try(tls_private_key.server_key.0.private_key_pem,null))
  }
}

resource "helm_release" "bindplane" {
  name             = "bindplane"
  repository       = "https://observiq.github.io/bindplane-op-helm"
  chart            = "bindplane"
  namespace        = "bindplane"
  create_namespace = false
  values = [templatefile("${path.module}/config/values.yaml.tpl", {
    postgresql_ip       = module.addresses.psc_addresses["postgresql"].address
    postgresql_username = "bindplane"
    postgresql_password = module.db.user_passwords["bindplane"]
    gcp_project_id      = module.project.project_id
    hostname            = "${var.dns_config.hostname}.${var.dns_config.domain}"
    address             = "ingress"
  })]

  depends_on = [
    module.bindplane-deployment,
    module.addresses
  ]
}
