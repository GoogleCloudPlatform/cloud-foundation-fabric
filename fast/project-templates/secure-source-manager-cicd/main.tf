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

# STUB / SKETCH ONLY. Nothing here is expected to plan yet. Attributes are
# named from the modules' variables.tf where verified, and marked TODO where
# they still have to be checked or where the module does not carry them.

# ------------------------------------------------------------------------
# source: instance and repositories
# ------------------------------------------------------------------------

# modules/secure-source-manager-instance
#
# Carries: instance with private_configs {is_private, ca_pool_id},
# repositories with initial_config + branch_rules + per-repo IAM,
# instance-level iam / iam_bindings / iam_bindings_additive.
#
# GAP: var.repositories has no `service_account` attribute, so the BYOSA the
# whole isolation requirement rests on cannot be set. The provider field
# exists (7.44.0+). Module needs extending before this template can be built.
#
# GAP: no output for the two PSC service attachments. Reachable today as
# module.ssm.instance.private_config[0].http_service_attachment / .ssh_...
# but the LB blocks below want a clean output.
#
module "ssm" {
  source     = "../../../modules/secure-source-manager-instance"
  project_id = var.project_id
  location   = var.location
  # instance id ends up inside every hostname, DNS record and clone URL, and
  # the instance is immutable, so this is a one-shot naming decision
  instance_id = var.instance_id
  private_configs = {
    is_private = true
    ca_pool_id = var.ca_pool_id
  }
  repositories = {
    for k, v in var.repositories : k => {
      description  = v.description
      branch_rules = v.branch_rules
      # TODO service_account = module.repo-sa[k].email   <- module gap above
      iam = {
        # build identities this repo's pipelines may run as get repoReader
        # here, on the repository, never on the project
        "roles/securesourcemanager.repoReader" = [
          for sa in v.build_identities : module.build-sa[sa].iam_email
        ]
      }
    }
  }
}

# ------------------------------------------------------------------------
# identity
# ------------------------------------------------------------------------

# modules/iam-service-account, one per repository (BYOSA).
#
# iam_sa_roles is the variable that carries the act-as edges: a map of
# service account id -> roles, granted on the target SA resource. That is
# exactly the "grant on the SA, never on the project" rule.
#
module "repo-sa" {
  source     = "../../../modules/iam-service-account"
  for_each   = var.repositories
  project_id = var.project_id
  name       = "ssm-repo-${each.key}"
  # the SSM service agent mints tokens for this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      # TODO service agent member string; needs the project module's
      # service_agents output, which this template does not have because the
      # project comes from the factory. Options: project_number variable and
      # build the string, or a projects-data-source module.
    ]
  }
  # act-as edges out of this BYOSA, one per build identity it may name
  iam_sa_roles = {
    for sa in each.value.build_identities :
    module.build-sa[sa].id => ["roles/iam.serviceAccountUser"]
  }
  iam_project_roles = {
    (var.project_id) = [
      "roles/cloudbuild.builds.editor",
      "roles/cloudbuild.workerPoolUser",
      "roles/serviceusage.serviceUsageConsumer",
    ]
  }
}

# modules/iam-service-account, the build identities (plan / apply / whatever
# the customer's split is). These are what the triggers file names.
module "build-sa" {
  source     = "../../../modules/iam-service-account"
  for_each   = var.build_identities
  project_id = var.project_id
  name       = each.key
  iam_project_roles = {
    (var.project_id) = ["roles/logging.logWriter"]
    # TODO roles/privateca.auditor on the CA pool's project - open point in
    # the README: from here, or from the project factory?
  }
  # impersonation of the terraform SAs the pipeline actually uses
  iam_sa_roles = each.value.impersonate_service_accounts
}

# instance-level roles/securesourcemanager.instanceAccessor for every build
# identity, via module.ssm's own iam variable. TODO fold into the ssm block.

# ------------------------------------------------------------------------
# network: PSC access path to the instance
# ------------------------------------------------------------------------

# modules/net-lb-proxy-int, twice: regional internal TCP proxy LB in front of
# each PSC service attachment. The module creates the PSC NEG itself
# (neg_configs[].psc), the backend service, the target TCP proxy and the
# forwarding rule, so one block covers the whole chain.
#
# forwarding_rules_config.global_access defaults to true, which closes the
# README's cross-region open point for free.
#
module "lb-http" {
  source     = "../../../modules/net-lb-proxy-int"
  project_id = var.project_id
  region     = var.region
  name       = "${var.instance_id}-http"
  vpc_config = {
    network    = var.network_config.network
    subnetwork = var.network_config.subnetwork
  }
  neg_configs = {
    ssm-http = {
      psc = {
        region         = var.region
        target_service = null # TODO module.ssm http service attachment
        network        = var.network_config.network
        subnetwork     = var.network_config.subnetwork
      }
    }
  }
  backend_service_config = {
    backends = [{ group = "ssm-http" }]
  }
  forwarding_rules_config = {
    "" = { port = 443 }
  }
}

module "lb-ssh" {
  source     = "../../../modules/net-lb-proxy-int"
  project_id = var.project_id
  region     = var.region
  name       = "${var.instance_id}-ssh"
  vpc_config = {
    network    = var.network_config.network
    subnetwork = var.network_config.subnetwork
  }
  neg_configs = {
    ssm-ssh = {
      psc = {
        region         = var.region
        target_service = null # TODO module.ssm ssh service attachment
        network        = var.network_config.network
        subnetwork     = var.network_config.subnetwork
      }
    }
  }
  backend_service_config = {
    backends = [{ group = "ssm-ssh" }]
  }
  forwarding_rules_config = {
    "" = { port = 22 }
  }
}

# ------------------------------------------------------------------------
# build: private worker pool
# ------------------------------------------------------------------------

# No Fabric module for Cloud Build worker pools. Raw resource, the only one
# in this template. The PSA range it peers over belongs to the VPC and is
# created by whoever owns it (net-vpc psa_configs), not here.
resource "google_cloudbuild_worker_pool" "default" {
  project  = var.project_id
  name     = var.worker_pool_config.name
  location = var.region
  worker_config {
    disk_size_gb   = var.worker_pool_config.disk_size_gb
    machine_type   = var.worker_pool_config.machine_type
    no_external_ip = true
  }
  network_config {
    peered_network = var.network_config.network
    # TODO peered_network_ip_range, and confirm this is the right expression
    # of --no-public-egress
  }
}

# ------------------------------------------------------------------------
# owned elsewhere, listed so the boundary is explicit
# ------------------------------------------------------------------------
#
# modules/certificate-authority-service  CA pool + CA, in the security
#   project. Plus roles/privateca.certificateRequester for this project's SSM
#   service agent, placed by the project factory
#   (service_agents_project_bindings) because the member string embeds this
#   project's number.
#
# modules/net-vpc  proxy-only subnet (REGIONAL_MANAGED_PROXY, /23), the PSA
#   range and peering for the worker pool, and peered_domains for
#   REGION.p.sourcemanager.dev. so the pool resolves the private names.
#
# modules/dns  private zone REGION.p.sourcemanager.dev. attached to the VPC,
#   four A records against the two LB addresses. Kept out because attaching a
#   zone to a VPC in the host project is a cross-project bind needing a
#   custom role.
