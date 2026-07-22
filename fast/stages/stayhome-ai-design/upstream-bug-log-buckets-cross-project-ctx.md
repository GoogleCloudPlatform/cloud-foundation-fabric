# Upstream bug: `log_buckets` has no cross-project context merge in `project-factory`

**Status:** confirmed, worked around locally; not yet filed upstream
**Found:** 2026-07-22, while bootstrapping `0-org-setup` for a fresh org
**Repo/commit at time of discovery:** `Stayhome-AI/cloud-foundation-fabric` (fork of
`GoogleCloudPlatform/cloud-foundation-fabric`), commit `11c1d248826f06cbec3fff54fc7094da405a5322`,
FAST release `v57.0.0`

---

## TL;DR

`project-factory` lets one project's YAML reference **another sibling project's tags** via
context (`ctx_tag_keys` / `ctx_tag_values`, cross-merged across every project in the same
factory pass). It does **not** do the equivalent for **log buckets** — so a project's
observability alerts (`logging_metrics.bucket_name`) can't reference a log bucket that lives in a
different project created in the same `apply`, even though the YAML syntax (`$log_buckets:proj/bucket`)
looks identical to the working tag pattern and gives no indication it won't resolve. It fails
silently (falls through to a broken literal string) rather than erroring at plan time.

