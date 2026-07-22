# Landing Zone Deployment State

Living breadcrumb for standing up the StayHome AI GCP landing zone with **Fabric FAST v57.0.0**.
Single source of truth for gathered values, locked decisions, and stage progress — read this first
when resuming in a new session.

Companion: [landing-zone-design.md](landing-zone-design.md) (architecture, still valid).
The old `landing-zone-implementation-plan.md` was scrapped (2026-07-22) — it was written against
classic multi-stage FAST and outdated YAML-factory mechanics; this doc is now the sole source of
truth for stage mechanics, see "Stage map" below for the v57 reality.

---

## ▶ Resume pointer

- **Current stage:** `0-org-setup` — **first apply succeeded** 2026-07-22, **state migrated** to
  the GCS backend same day. Both confirmed via clean `terraform plan` (zero changes).
- **Branch:** `landing-zone-stage-0` (PR: `Stayhome-AI/cloud-foundation-fabric#1`)
- **Next action:** wire + prove CI/CD via WIF (last item in the stage-0 checklist below), then
  clean up `org_policies_imports` from the tfvars. This was a long first-apply saga (billing quota,
  a soft-deleted project id, ADC reauth, a project-factory `log_buckets` gap, a boolean-org-policy
  fallback rule, and a cross-project metric-ownership rule) — every one of them is written up in
  the checklist/breadcrumbs below and in
  [upstream-bug-log-buckets-cross-project-ctx.md](upstream-bug-log-buckets-cross-project-ctx.md).
- **Working method:** edit the `datasets/classic` dataset **in place** (keeps clean diffs vs
  `fast_version.txt` on future upgrades). Configure via **YAML factories**, not `.tfvars`.
- **Repo:** this fork (`Stayhome-AI/cloud-foundation-fabric`) *is* the monorepo — CI/CD runs
  directly out of `fast/stages/0-org-setup` etc., no separate `iac-foundation` repo. The earlier
  `iac-foundation` repo (partial hand-copy of fabric) is abandoned; it's what caused the "partial
  fabric repo" problems from the prior session.

---

## 🔒 Locked decisions

| Decision | Choice | Rationale |
|---|---|---|
| FAST version | **v57.0.0** (new consolidated layout) | Already cloned; `0-org-setup` = old `0-bootstrap` + `1-resman` merged |
| Dataset | **classic + cherry-pick hardened** | classic org-policies already = design §7; add hardened's 10 detective alerts + born-with-it constraints only. Full hardened deferred to Phase B |
| Dataset editing | **edit `datasets/classic` in place** | Clean upstream diffs; avoids maintaining a forked dataset name |
| Folder layout | **FAST as-shipped (Networking / Security / Teams) + top-level `Sandbox`** | Trust FAST's team-scalable pattern; Sandbox is the one additive, design-driven deviation (relaxed policy + hard budget cap) |
| Environments | **`dev`, `staging`, `prod`** (staging added 2026-07-22) | Partner agreement; originally deferred to Phase B (design §2), front-loaded since env is a data-driven tag/map, cheap to add pre-apply. HA custom constraint stays production-only (cost) |
| Prefix | **`shai`** | Immutable — baked into every project ID |
| Region | **`us-central1`** (primary); US multi-region for audit-log/backup buckets only | design §5 / cost-conscious |
| Identity | Groups-only IAM; WIF-only (no SA keys ever); break-glass excluded from SSO | design §4 |
| Git/CI | Monorepo `Stayhome-AI/iac-foundation`, path-filtered workflows | design §9. **NB:** FAST classic default is repo-per-stage — CI/CD wiring step adapts this |

---

## 📋 Required inputs — stage 0 (`0-org-setup`)

