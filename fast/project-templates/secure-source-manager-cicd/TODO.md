# TODO

The state of the work. Open items carry enough to act on; closed ones carry a line and a pointer, because the reasoning lives in README.md, SSM-CB.md or the `fast-config` YAML headers and is not repeated here. Rewritten 2026-09-14.

## Next



Order settled 2026-09-13: pool first, on its own, then the instance and the two design-invalidating trigger tests before anything else.

- [ ] **Write the delegation on `dev-sec-core`**: a conditioned `roles/resourcemanager.projectIamAdmin` for `dev-build-ssm-0-rw`, limited to `roles/privateca.auditor`, in the security project's data. Settled 2026-09-12, never written. Without it the build identities' `iam_project_roles` grant fails on first apply.
- [ ] **Wire the sketch into `main.tf`**: instance, repositories, BYOSAs, build identities, the two `net-lb-proxy-int` blocks, with a `context` variable carrying the network, CA pool and second project as logical names. The SSM module resolves context already; the template does not pass it yet.
- [ ] **Build the instance, then immediately test the two trigger behaviours** that can invalidate the design: whether a pull request build runs `.cloudbuild/cloudbuild.yaml` from the pull request head rather than the default branch, and what omitting `serviceAccount` from a triggers file does. The rest of the test list is in SSM-CB.md.
- [ ] **Fill the `pvt-ssm.yaml` records** from the load balancer addresses the template outputs, and narrow `network_users` in `dev-build-ssm-0.yaml` to `network_subnet_users` on `europe-west4/gce` and `europe-west4/ilb-l7-ew4` once we know what the service project needs. `service_agent_iam` there is a guess copied from the pool project.
- [ ] **How this template names the SSM service agent.** No `project` module here, so no `service_agents` output. The factory tfvars carries `number`; a `number` variable plus interpolation is the cheap answer, `modules/projects-data-source` the one that costs an API read.
- [ ] **README**: landing zone snippets for the hub zone and the peering are in now; drop the "nothing is implemented yet" banner once the template plans, and tidy `branch_rules` into alphabetical order in the SSM module's `repositories` object while in the file.

## Settled

- **The instance is up on the DevOps pool** (2026-09-12), `test-0-dev-0` in `europe-west4` against `dev-ca-3`, built in 27 minutes. Instance ids are reusable after deletion, unlike CA pool ids, so a rebuild costs half an hour and nothing else. The service attachments move to a new tenant project on every rebuild, so nothing downstream may hardcode them.

- **DevOps tier pools work, and the tier is a cost decision** (2026-09-12). `$200` per CA per month for Enterprise against `$20` for DevOps, and what Enterprise buys is listing, describing and revoking certificates. This playground runs DevOps on `dev-ca-3`; production should weigh revocation against the ten-fold price. README, CA pool section.

- **The CA pool has to be in the instance's region** (2026-09-12). A pool in `europe-west8` against an instance in `europe-west4` fails `CreateInstance` with a permission error that is not about permissions and produces no logs anywhere. SSM-CB.md has the full elimination trail, which is worth reading before trusting any other "missing permission" from this API.

- **The pool is up and the perimeter sees it correctly** (2026-09-12). Running on the PSA peering with a `/26` carved from `psa-build`. A probe build proved the producer project is inside our perimeter and that the BYOSA is the attributed principal; the worker has no public egress and resolves both Google API VIPs. SSM-CB.md, attribution section. The pool project needs `servicenetworking.googleapis.com` enabled even though the connection lives in the host project.
- **The networking stage is applied** (2026-09-14). PSA range `psa-build`, the service networking connection, the `ssm.gcp.qix.it.` peered domain and the `pvt-ssm` hub zone are live; the `na` subnet and `cloudbuild-ew8` attachment are gone. The peering came up with `exportSubnetRoutesWithPublicIp: false` on its own, so `--no-export-subnet-routes-with-public-ip` needs no module work.

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

- **Publish CA bundles to a bucket instead of granting read on the CA.** Rough shape, not validated. `modules/certificate-authority-service` already takes `ca_configs.<ca>.gcs_bucket`, resolved through a `storage_buckets` context key, and `ca_pool_config.create_pool.publishing_options` with `publish_ca_cert` and `publish_crl`. The 2-security stage does not carry it: `context` in `defaults.schema.json` has no `storage_buckets` key, so a bucket cannot be named symbolically from a CA definition, and nothing anywhere handles a managed folder to scope access to one bundle rather than a whole bucket. With this, a consumer reads the chain from the folder and needs no role on the CA project at all, which removes both the per-identity grant and the delegation that enables it. The cost is a published artifact that has to stay current across CA rotation, against a live fetch that cannot go stale.

- **IAM conditions on the SSM module.** `iam_bindings` and `iam_bindings_additive` carry no `condition` and all three IAM variables share the description `"IAM bindings."`. Module surface, not provider lag, and Fabric's standard interfaces are a promise. Nothing here waits on it; a different branch.
- **`requiredStatusChecks` and `requireCodeOwnerApproval` on branch rules.** The REST resource has both, `BranchRule.yaml` in Magic Modules has neither. Contribute upstream, then add to the module. Until then both are set in the web interface and the README's security note says so.
