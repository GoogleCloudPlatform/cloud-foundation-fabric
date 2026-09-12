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
# network: load balancers in front of the instance
# ------------------------------------------------------------------------

# One regional internal proxy load balancer per service attachment, as in
# Google's guide: PSC NEG, backend service, target TCP proxy, forwarding rule.
# The forwarding rule address is an ordinary internal address that peering,
# VPN and Interconnect carry, which is what lets the build workers reach the
# instance from the producer side of the private service access peering, and
# the hub and on-premises clients from theirs. A PSC endpoint would not: its
# address is valid only inside the VPC that holds it.
#
# The proxy carries no certificate. TLS runs end to end from the client to the
# instance, whose certificate covers the custom hostnames.
#
# global_access is the module default and is what makes the region split
# work: the load balancers are in europe-west4 with the instance, while the
# pool and everything else are in europe-west8. The proxy-only subnet is
# europe-west4/ilb-l7-ew4 in the dev VPC.
module "lb" {
  source     = "../../../modules/net-lb-proxy-int"
  for_each = {
    http = { port = 443, attachment = module.ssm.http_service_attachment }
    ssh  = { port = 22, attachment = module.ssm.ssh_service_attachment }
  }
  project_id = var.project_id
  region     = var.region
  name       = "${var.instance_id}-${each.key}"
  forwarding_rules_config = {
    "" = { port = each.value.port }
  }
  backend_service_config = {
    backends = [{ group = "${var.instance_id}-${each.key}" }]
  }
  neg_configs = {
    "${var.instance_id}-${each.key}" = {
      psc = {
        network        = var.network_config.vpc_self_link
        subnetwork     = var.network_config.subnetwork
        region         = var.region
        producer_port  = each.value.port
        target_service = each.value.attachment
      }
    }
  }
  vpc_config = {
    network    = var.network_config.vpc_self_link
    subnetwork = var.network_config.subnetwork
  }
}

# ------------------------------------------------------------------------
# build: private worker pool
# ------------------------------------------------------------------------

# Raw resource by decision: Fabric does not write modules for single
# resources. Live in build-pool.tf; kept here for the shape.
#
# The workers reach the VPC over a private service access peering on the
# psa-build range, created by the networking stage. Private Service Connect
# through a network attachment was the first choice and is gated; see
# SSM-CB.md. Name resolution needs the peered_domains entry on that peering,
# since a worker on the producer side does not see the VPC's zones.
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
    peered_network          = var.network_config.vpc_self_link
    peered_network_ip_range = var.network_config.build_psa_range
  }
}
```

## Owned elsewhere

Listed so the boundary is explicit.

- **2-security** — the CA pool and CA, `dev-ca-0` in `ldj-dev-sec-core`, plus `roles/privateca.certificateRequester` for the instance project's Secure Source Manager service agent. The factory places that one through `service_agents_project_bindings`, because the member string embeds the project number. Already in `dev-build-ssm-0.yaml`.
- **2-networking** — the `europe-west4/gce` subnet the forwarding rule addresses come from, the proxy-only subnet `europe-west4/ilb-l7-ew4`, and the private service access peering on `psa-build` at `10.8.200.0/24` with `ssm.gcp.qix.it.` as a peered domain.
- **2-networking DNS** — the `ssm.gcp.qix.it.` private zone in the hub, `pvt-ssm.yaml` under `net-core-0`. Kept out because the addresses are outputs here and the records are owned there; the records are filled in after the first apply.
