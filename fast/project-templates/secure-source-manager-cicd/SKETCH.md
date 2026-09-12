# The sketch

The parts of this configuration that are not live yet, kept as a sketch. They were comments inside `main.tf` until 2026-09-13, which left that file mostly prose; it now carries only code that runs, and everything explanatory lives in a document instead. Reasoning is in [README.md](README.md), open questions in [TODO.md](TODO.md), observed behaviour and caveats in [SSM-CB.md](SSM-CB.md).

Attribute names below were taken from each module's `variables.tf` where they were verified, and marked TODO where they were not. Nothing here is expected to plan.

The configuration spans two projects with one provider, because one automation service account, `dev-build-ssm-0-rw`, holds IAM in both. The instance project holds the instance, its repositories, their per-repository service accounts and the Private Service Connect endpoints fronting the service attachments, in `europe-west4` — Secure Source Manager runs in eleven regions and only two are in Europe. The build project holds the private worker pool and the build identities the triggers file names, in `europe-west8`, the primary location for everything else here. The regions differ on purpose, and `global_access` on the endpoints is what lets a pool in one reach endpoints in the other across the same VPC.

## Blocks

```hcl
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
    # custom hostnames under ssm.gcp.qix.it, in place of the generated ones
    # under europe-west4.p.sourcemanager.dev. The generated names embed the
    # instance id and the project number, so they change on any rebuild;
    # these are ours and survive one. All four are required by the API, and
    # their certificate is signed by the CA pool above.
    custom_host_config = {
      api      = "api.${var.domain}"
      git_http = "git.${var.domain}"
      git_ssh  = "ssh.${var.domain}"
      html     = var.domain
    }
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

# One endpoint per service attachment and no load balancers. The instance
# publishes the two attachments and nothing else; who may connect to them is
# psc_allowed_projects on the instance, granted per project.
#
# global_access is what makes the region split work: the endpoints are in
# europe-west4 with the instance, while the worker pool and everything else
# are in europe-west8 of this same VPC.
#
# The limit to know: an endpoint address is reachable only from inside its own
# VPC, never across a peering, VPN or Interconnect. Clients on the hub or
# on-premises therefore need either their own endpoint and their own private
# zone, or the fallback in the README — a net-lb-proxy-int per attachment,
# whose forwarding rule is an ordinary internal address that peering carries.
module "psc-endpoints" {
  source     = "../../../modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    "${var.instance_id}-http" = {
      region           = var.region
      subnet_self_link = var.network_config.subnetwork
      service_attachment = {
        psc_service_attachment_link = module.ssm.http_service_attachment
        global_access               = true
      }
    }
    "${var.instance_id}-ssh" = {
      region           = var.region
      subnet_self_link = var.network_config.subnetwork
      service_attachment = {
        psc_service_attachment_link = module.ssm.ssh_service_attachment
        global_access               = true
      }
    }
  }
}

# ------------------------------------------------------------------------
# build: private worker pool
# ------------------------------------------------------------------------

# Raw resource by decision: Fabric does not write modules for single
# resources.
#
# private_service_connect and network_config are mutually exclusive, and this
# is the whole reason the design has no peered DNS domain: on an attachment
# the workers hold an interface in the VPC, so they resolve against its
# resolver and see its private zones. The attachment is regional and lives in
# the pool's region, europe-west8/na in the dev VPC, created by the networking
# stage rather than here.
#
# route_all_traffic sends public egress through the VPC as well as private, so
# builds reach the internet through nat-ew8 and under this VPC's controls.
resource "google_cloudbuild_worker_pool" "default" {
  project  = var.pool_project_id
  name     = var.worker_pool_config.name
  location = var.pool_region
  worker_config {
    disk_size_gb   = var.worker_pool_config.disk_size_gb
    machine_type   = var.worker_pool_config.machine_type
    no_external_ip = true
  }
  private_service_connect {
    network_attachment = var.network_config.network_attachment
    route_all_traffic  = true
  }
}
```

## Owned elsewhere

Listed so the boundary is explicit.

- **2-security** — the CA pool and CA, `dev-ca-0` in `ldj-dev-sec-core`, plus `roles/privateca.certificateRequester` for the instance project's Secure Source Manager service agent. The factory places that one through `service_agents_project_bindings`, because the member string embeds the project number. Already in `dev-build-ssm-0.yaml`.
- **2-networking** — the `europe-west4` workload subnet the endpoints sit in, the `europe-west8/na` subnet at `10.8.208.0/24`, and the `cloudbuild-ew8` network attachment on it. The proxy-only subnet and the `psa-build` range are no longer part of this design and the range is free.
- **2-networking DNS** — resolution for `ssm.gcp.qix.it`, through response policy rules on the dev VPC rather than a zone, since an endpoint address is not network-wide. Kept out because the addresses are outputs here and the records are owned there. See the DNS section in README.md for why a zone in the hub would resolve for clients that cannot reach the address.
