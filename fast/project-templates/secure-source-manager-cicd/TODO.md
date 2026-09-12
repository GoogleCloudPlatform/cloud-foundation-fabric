# TODO

The state of the work. Open items carry enough to act on; closed ones carry a line and a pointer, because the reasoning lives in README.md, SSM-CB.md or the `fast-config` YAML headers and is not repeated here. Rewritten 2026-09-14.

## Next

Order settled 2026-09-13: pool first, on its own, then the instance and the two design-invalidating trigger tests before anything else.

- [ ] **Apply the landing zone changes** in `fast-config/ludo`: the dev VPC back on `psa_configs` with `psa-build` at `10.8.200.0/24` and `ssm.gcp.qix.it.` as a peered domain, the `na` subnet and `cloudbuild-ew8` attachment gone, the empty `pvt-ssm.yaml` hub zone, and the reworded `dev-build-ssm-0.yaml` header. Then check the peering exports subnet routes and whether `--no-export-subnet-routes-with-public-ip` matters.
- [ ] **Bring the pool up on the peering** with `build-pool.tf` as it now stands, and run one build as `build-test-0` that calls an API the perimeter denies. The violation has to land in our perimeter's audit logs with the worker as the source. Same build: confirm what a no-public-egress worker reaches.
- [ ] **Wire the sketch into `main.tf`**: instance, repositories, BYOSAs, build identities, the two `net-lb-proxy-int` blocks, with a `context` variable carrying the network, CA pool and second project as logical names. The SSM module resolves context already; the template does not pass it yet.
- [ ] **Build the instance, then immediately test the two trigger behaviours** that can invalidate the design: whether a pull request build runs `.cloudbuild/cloudbuild.yaml` from the pull request head rather than the default branch, and what omitting `serviceAccount` from a triggers file does. The rest of the test list is in SSM-CB.md.
- [ ] **Fill the `pvt-ssm.yaml` records** from the load balancer addresses the template outputs, and narrow `network_users` in `dev-build-ssm-0.yaml` to `network_subnet_users` on `europe-west4/gce` and `europe-west4/ilb-l7-ew4` once we know what the service project needs. `service_agent_iam` there is a guess copied from the pool project.
- [ ] **How this template names the SSM service agent.** No `project` module here, so no `service_agents` output. The factory tfvars carries `number`; a `number` variable plus interpolation is the cheap answer, `modules/projects-data-source` the one that costs an API read.
- [ ] **README**: landing zone snippets for the hub zone and the peering are in now; drop the "nothing is implemented yet" banner once the template plans, and tidy `branch_rules` into alphabetical order in the SSM module's `repositories` object while in the file.

## Settled

- **Private Service Connect for the pool is gated** (2026-09-13). Evidence in SSM-CB.md. The design uses private service access and switches back when the allowlist opens; the load balancers and the hub zone are unaffected by that switch.
- **Load balancers, not endpoints** (2026-09-14). An endpoint address does not cross the peering the workers now sit behind; a forwarding rule address does, and it serves the hub and on-premises too. README, access path section.
- **DNS is one private zone in the hub**, `ssm.gcp.qix.it.`, plus a peered domain on the PSA peering so the workers see it. README, DNS section.
- **`compute.vmExternalIpAccess` is no backstop** for worker public IPs; the tenant project is outside our organisation. SSM-CB.md, gated section.
- **`psc_allowed_projects` is immutable**; list every VPC host project at creation. Recorded in `dev-build-ssm-0.yaml`.
- **Custom hostnames** under `ssm.gcp.qix.it`: `api.`, `git.`, `ssh.` and the apex. Survive a rebuild and take the region out of the suffix. Module support in `b4467f49e`.
- **Two regions**: instance and load balancers in `europe-west4`, pool in `europe-west8`, joined by `global_access`.
- **Two projects**, one automation seat spanning both; `iam.disableCrossProjectServiceAccountUsage` off on `dev-build-ssm-0`.
- **CA pool is mandatory** inside a perimeter, and `roles/privateca.auditor` for the build identities is placed by this template under a delegated `projectIamAdmin` on `dev-sec-core`. README, CA pool section.
- **`roles/iam.serviceAccountTokenCreator`** on Terraform accounts: from here for application pipelines, from stage 0 as static context entries for FAST stages. README, CA pool section.
- **Module work done**: `service_account` on repositories, `psc_allowed_projects`, `deletion_policy`, flattened `secret_scan_config`, service attachment outputs (`e1a8e2af6`); `context` support with `ca_pools` as a new key; `network_attachment_ids` on the 2-networking stage. The pool stays a raw resource.

## Follow-up, outside this template

- **IAM conditions on the SSM module.** `iam_bindings` and `iam_bindings_additive` carry no `condition` and all three IAM variables share the description `"IAM bindings."`. Module surface, not provider lag, and Fabric's standard interfaces are a promise. Nothing here waits on it; a different branch.
- **`requiredStatusChecks` and `requireCodeOwnerApproval` on branch rules.** The REST resource has both, `BranchRule.yaml` in Magic Modules has neither. Contribute upstream, then add to the module. Until then both are set in the web interface and the README's security note says so.
