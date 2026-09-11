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
# they still have to be checked.
#
# The template spans two projects with one provider, because one automation
# service account (dev-build-ssm-0-rw) holds IAM in both:
#
#   var.project_id       the instance, its repositories, their BYOSAs, and the
#                        load balancer path fronting the service attachments.
#                        europe-west4, because Secure Source Manager runs in
#                        eleven regions and only two are in Europe.
#   var.pool_project_id  the Cloud Build private worker pool and the build
#                        identities the triggers file names. europe-west8, the
#                        primary location for everything else here.
#
# The regions differ on purpose. Regional internal proxy load balancers need
# global access on their forwarding rules for a pool in another region to
# reach them, which net-lb-proxy-int enables by default.

# ------------------------------------------------------------------------
# source: instance and repositories
# ------------------------------------------------------------------------

module "ssm" {
  source     = "../../../modules/secure-source-manager-instance"
  project_id = var.project_id
  location   = var.region
  # the instance id ends up inside every hostname, DNS record and clone URL,
  # and nothing about an instance can be changed after creation
  instance_id = var.instance_id
  private_configs = {
    is_private = true
    # projects/ldj-dev-sec-core/locations/europe-west8/caPools/dev-ca-0 in the
    # playground. The pool's project and location are independent of the
    # instance's, so europe-west8 here against europe-west4 above is fine
    ca_pool_id = var.ca_pool_id
  }
  repositories = {
    for k, v in var.repositories : k => {
      description     = v.description
      branch_rules    = v.branch_rules
      service_account = module.repo-sa[k].email
      iam = {
        # build identities this repository's pipelines may run as get
        # repoReader here, on the repository, never on the project
        "roles/securesourcemanager.repoReader" = [
          for sa in v.build_identities : module.build-sa[sa].iam_email
        ]
      }
    }
  }
  # every build identity needs instanceAccessor on the instance itself
  iam = {
    "roles/securesourcemanager.instanceAccessor" = [
      for k, v in module.build-sa : v.iam_email
    ]
  }
}

# ------------------------------------------------------------------------
# identity
# ------------------------------------------------------------------------

# One BYOSA per repository, in the instance project. iam_sa_roles carries the
# act-as edges: a map of target service account id to roles, granted on the
# target service account resource rather than on a project, which is the rule
# the whole isolation requirement rests on.
#
# These live in var.project_id while the builds they create run in
# var.pool_project_id, which is why dev-build-ssm-0 disables
# iam.disableCrossProjectServiceAccountUsage. Only the project hosting the
# service account needs that; the resource side needs no mirror.
module "repo-sa" {
  source     = "../../../modules/iam-service-account"
  for_each   = var.repositories
  project_id = var.project_id
  name       = "ssm-repo-${each.key}"
  # the Secure Source Manager service agent mints tokens for this BYOSA.
  # No project module here, so no service_agents output to take the member
  # string from: it is built from var.project_number, which the project
  # factory tfvars already carry.
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      "serviceAccount:service-${var.project_number}@gcp-sa-sourcemanager.iam.gserviceaccount.com"
    ]
  }
  iam_sa_roles = {
    for sa in each.value.build_identities :
    module.build-sa[sa].id => ["roles/iam.serviceAccountUser"]
  }
  # the BYOSA creates builds in the pool project, so its Cloud Build roles
  # land there rather than here
  iam_project_roles = {
    (var.pool_project_id) = [
      "roles/cloudbuild.builds.editor",
      "roles/cloudbuild.workerPoolUser",
      "roles/serviceusage.serviceUsageConsumer",
    ]
  }
}

# The build identities the triggers file names, in the pool project alongside
# the pool they run on.
module "build-sa" {
  source     = "../../../modules/iam-service-account"
  for_each   = var.build_identities
  project_id = var.pool_project_id
  name       = each.key
  iam_project_roles = {
    (var.pool_project_id) = ["roles/logging.logWriter"]
    # TODO roles/privateca.auditor on the CA pool's project, to fetch the
    # certificate chain. Open: this template's automation service account has
    # no right to set IAM policy on dev-sec-core, and stage 0 already
    # delegates the privateca roles to the project factory, so the grant may
    # belong there instead.
  }
  # impersonation of the terraform service accounts the pipeline uses
  iam_sa_roles = each.value.impersonate_service_accounts
}

# ------------------------------------------------------------------------
# network: PSC access path to the instance
# ------------------------------------------------------------------------

# net-lb-proxy-int creates the PSC NEG, the backend service, the target TCP
# proxy and the forwarding rule, so one block per attachment covers the whole
# chain. The proxy-only subnet is not an input: it only has to exist in the
# region, and europe-west4/ilb-l7-ew4 (172.16.130.0/24) already does.
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
        target_service = module.ssm.http_service_attachment
        network        = var.network_config.network
        subnetwork     = var.network_config.subnetwork
      }
    }
  }
  backend_service_config = {
    backends = [{ group = "ssm-http" }]
  }
  # global_access defaults to true, which is what lets the europe-west8 pool
  # reach these europe-west4 forwarding rules
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
        target_service = module.ssm.ssh_service_attachment
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

# Raw resource by decision: Fabric does not write modules for single
# resources. The PSA range this peers over is psa-build, 10.8.200.0/24 in the
# dev VPC, created by the networking stage rather than here.
resource "google_cloudbuild_worker_pool" "default" {
  project  = var.pool_project_id
  name     = var.worker_pool_config.name
  location = var.pool_region
  worker_config {
    disk_size_gb   = var.worker_pool_config.disk_size_gb
    machine_type   = var.worker_pool_config.machine_type
    no_external_ip = true
  }
  network_config {
    peered_network = var.network_config.network
    # TODO peered_network_ip_range, and confirm this is how the provider
    # expresses --no-public-egress
  }
}

# ------------------------------------------------------------------------
# owned elsewhere, listed so the boundary is explicit
# ------------------------------------------------------------------------
#
# 2-security  the CA pool and CA, dev-ca-0 in ldj-dev-sec-core. Plus
#   roles/privateca.certificateRequester for this project's Secure Source
#   Manager service agent, placed by the project factory through
#   service_agents_project_bindings because the member string embeds this
#   project's number. Already in dev-build-ssm-0.yaml.
#
# 2-networking  the europe-west4 workload and proxy-only subnets, and the
#   psa-build range with export_routes. All applied. Still to do there:
#   peered_domains for europe-west4.p.sourcemanager.dev., currently commented
#   out, without which the pool resolves the instance hostnames through public
#   DNS and clone fails even though the route works.
#
# 2-networking DNS  the private zone for europe-west4.p.sourcemanager.dev.
#   attached to the VPC, and four A records against the two load balancer
#   addresses this template outputs. Kept out because the addresses are
#   outputs here and the records are owned there.