Fill the **Value** column (or paste to me and I'll transcribe). Sensitive-but-not-secret IDs
(org, billing, customer) are committed into `defaults.yaml` — this is the standard FAST flow;
keep the repo **private**.

| # | Value | Format / example | Source | Lands in | Value | Status |
|---|---|---|---|---|---|---|
| 1 | Organization ID | `123456789012` (numeric) | `gcloud organizations list` (Phase 0.1) | `defaults.yaml` global.organization.id | 15122406886 | ✅ |
| 2 | Customer ID | `C0xxxxxxx` | `gcloud organizations list --format="value(owner.directoryCustomerId)"` | `defaults.yaml` global.organization.customer_id | C03ayt8zz | ✅ |
| 3 | Domain | `stayhome-ai.com` | known | `defaults.yaml` global.organization.domain | `stayhome-ai.com` | ✅ |
| 4 | Billing Account ID | `XXXXXX-XXXXXX-XXXXXX` | `gcloud beta billing accounts list` (Phase 0.3) | `defaults.yaml` global.billing_account | 01425B-C8ADCC-9C38B7 | ✅ |
| 5 | Billing account type | `org-owned` **or** `external` | how you set it up | billing factory works as-is for org-owned (account-level IAM) | org-owned | ✅ |
| 6 | Org-admins group email | `gcp-organization-admins@stayhome-ai.com` | Phase 0.4 | `defaults.yaml` context.iam_principals + email_addresses | gcp-organization-admins@stayhome-ai.com | ✅ |
| 7 | GitHub org | `Stayhome-AI` | repo remote (`github.com/Stayhome-AI/...`) | WIF attribute condition + cicd.yaml | `Stayhome-AI` | ✅ |
| 8 | GitHub repo | `cloud-foundation-fabric` (this fork, monorepo) | `git remote -v` | `cicd.yaml` repository.name = `Stayhome-AI/cloud-foundation-fabric` | `Stayhome-AI/cloud-foundation-fabric` | ✅ |
| 9 | Temp/default gcloud project | project id, billing-linked | **"My First Project"** (auto-created) — throwaway; delete after first apply | `gcloud config set project` before first apply | My First Project — heroic-bird-502819-q1 | ✅ |
| 10 | Local output path | e.g. `~/fast-config/stayhome` | your choice | `defaults.yaml` output_files.local_path | `~/fast-config/stayhome` | ✅ |

**Row 9 runbook** — this project isn't Terraform-managed (it's not in any YAML factory; `iac-0`,
the real automation project, doesn't exist until after first apply), so this is a manual step,
every time you need to redo a first apply from scratch (README §"Default project"):

```bash
gcloud config set project heroic-bird-502819-q1
gcloud services enable \
  bigquery.googleapis.com \
  cloudbilling.googleapis.com \
  cloudresourcemanager.googleapis.com \
  essentialcontacts.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  orgpolicy.googleapis.com \
  serviceusage.googleapis.com
```

Prerequisites: the project must already exist and be billing-linked (created via Console, not
CLI, so a unique ID gets picked — see README), and you must be authenticated as an identity with
rights on it. After first apply succeeds, reset the `gcloud` default to `iac-0` and delete this
temp project.

**ADC quota project** — `terraform plan` failed on org-policy reads/writes (`iam.*`,
`storage.uniformBucketLevelAccess`, etc.) with a 403 `SERVICE_DISABLED` on `orgpolicy.googleapis.com`
against consumer project `764086051850`. That's not a real project — it's gcloud's own SDK OAuth
client project, which credentials fall back to when no quota project is in effect.

`gcloud auth application-default set-quota-project <project>` alone did **not** fix it — that only
sets quota project for gcloud/client-library calls. Terraform's Google provider needs its own,
separate config to send the `X-Goog-User-Project` header; set these env vars in the shell you run
`terraform` from (not committed anywhere — this is a per-shell/per-machine thing, redo after every
fresh terminal session doing a from-scratch bootstrap):

```bash
export USER_PROJECT_OVERRIDE=true
export GOOGLE_BILLING_PROJECT=heroic-bird-502819-q1
```

(use whatever the current temp/default project is at the time — see row 9 above; swap to `iac-0`'s
project id once it exists and this stage is re-applied post-migration)

---

## 🗺️ Stage map — plan (classic FAST) → repo (v57)

The implementation plan's phase→stage names are outdated. Actual mapping:

| Plan phase | v57 stage in repo | Notes |
|---|---|---|
| 1 (0-bootstrap) + 2 (1-resman) | **`0-org-setup`** | merged: automation projects, WIF, folders, org policies, org IAM, log sinks, tags, custom roles |
| 3 (2-security → VPC-SC) | **`1-vpcsc`** | VPC-SC split out, runs *earlier* (org-wide single perimeter, dry-run) |
| 3 (2-security → KMS) | **`2-security`** | KMS keyrings / CAS, factory-driven |
| 4 (2-networking) | **`2-networking`** | Shared VPCs, factory-driven |
| 5 (2-project-factory) | **`2-project-factory`** | workload projects (roots under Teams/env folders) |
| — | `3-secops-dev` | Google SecOps/Chronicle — **not in design; ignore for Phase A** |

---

## ✅ Stage progress

- [x] **Phase 0** — manual bootstrap (Cloud Identity, org, break-glass, billing, groups, Entra SSO/SCIM, GitHub org)
- [ ] **0-org-setup** — org config + folders + policies + logging + CI/CD wiring  ← *applied successfully; state migration + CI/CD proof-out remain*
- [ ] **1-vpcsc** — org-wide perimeter, dry-run
- [ ] **2-security** — KMS / CAS
- [ ] **2-networking** — Shared VPCs, NAT, DNS, firewall
- [ ] **2-project-factory** — first dev/staging/prod workload projects
- [ ] Phase B (triggered) — see design §10

---

## 🧩 Stage-0 work checklist (this branch)

- [x] `defaults.yaml` — org/billing/customer IDs, prefix, domain, admin group, locations
- [x] Add top-level `Sandbox` folder (relaxed policy + hard budget cap) — `folders/sandbox/.config.yaml`, mirrors the `Teams` pattern (project-factory-managed)
- [x] Cherry-pick hardened observability alerts (10) into classic dataset — `observability/iac-0/*.yaml`, all feed off `log_buckets:log-0/audit-logs` (already exists); no notification channel wired, alerts are metric-only until one is added (breadcrumb below)
- [x] Cherry-pick born-with-it custom constraints — Cloud SQL PITR + SSL (org-wide, free) and HA (production-tag-scoped, doubles cost) in `custom-constraints/sql.yaml` + `org-policies/sql.yaml`; GKE private endpoint (org-wide) in `custom-constraints/gke.yaml` + `org-policies/gke.yaml`. **AR CMEK and GKE confidential nodes skipped** — not in the design doc, not available as pre-built hardened constraints (AR) or cost/complexity-significant enough to need an explicit decision (confidential nodes); see breadcrumbs below
- [x] Widen Data Access logs org-wide + set 13-month audit-log retention + US multi-region log buckets — `organization/.config.yaml` `data_access_logs.allServices` (ADMIN_READ/DATA_READ/DATA_WRITE) + `logging.storage_location: $locations:us_multi`; `log-0.yaml` audit-logs/iam buckets now `location: $locations:us_multi`, `retention: 395`. New `us_multi: US` location added to `defaults.yaml` context
- [x] CI/CD: add `workload_identity_pools` to `iac-0.yaml`, set GitHub org/repo, point `cicd.yaml` at this fork — done; **two apply-time gotchas, see breadcrumbs below**
- [x] Reconcile org-policy set vs design §7 — fixed a real conflict: `compute.restrictLoadBalancerCreationForTypes` only allowed `in:INTERNAL`, which would have blocked the global external HTTPS LB the device fleet depends on (design §5/§6) — now allows `in:INTERNAL` + `GLOBAL_EXTERNAL_MANAGED_HTTP_HTTPS` (verified against Google's LB org-policy-constraints doc; bare `EXTERNAL_MANAGED` is **not** a valid value, and the broader `in:EXTERNAL` group was deliberately not used — no other external LB type is part of the design). Also added `compute.requireShieldedVm` (was missing) and restricted `gcp.resourceLocations` to `in:us-locations` (was unrestricted `allow: all`, verified against Google's docs). `iam.allowedPolicyMemberDomains` was already correctly customer_id-scoped
- [x] Add `staging` environment (partner agreement, 2026-07-22) — `organization/tags/environment.yaml` new `staging` tag value (mirrors `development`/`production` IAM grants exactly); `folders/networking/staging/.config.yaml` and `folders/security/staging/.config.yaml` new subfolders (mirror the `dev`/`prod` siblings' pattern, including `security/staging`'s explicit `parent:` line that `networking/staging` doesn't need). Re-planned clean (0 destroy) before this was added; re-plan again to confirm the 3 new folder/tag resources add cleanly
- [x] First apply cycle (local, as org admin) — succeeded 2026-07-22; subsequent `terraform plan` shows no changes, state matches reality exactly
- [ ] Remove `org_policies_imports` from `0-org-setup.auto.tfvars` — import is one-time-use, README says to clear it post-apply (gitignored file, not part of the PR either way)
- [x] Migrate state to the GCS backend — `0-org-setup-providers.tf` symlinked from
  `~/fast-config/stayhome/providers/` (gitignored, matches `fast/**/[0-9]*providers.tf`),
  `terraform init` migrated local state into `gs://shai-prod-iac-core-1-iac-org-state`, confirmed
  with a clean `terraform plan` (no changes) reading through the new backend + `iac-org-rw` SA
  impersonation. Note: `../fast-links.sh` has a broken shebang on macOS (`#!/bin/env bash` —
  `/bin/env` doesn't exist, needs `/usr/bin/env`); invoke it as `bash ../fast-links.sh <path>`
  instead. Its tfvars-linking suggestion doesn't apply to this stage specifically — that's for
  linking a *manually-copied* tfvars file into the shared output path, not the auto-generated
  `tfvars/*.auto.tfvars.json` output files (those are for *downstream* stages to consume, e.g.
  `1-vpcsc`, `2-networking` — not something `0-org-setup` itself needs).
- [ ] Wire and prove CI/CD: set `factories_config.paths.cicd_workflows = "cicd.yaml"` in tfvars, generate the GitHub Actions workflow, **fix `branches: [main]` → `branches: [master]`** in the generated file (breadcrumb below) before committing, then prove a PR-driven plan/apply via WIF end to end ← **next action**

---

## 🍞 Breadcrumbs for later stages / follow-ups

- **`USER_PROJECT_OVERRIDE`/`GOOGLE_BILLING_PROJECT` become actively harmful once the real
  provider config is linked.** These were set early on to fix ADC's missing-quota-project error
  (pointing quota at the temp project `heroic-bird-502819-q1`) while running with direct user
  credentials. After state migration linked `0-org-setup-providers.tf` (which impersonates
  `iac-org-rw@shai-prod-iac-core-1...`), the same env vars caused `plan` to fail with
  `USER_PROJECT_DENIED` — the impersonated SA has no rights to use the old temp project for quota,
  and doesn't need to; the provider's own service-account identity handles that now. Fix: `unset
  GOOGLE_BILLING_PROJECT USER_PROJECT_OVERRIDE` in any shell that still has them from earlier in
  this saga. (Separately: my own verification `plan` right after migration succeeded because my
  tool's shell never had these vars set — only the user's actual terminal carried them forward
  from the original ADC fix. Worth remembering that my Bash tool and a user's own terminal are
  different shell sessions with independently-set env state.)
- **Boolean org policies with a conditional rule need an explicit unconditional fallback rule.**
  `custom.cloudsqlRequireHighAvailability` (production-tag-scoped, `org-policies/sql.yaml`) failed
  apply with `A boolean policy must always include one unconditional rule` — it only had the
  production-conditional rule, nothing covering the non-production case. Unlike list constraints
  (e.g. `iam.allowedPolicyMemberDomains`, which satisfies this by having two conditions that
  jointly cover every case), a boolean (`enforce: true/false`) constraint must have at least one
  rule with **no** `condition:` at all, as the fallback. Fixed by adding `- enforce: false` as a
  second, unconditional rule. Applies to any future tag-conditional boolean constraint — the
  `custom.gkeRequirePrivateEndpoint`/PITR/SSL constraints are unconditional org-wide already so
  this didn't affect them, but the next one scoped to a tag will need the same fallback rule.
- **`bucket_name: $log_buckets:log-0/audit-logs` can't resolve — real cause is a missing
  cross-project context merge in `project-factory`, not a YAML prefix issue.** Full root-cause
  trace, the dead-end first fix attempt, our hardcoded-resource-name workaround, the follow-on
  ordering race it caused (and how that was resolved with a one-time targeted apply), and a
  proposed upstream fix are all written up in
  [upstream-bug-log-buckets-cross-project-ctx.md](upstream-bug-log-buckets-cross-project-ctx.md) —
  intended as the basis for an issue/PR against `GoogleCloudPlatform/cloud-foundation-fabric`
  eventually. Short version: `log-0` and `iac-0` are sibling projects created in the same
  project-factory pass; `project-factory` cross-merges sibling projects' tags into context
  (`ctx_tag_keys`/`ctx_tag_values`) but has no equivalent for `log_buckets`, so a project can never
  resolve another sibling project's bucket via the `$log_buckets:` context mechanism — regardless
  of prefix formatting. Fixed locally by hardcoding the fully-qualified resource name
  (`bucket_name: projects/shai-prod-audit-logs-0/locations/us/buckets/audit-logs`) in all 10
  cherry-picked alert files. If more observability alerts get cherry-picked later that reference
  another project's bucket, expect the same gap. **Follow-up finding**: a `google_logging_metric`
  can only be created in the project that *owns* the bucket it reads from (a distinct GCP API
  rule, hit as `Metric must be created in the project that owns the bucket` — 400) — so these
  alerts had to move entirely, from `observability/iac-0/` to a new `observability/log-0/`, with
  `factories_config.observability: observability/log-0` and `monitoring.googleapis.com` added to
  `log-0.yaml`. This is also why `hardened` wired its own samples to `log-0` in the first place
  (not a mistake, just typo'd — see the upstream doc).
- **ADC reauth expiry (`invalid_grant "reauth related error (invalid_rapt)"`).** Every API call in
  a `plan`/`apply` failed the same way after the session sat idle a while — this is Google
  Workspace/Cloud Identity's periodic reauth requirement for sensitive API calls (IAM, org policy,
  security settings — most of what this stage does), not a permissions or config issue. Fix:
  `gcloud auth application-default login`, then retry. `USER_PROJECT_OVERRIDE`/
  `GOOGLE_BILLING_PROJECT` are shell env vars, not part of the ADC file, so they survive a re-login
  in the same shell — only re-set them if starting a fresh terminal too. Expect this to recur
  across later stages/sessions.
- **Tainted-resource trap: a partial `google_project` create → destroy+recreate → soft-delete
  collision.** First apply's billing-quota failure on `iac-0` happened mid-create (project created,
  then billing-link sub-call failed) — Terraform marked `google_project.project[0]` **tainted**.
  A tainted resource is *always* destroyed and recreated on the next apply, never updated in
  place, regardless of whether the changed field (`billing_account`) would normally be a safe
  in-place update. The destroy soft-deleted `shai-prod-iac-core-0` (GCP reserves deleted project
  IDs for ~30 days before purging), so the immediate recreate 409'd on the still-reserved ID.
  **Lesson: after any apply that errors mid-resource, always run `terraform plan` again and read
  it before re-applying** — it would have shown `must be replaced`, catching this before it
  destroyed anything. Recovered by renaming `iac-0.yaml`'s `name:` from `prod-iac-core-0` →
  `prod-iac-core-1` (new derived project_id, sidesteps the reserved-id collision entirely — nothing
  external referenced the old id yet, this early in bootstrap). The old `shai-prod-iac-core-0` id
  is now permanently unusable but otherwise harmless; can be left to auto-purge in ~30 days.
- **Billing account project-linking quota.** First apply failed linking `shai-prod-iac-core-0` to
  billing account `01425B-C8ADCC-9C38B7`: `Cloud billing quota exceeded` (400, `QuotaFailure`).
  This is a Google-side daily cap on how many *new* projects can be linked to a billing account,
  unrelated to spend limits or anything in this dataset — hit because the temp project + `iac-0` +
  `log-0` + `billing-0` all tried to link the same day. Not one-and-done: `2-networking` links 3
  more (`net-dev-0`/`net-staging-0`/`net-prod-0`), `2-security` at least 1, and every
  `2-project-factory` workload project after that — expect to hit this again. Options: wait ~24h
  for the window to roll over, or request a permanent increase now at
  https://support.google.com/code/contact/billing_quota_increase (worth doing proactively given
  how many more projects are coming). State is local pre-migration, so re-`apply` after either
  fix resumes cleanly — already-linked projects aren't retried.
- **Staging environment (added 2026-07-22) — downstream implications for later stages.** This
  stage only adds the `staging` tag value + `networking/staging` + `security/staging` folders.
  Still to do when those stages are reached: `2-networking` needs a third Shared VPC host
  (`net-staging-0`, CIDR `10.64/12` staging-r1, already reserved in design §5); `2-project-factory`
  needs `staging` in its environment map alongside `dev`/`prod`; `2-security` KMS keyrings follow
  whatever per-env pattern is used for dev/prod. HA custom constraint
  (`custom.cloudsqlRequireHighAvailability`) stays scoped to the `production` tag only — staging
  Cloud SQL is assumed non-HA, same cost posture as dev, unless told otherwise.
- **Pre-existing org policies + `org_policies_imports`.** `gcloud org-policies list --organization
  15122406886` (2026-07-22) showed 7 policies already set on the org (Google's new-org defaults):
  `iam.allowedPolicyMemberDomains`, `storage.uniformBucketLevelAccess`,
  `essentialcontacts.managed.allowedContactDomains`, `iam.managed.disableServiceAccountKeyCreation`,
  `compute.managed.restrictProtocolForwardingCreationForTypes`,
  `iam.automaticIamGrantsForDefaultServiceAccounts`, `iam.disableServiceAccountKeyUpload`. Only 4
  are exact-name matches against the classic dataset — those went into
  `0-org-setup.auto.tfvars`'s `org_policies_imports` (gitignored, local only). The other 3 use
  Google's newer `.managed.` constraint names while the dataset still declares the legacy names
  (`org-policies/essentialcontacts.yaml`, `compute.yaml:123`, `iam.yaml:59`) — **do not** add those
  3 to `org_policies_imports`: `imports.tf`'s import block targets
  `google_org_policy_policy.default[each.key]`, which only exists for keys the dataset declares, so
  importing a `.managed.` name that the dataset never uses breaks `terraform plan`. Watch the plan
  output for those 3 legacy-named constraints specifically — unclear whether GCP still accepts
  creating a policy under the legacy name cleanly alongside the pre-existing managed one.
- **`$locations:us_multi` (`defaults.yaml`) resolves to lowercase `us` — a Cloud Logging bucket
  location, not a GCS bucket location.** Cloud Logging multi-regions are `us`/`eu`/`global`
  (lowercase); GCS multi-regions are `US`/`EU`/`ASIA` (uppercase) — different conventions, easy to
  cross-wire. This context value is only wired to log buckets (`log-0.yaml`,
  `organization/.config.yaml` `logging.storage_location`). If a later stage needs a multi-region
  **GCS** bucket (e.g. backups, design §7/§12 Q10), add a separate context value with the
  uppercase GCS form — don't reuse this one.
- **CI/CD workflow trigger branch is hardcoded to `main`** in FAST's generated template (`assets/workflow-github.yaml:19-20`), not templated from `cicd.yaml`'s `apply_branches`. This repo's default branch is `master`. After first apply generates the workflow file, **edit `branches: [main]` → `branches: [master]`** before committing to `.github/workflows/` — otherwise CI silently never triggers.
- **`cicd.yaml` isn't read unless explicitly wired.** `factories_config.paths.cicd_workflows` has no default in the stage's variables (unlike other factory paths) — it must be set to `"cicd.yaml"` in the tfvars used at apply time (local/gitignored, part of the first-apply step) or the file is silently ignored.
- **AR CMEK** — design doesn't actually call for it (only the primary Cloud SQL DB, design §2/§7); no such org-policy or custom constraint exists in the hardened dataset either. If Artifact Registry repos later need CMEK, it's a per-repo `kms_key_name` set at creation in whichever stage creates them (born-with-it, same pattern as Cloud SQL) — likely `2-project-factory`.
- **GKE confidential nodes** — hardened dataset has `custom.gkeRequireConfidentialNodes`, not cherry-picked. Design only specifies "private cluster" (§5), not confidential computing, which adds real cost/machine-type constraints for GKE Autopilot. Revisit at `2-project-factory`/`2-networking` if a concrete need appears.
- **`data-classification` labels/tags** (design §2) — no tag taxonomy for this exists yet in `organization/tags/`. Design says this should be "applied from the factory," i.e. belongs to `2-project-factory`, not this stage.
- **Log-based alerts have no notification channel.** The 10 cherry-picked alerts (and pre-existing `impersonation.yaml`) create metrics + alert policies but don't page anyone — `notification_channels: {}` everywhere. Fine for Phase A (SCC Standard triage is manual anyway per design §7), but worth an email channel before these matter operationally.

---

## ❓ Open questions carried forward

- **Billing account type** (input #5) — gates billing IAM factory shape.
- **Office/VPN egress IPs** — needed for `1-vpcsc` access levels (design §5 / §7). Gather before stage 1.
- **DNS** — where is `stayhome-ai.com` hosted; which subdomains delegate to Cloud DNS (design §12 Q8). Needed for `2-networking`.