This also affects the `hardened` dataset's own shipped observability sample files, which use
exactly this cross-project pattern (alerts in `log-0`'s observability factory referencing
`log-0`'s own bucket — see "secondary bug" below for why even that self-reference is miswired).

---

## How this surfaced

Cherry-picked `hardened`'s 10 observability alert YAML files (log-based metrics + alert policies)
into our `classic` dataset, wired to `iac-0`'s project-level observability factory. Each alert's
`logging_metrics.<name>.bucket_name` field pointed at `log-0`'s audit-logs bucket:

```yaml
# as shipped in fast/stages/0-org-setup/datasets/hardened/observability/*.yaml
bucket_name: $log_buckets:log-0/audit-logs
```

First `apply` attempt failed:

```
Error: Error creating Metric: googleapi: Error 400: Received unexpected value parsing name
"$log_buckets:log-0/audit-logs": audit-logs. Expected the form
projects/[PROJECT_ID]/locations/[ID]/buckets/[ID]
```

The literal, unresolved string reached the Cloud Logging API — meaning whatever mechanism is
supposed to resolve `$log_buckets:log-0/audit-logs` into a real resource name never fired.

## Root cause, traced through the actual module code

**1. The lookup itself** — `modules/project/logging-metrics.tf:72-76`:

```hcl
bucket_name = try(
  # first try to check the context
  local.ctx.log_buckets[each.value.bucket_name],
  # if nothing else, use the provided channel as is
  each.value.bucket_name
)
```

A direct map lookup against `local.ctx.log_buckets`, keyed by whatever `each.value.bucket_name`
literally is (as read from the observability YAML). If the lookup fails, `try()` silently falls
back to the raw string — **no error, no warning**, just a bad value that only surfaces once it
hits the API.

**2. What keys `local.ctx.log_buckets` actually has** — `modules/project/main.tf:36-40`:

```hcl
ctx = {
  for k, v in var.context : k => {
    for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
  } if !endswith(k, "_vars")
}
# ctx_p = "$"
```

Every context category gets its keys re-prefixed with `$category:` when `local.ctx` is built from
`var.context`. So `local.ctx.log_buckets` keys really are of the form
`"$log_buckets:log-0/audit-logs"` — meaning **the original hardened YAML's prefixed form was the
correct format** for the lookup key. (We initially "fixed" this by stripping the prefix, assumed
wrongly that observability files skipped this re-prefixing step. Same error persisted with the
unprefixed string — proof that theory was wrong, and the real problem is one level deeper.)

**3. The actual gap** — `modules/project-factory/projects.tf:52-70` builds cross-project context
for **tags** explicitly:

```hcl
ctx_tag_keys = merge(local.ctx.tag_keys, {
  for k, v in merge({}, [
    for pk, pv in local.projects_input : {
      for tk, tv in module.projects[pk].tag_keys :
      "${pk}/${tk}" => tv.id
    }
  ]...) : k => v
})
ctx_tag_values = merge(local.ctx.tag_values, { /* same pattern */ })
```

This walks every project in the current factory pass (`local.projects_input`), pulls each one's
own `tag_keys`/`tag_values` module outputs, and re-keys them as `"<project_key>/<tag_key>"` —
exactly the shape `$tag_values:log-0/sometag` would need to resolve. **There is no equivalent
`ctx_log_buckets` local anywhere in this file.** The `context` passed into each `module "projects"`
instance (line 134, `context = merge(local.ctx, {...})`) only extends `condition_vars` and
`folder_ids` — `log_buckets` passes through untouched, still just whatever came in via
`var.context` from the parent stage, which never includes buckets created by sibling projects in
the *same* factory pass.

**4. Where the key format actually comes from** —
`modules/project-factory/projects-log-buckets.tf:39-43`:

```hcl
module "log-buckets" {
  for_each = {
    for k in local.projects_log_buckets : "${k.project_key}/${k.name}" => k
  }
  ...
}
```

Confirms the intended bare key shape is `"<project_key>/<bucket_name>"` (e.g. `"log-0/audit-logs"`)
— matching what the `$log_buckets:` YAML references assume. The shape is right; the plumbing to
get sibling-project bucket ids into `ctx_log_buckets` (analogous to `ctx_tag_keys`) is just
missing.

**Net effect:** `log-0` and `iac-0` are sibling projects created by the same `module "projects"`
`for_each` in `project-factory`. `iac-0`'s observability alerts reference `log-0`'s bucket. Because
there's no `ctx_log_buckets` cross-merge, that reference can never resolve — regardless of prefix
formatting — since the data genuinely isn't present in the context `iac-0`'s module instance
receives. This is a plumbing gap in `project-factory`, not a dataset authoring mistake.

## Why `hardened` wires these alerts to `log-0`, and a path typo that breaks it anyway

`hardened`'s choice to wire these alerts to `log-0` (not `iac-0`) wasn't incidental — it's
**required**. A `google_logging_metric` can only be created in the project that owns the bucket it
reads from (confirmed by a distinct API error hit later in this saga: `Error creating Metric:
googleapi: Error 400: Metric must be created in the project that owns the bucket`). So even a
same-project self-reference (which sidesteps the missing `ctx_log_buckets` merge above) only works
if the alerts' observability factory is wired to the *same* project that owns the bucket — here,
`log-0`, not `iac-0`. We initially placed these files under `iac-0`'s observability factory
(mirroring the pre-existing `impersonation.yaml`, which doesn't reference any bucket and so never
surfaced this), hit the "wrong project" error, and had to relocate all 10 files to a new
`observability/log-0/` directory plus add `factories_config.observability: observability/log-0` to
`log-0.yaml` (along with `monitoring.googleapis.com` to its `services`, needed for the alert
policies).

That said, `hardened`'s own path string is still typo'd —
`datasets/hardened/projects/core/log-0.yaml:68`:

```yaml
factories_config:
  observability: organization/observability/
```

The actual files live at `datasets/hardened/observability/*.yaml` — there is no
`datasets/hardened/organization/observability/` directory. The path is relative to the dataset
root, so this reference doesn't resolve to where the files actually are — meaning `hardened`'s own
observability samples have likely never been exercised through a real apply even in the "right"
project. Worth fixing alongside the `ctx_log_buckets` gap if filing upstream.

## Our workaround (local only, not a real fix)

Hardcoded the fully-qualified Cloud Logging bucket resource name directly, bypassing the context
lookup entirely:

```yaml
bucket_name: projects/shai-prod-audit-logs-0/locations/us/buckets/audit-logs
```

Safe for us because `log-0`'s project id and the bucket's location/name are all fixed, known
values in our dataset. This is not portable — it hardcodes a specific project id into what's
otherwise meant to be a reusable, context-driven config file.

This introduced a second, smaller issue: since the hardcoded string carries no Terraform
dependency information, nothing tells Terraform the metric must wait for the bucket to exist.
First `apply` after the fix hit a race (`Bucket audit-logs in location us does not exist` — 404,
progress from the earlier 400, but still failing) because the metric and the bucket happened to
get scheduled in the same wave with the metric losing. Resolved with a one-time targeted apply
(`terraform apply -target='module.factory.module.log-buckets["log-0/audit-logs"]' ...`) to force
bucket creation first; a real Terraform-level `depends_on` isn't reachable from YAML-factory config
and would require patching vendored module code (out of scope for a one-time bootstrap hiccup —
see main thread discussion for why we didn't go that route). This is a one-time hazard: once the
bucket exists, every future `apply` resolves cleanly with no race, since there's nothing left to
create.

## Proposed upstream fix

In `modules/project-factory/projects.tf`, add a `ctx_log_buckets` local mirroring `ctx_tag_keys`/
`ctx_tag_values` (~line 55), merging each project's own `log_buckets` output
(`module.projects[pk].log_buckets`, re-keyed `"<project_key>/<bucket_key>"`) into
`local.ctx.log_buckets`, then include it in the `context = merge(...)` block passed to
`module "projects"` (~line 134), the same way `folder_ids` already is. Separately, fix
`hardened`'s `log-0.yaml` observability path to point at wherever the files actually live.

## Next steps

- [ ] Confirm the fix works as described against a throwaway test org (would strengthen a PR)
- [ ] Search existing issues on `GoogleCloudPlatform/cloud-foundation-fabric` for prior reports of this
- [ ] File an issue describing the gap (this doc is most of the writeup already)
- [ ] If time allows, open a PR: `ctx_log_buckets` merge in `project-factory` + the `hardened`
      path fix
