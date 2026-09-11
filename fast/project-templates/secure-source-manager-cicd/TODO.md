# TODO

Open questions and work items for this template. Written 2026-09-11, from the design in [SSM-CB.md](SSM-CB.md) and the sketch in `main.tf`. Answers belong in the README once settled; this file is scratch.

## Module and provider gaps

- [x] **`service_account` on the SSM module's repositories.** Real blocker: the provider has the field, the module had no way to set it, and the whole isolation requirement rests on it. Done in `e1a8e2af6`, along with `psc_allowed_projects`, `deletion_policy` on both resources, flattened `secret_scan_config`, and outputs for the two PSC service attachments.
- [ ] **Cloud Build private worker pool.** No Fabric module exists — `google_cloudbuild_worker_pool` appears in the repo only under `tests/fixtures/`. Decide: add a module (thin, roughly name / location / machine type / disk / peered network / no external IP), or keep the raw resource in this template and accept the one departure from "prefer modules".
- [ ] **`context` support in `modules/secure-source-manager-instance`.** The module has no `context` variable at all. Out of scope for the commit above; worth its own pass if the module is on the context list.
- [ ] **`branch_rules` sits out of alphabetical order** inside the `repositories` object. Not enforced (only top-level variables are), left alone. Tidy or drop.

## Template design

- [ ] **How this template names the SSM service agent.** Project templates do not call the `project` module, so there is no `service_agents` output to take `service-<number>@gcp-sa-sourcemanager.iam.gserviceaccount.com` from. The factory tfvars does carry `number`, so a `number` variable plus interpolation works and matches how the factory feeds these templates. Alternative is `modules/projects-data-source`, which costs an API read for something we already hold.
- [ ] **One region or two.** The sketch keeps `location` (instance) and `region` (LBs, worker pool) separate because SSM runs in only eleven regions. If they are always equal, collapse to one variable. Note `net-lb-proxy-int` defaults `forwarding_rules_config.global_access` to `true`, so the cross-region reachability concern in the README is already covered either way.
- [ ] **Project boundary.** The sketch puts BYOSAs, build identities, instance and pool all in one project, which sidesteps the `iam.disableCrossProjectServiceAccountUsage` caveat. If builds run in a separate project that caveat returns and `iam_project_roles` on the BYOSAs points elsewhere.
- [ ] **Who places `roles/privateca.auditor` for the build identities.** From here via `iam_project_roles` on the build SAs, or from the project factory. It decides which identity the delegated `projectIamAdmin` on the CA pool's project has to name. Carried over from the README's open points.
- [ ] **What the LB path needs in a Shared VPC service project.** A PSC NEG plus a regional internal proxy LB may need more than `roles/compute.networkUser` for the compute service agent, particularly on the proxy-only subnet. To be established by building it.

## Environment

- [ ] **What exists in the playground today.** Is there a VPC with a proxy-only subnet and a PSA range, and a CA pool? Or are we standing those up too? Nothing can be applied until this is known.

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
