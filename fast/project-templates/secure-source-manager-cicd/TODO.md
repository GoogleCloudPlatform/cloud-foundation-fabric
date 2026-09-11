# TODO

Open questions and work items for this template. Written 2026-09-11, from the design in [SSM-CB.md](SSM-CB.md) and the sketch in `main.tf`. Answers belong in the README once settled; this file is scratch.

## Module and provider gaps

- [x] **`service_account` on the SSM module's repositories.** Real blocker: the provider has the field, the module had no way to set it, and the whole isolation requirement rests on it. Done in `e1a8e2af6`, along with `psc_allowed_projects`, `deletion_policy` on both resources, flattened `secret_scan_config`, and outputs for the two PSC service attachments.
- [x] **Cloud Build private worker pool.** Stays a raw `google_cloudbuild_worker_pool` in this template. Fabric does not write modules for single resources.
- [ ] **`context` support in `modules/secure-source-manager-instance`.** The module has no `context` variable at all. Out of scope for the commit above; worth its own pass if the module is on the context list.
- [ ] **`branch_rules` sits out of alphabetical order** inside the `repositories` object. Not enforced (only top-level variables are), left alone. Tidy or drop.

## Template design

- [ ] **How this template names the SSM service agent.** Project templates do not call the `project` module, so there is no `service_agents` output to take `service-<number>@gcp-sa-sourcemanager.iam.gserviceaccount.com` from. The factory tfvars does carry `number`, so a `number` variable plus interpolation works and matches how the factory feeds these templates. Alternative is `modules/projects-data-source`, which costs an API read for something we already hold.
- [x] **Two regions, and they are deliberately different.** The instance and its load balancers are in `europe-west4`, because Secure Source Manager runs in eleven regions and only `europe-west2` and `europe-west4` are in Europe. The worker pool stays in `europe-west8`, the primary location for everything else. So the template keeps both variables. `net-lb-proxy-int` defaults `forwarding_rules_config.global_access` to `true`, which is what makes the split work.
- [x] **Two projects.** `dev-build-ssm-0` holds the instance, the repositories, their BYOSAs and the whole load balancer path. `dev-build-pool-0` holds the worker pool and the build identities. One automation service account, `dev-build-ssm-0-rw`, has IAM in both, so the template spans them with a single provider. `iam.disableCrossProjectServiceAccountUsage` is already disabled on `dev-build-ssm-0` for exactly this, since the BYOSAs live there and the builds run next door.
- [ ] **Who places `roles/privateca.auditor` for the build identities.** Still open, and `dev-build-pool-0.yaml` states the blocker precisely: `iam-service-account` takes `iam_project_roles` so this template can make the grant, but something has to give `dev-build-ssm-0-rw` the right to set IAM policy on `dev-sec-core` first. Stage 0 already delegates the two privateca roles to the project factory, so the cheapest answer is probably the factory rather than here.
- [ ] **What the LB path needs in a Shared VPC service project.** Unchanged and still to be discovered by building it. `dev-build-ssm-0.yaml` flags its own `service_agent_iam` as copied from `dev-build-pool-0` and guessed, and its `network_users` as deliberately too wide — the whole VPC rather than the two `europe-west4` subnets — to be narrowed to `network_subnet_users` once we know which subnets the forwarding rules and the NEGs actually touch.
- [ ] **How the template receives the network, the CA pool and the second project.** Only `dev-build-ssm-0.auto.tfvars.json` is symlinked into this folder today. The VPC self link and subnets come from `2-networking.auto.tfvars.json`, the CA pool id from `2-security.auto.tfvars.json`, and `dev-build-pool-0` has no tfvars file at all yet. Decide which stage tfvars get symlinked in and what variables this template declares to receive them.

## Environment

- [x] **The network exists and is applied.** VPC `dev-spoke-0` at `projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0`, host project `ldj-dev-net-spoke-0` (`744301293705`), Shared VPC host enabled. Workload subnet `europe-west4/gce` at `10.8.4.0/24`. Proxy-only subnet `europe-west4/ilb-l7-ew4` at `172.16.130.0/24`, `/24` rather than the recommended `/23`. PSA range `psa-build` at `10.8.200.0/24` with `export_routes: true`.
- [x] **The CA pool exists.** `projects/ldj-dev-sec-core/locations/europe-west8/caPools/dev-ca-0`, with CA `dev-ca-0-0`. It is in `europe-west8` while the instance is in `europe-west4`, which is fine — the pool's project and location are independent of the instance's.
- [ ] **`peered_domains` is commented out** in `data/2-networking/vpcs/dev/.config.yaml`, pending the decision on which suffixes to forward. Without it the pool resolves the instance hostnames through public DNS and clone fails even though the route works. Uncomment `europe-west4.p.sourcemanager.dev.` when the instance region is committed.
- [ ] **`dev-build-pool-0` appears not to be applied.** It has a project factory definition but no tfvars file under `projects/tfvars/`, unlike `dev-build-ssm-0`. Confirm and run the factory before the template can reference it.

## Documentation holes in the README

- [ ] The landing zone snippet for the private DNS zone and its four A records, against the addresses this template outputs.
- [ ] The landing zone snippet for the PSA range and `peered_domains`, with the note that the range must not collide with the VPC's address plan.
- [ ] Remove the "nothing is implemented yet" banner once the template plans.

## Behaviour to verify against real infrastructure

From SSM-CB.md's test list; the first two can each invalidate the design.

- [ ] Confirm a pull request build runs `.cloudbuild/cloudbuild.yaml` from the pull request head commit rather than from the default branch. The third security boundary turns on this and it is currently inferred.
- [ ] Find out what omitting `serviceAccount` from a triggers file does — fail, drop the trigger silently, or fall back to an identity — and what a dropped trigger does to a branch protection rule requiring its status check.
- [ ] Confirm `google_secure_source_manager_repository` can create a repository in a PSC instance from a runner outside the VPC but inside the perimeter.
- [ ] Establish what a worker pool with no public egress can reach.
- [ ] Confirm a branch protection rule requiring a status check blocks a merge when the check fails.
- [ ] Measure actual instance creation time. Documentation says up to 60 minutes; the provider timeout is now 120.
