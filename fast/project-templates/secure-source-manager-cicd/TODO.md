# TODO

The state of the work. Open items carry enough to act on; closed ones carry a line and a pointer, because the reasoning lives in README.md, SSM-CB.md or the `fast-config` YAML headers and is not repeated here. Rewritten 2026-09-12.

## Next

The order is pool, then instance, then repositories. Pool and instance are up. Everything below is the third step and what follows it, and the two trigger tests come before any polish, because they can still invalidate the design.

- [ ] **The two load balancers.** `net-lb-proxy-int` in front of each service attachment, shape in SKETCH.md with verified attribute names. Take the attachments from `module.ssm-instance` outputs and never hardcode them: the tenant project changes on every rebuild. Proxy-only subnet is `europe-west4/ilb-l7-ew4`, addresses come from `europe-west4/gce`.
- [ ] **Fill the `pvt-ssm.yaml` records** in `fast-config` from the forwarding rule addresses the template outputs: `api`, `git` and the apex on the HTTP load balancer, `ssh` on the SSH one. The zone is live and empty.
- [ ] **Repositories and the identity chain.** `ssm-repositories.tf` holds one BYOSA stub with the act-as edges and the Cloud Build roles; the repository itself, the build identities and the `n>1` variable shape are not written. The stub's service agent member string is commented out pending the item below.
- [ ] **How this template names the SSM service agent.** No `project` module here, so no `service_agents` output. The factory tfvars carries `number` at the top level, so a bare `number` variable picks it up for free; `modules/projects-data-source` is the alternative and costs an API read.
- [ ] **The two trigger behaviours that can invalidate the design**: whether a pull request build runs `.cloudbuild/cloudbuild.yaml` from the pull request head rather than the default branch, and what omitting `serviceAccount` from a triggers file does. The rest of the test list is in SSM-CB.md.
- [ ] **Prove the access path end to end**: a worker on the peering reaching a load balancer address and resolving `git.ssm.gcp.qix.it` through the peered domain. Both are still inferred. `builds/probe.yaml` is the pattern for this kind of test.
- [ ] **Narrow `network_users`** in `dev-build-ssm-0.yaml` to `network_subnet_users` on `europe-west4/gce` and `europe-west4/ilb-l7-ew4` once the load balancers show what the service project actually needs.
- [ ] **README**: drop the "nothing is implemented yet" banner, and tidy `branch_rules` into alphabetical order in the SSM module's `repositories` object while in the file.
- [ ] **Test the `dev-sec-core` delegation.** Written and applied, never exercised: nothing has used it because the build identities do not exist yet.

## Settled

- **The instance is up on the DevOps pool** (2026-09-12), `test-0-dev-0` in `europe-west4` against `dev-ca-3`, built in 27 minutes. Instance ids are reusable after deletion, unlike CA pool ids, so a rebuild costs half an hour and nothing else. The service attachments move to a new tenant project on every rebuild, so nothing downstream may hardcode them.

- **DevOps tier pools work, and the tier is a cost decision** (2026-09-12). `$200` per CA per month for Enterprise against `$20` for DevOps, and what Enterprise buys is listing, describing and revoking certificates. This playground runs DevOps on `dev-ca-3`; production should weigh revocation against the ten-fold price. README, CA pool section.

- **The CA pool has to be in the instance's region** (2026-09-12). A pool in `europe-west8` against an instance in `europe-west4` fails `CreateInstance` with a permission error that is not about permissions and produces no logs anywhere. SSM-CB.md has the full elimination trail, which is worth reading before trusting any other "missing permission" from this API.

- **The pool is up and the perimeter sees it correctly** (2026-09-12). Running on the PSA peering with a `/26` carved from `psa-build`. A probe build proved the producer project is inside our perimeter and that the BYOSA is the attributed principal; the worker has no public egress and resolves both Google API VIPs. SSM-CB.md, attribution section. The pool project needs `servicenetworking.googleapis.com` enabled even though the connection lives in the host project.
- **The networking stage is applied** (2026-09-12). PSA range `psa-build`, the service networking connection, the `ssm.gcp.qix.it.` peered domain and the `pvt-ssm` hub zone are live; the `na` subnet and `cloudbuild-ew8` attachment are gone. The peering came up with `exportSubnetRoutesWithPublicIp: false` on its own, so `--no-export-subnet-routes-with-public-ip` needs no module work.

- **Private Service Connect for the pool is gated** (2026-09-12). Evidence in SSM-CB.md. The design uses private service access and switches back when the allowlist opens; the load balancers and the hub zone are unaffected by that switch.
- **Load balancers, not endpoints** (2026-09-12). An endpoint address does not cross the peering the workers now sit behind; a forwarding rule address does, and it serves the hub and on-premises too. README, access path section.
- **DNS is one private zone in the hub**, `ssm.gcp.qix.it.`, plus a peered domain on the PSA peering so the workers see it. README, DNS section.
- **`compute.vmExternalIpAccess` is no backstop** for worker public IPs; the tenant project is outside our organisation. SSM-CB.md, gated section.
- **`psc_allowed_projects` is immutable**; list every VPC host project at creation. Recorded in `dev-build-ssm-0.yaml`.
- **Custom hostnames** under `ssm.gcp.qix.it`: `api.`, `git.`, `ssh.` and the apex. Survive a rebuild and take the region out of the suffix. Module support in `b4467f49e`.
- **Two regions**: instance, CA pool and load balancers in `europe-west4`, build pool in `europe-west8`, joined by `global_access`. The CA pool has no choice; the build pool does.
- **The delegation on `dev-sec-core` is written and applied** (2026-09-12): a conditioned `projectIamAdmin` for `dev-build-ssm-0-rw` allowing only `privateca.certificateRequester` and `privateca.auditor`, with the account named through a static `iam_principals` entry in the security stage's `defaults.yaml`.
- **Two projects**, one automation seat spanning both; `iam.disableCrossProjectServiceAccountUsage` off on `dev-build-ssm-0`.
- **CA pool is mandatory** inside a perimeter, and `roles/privateca.auditor` for the build identities is placed by this template under a delegated `projectIamAdmin` on `dev-sec-core`. README, CA pool section.
- **`roles/iam.serviceAccountTokenCreator`** on Terraform accounts: from here for application pipelines, from stage 0 as static context entries for FAST stages. README, CA pool section.
- **Module work done**: `service_account` on repositories, `psc_allowed_projects`, `deletion_policy`, flattened `secret_scan_config`, service attachment outputs (`e1a8e2af6`); `context` support with `ca_pools` as a new key; `network_attachment_ids` on the 2-networking stage. The pool stays a raw resource.

## Follow-up, outside this template

- **Publish CA bundles to a bucket instead of granting read on the CA.** Rough shape, not validated. `modules/certificate-authority-service` already takes `ca_configs.<ca>.gcs_bucket`, resolved through a `storage_buckets` context key, and `ca_pool_config.create_pool.publishing_options` with `publish_ca_cert` and `publish_crl`. The 2-security stage does not carry it: `context` in `defaults.schema.json` has no `storage_buckets` key, so a bucket cannot be named symbolically from a CA definition, and nothing anywhere handles a managed folder to scope access to one bundle rather than a whole bucket. With this, a consumer reads the chain from the folder and needs no role on the CA project at all, which removes both the per-identity grant and the delegation that enables it. The cost is a published artifact that has to stay current across CA rotation, against a live fetch that cannot go stale.

- **IAM conditions on the SSM module.** `iam_bindings` and `iam_bindings_additive` carry no `condition` and all three IAM variables share the description `"IAM bindings."`. Module surface, not provider lag, and Fabric's standard interfaces are a promise. Nothing here waits on it; a different branch.
- **`requiredStatusChecks` and `requireCodeOwnerApproval` on branch rules.** The REST resource has both, `BranchRule.yaml` in Magic Modules has neither. Contribute upstream, then add to the module. Until then both are set in the web interface and the README's security note says so.
