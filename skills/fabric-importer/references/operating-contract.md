# fabric-importer — operating contract

Rules for any agent or human operating this skill.

## 1. Trust boundary

The skill is intentionally lean: the model performs discovery-to-Terraform
mapping itself, and correctness comes from un-gameable verification, not
from deterministic codegen. That only holds if the boundary is respected:

| Layer | Contents | Who may change it |
|---|---|---|
| Frozen scripts | `scripts/inventory.py`, `scripts/coverage.py`, `scripts/verify_plan.py`, `scripts/benign-drift.yaml`, `scripts/manifest_init.py`, `scripts/integrity.py` | Humans, via code review only. The model may run them, never edit them. |
| Human-owned run files | `import-manifest.yaml`, `waivers.yaml` | Humans. The model drafts/proposes; a human commits. |
| Model workspace | `tf/`, `coverage-map.yaml`, reports, worklists | The model — with immutable-address discipline (§4). |

A converged verdict is only meaningful if the gates and their rulesets
were not touched by the same actor whose output they verify.

Both gates stamp runtime provenance into their output, covering every
verification script. To check a recorded verdict, run `python3
scripts/integrity.py` from a clean checkout of the same commit and
compare; `--verbose` identifies which file differs. This is evidence,
not prevention — an actor editing a gate could edit the stamp — but it
removes the silent case, and any stored gate output can be checked after
the fact.

The script provenance alone does not prove which *inputs* a gate judged,
so both gates also stamp every input they read — resolved path and
SHA256 — on the line after the digest: the plan JSON (or stdin), the
rules file actually loaded, the inventory, the coverage map, the waiver
ledger, and the set of `*.tf` files scanned. A non-default `--rules`
file additionally prints a loud warning that the verdict is NOT judged
by the frozen ruleset. A recorded verdict is therefore attributable to
exact inputs, not just to a tool build.

The gates also fail closed on degenerate inputs: a plan without
`format_version` and `resource_changes` (state JSON, `{}`), a plan with
zero resource changes without `--allow-empty-plan`, and an empty
inventory without `--allow-empty-inventory` all exit non-zero. An empty
verdict is never evidence of convergence.

**Which decisions need a human.** The pattern behind this table is that
every human-owned artifact either narrows what the gates check or is
irreversible. Scope narrows the denominator; a waiver removes an entry
from it; a benign rule removes an entry from the residual set; an apply
cannot be undone. Everything else — module choice, file layout, instance
keys, raw-vs-module calls — is falsifiable by the plan and can be
model-owned. Use that test when something new appears: *does this shrink
what is checked, or is it irreversible?* If yes, a human decides.

Waivers therefore carry an optional `signed_by` field. It is reported by
default and enforced with `coverage.py --require-signed-waivers`.
Enforcement is opt-in on purpose: demanding attribution where no human is
present produces invented signatures, and a forged name defeats the audit
it was meant to support.

## 2. Absolute invariants

1. **NEVER run `terraform apply`** — against any environment, for any
   reason. The generated authoritative IAM bindings make an apply
   equivalent to overwriting live org IAM with a stale snapshot.
2. **Read-only against GCP APIs.** Allowed: `list`, `describe`,
   `get-iam-policy`, `search`, asset inventory reads, plus
   `terraform init/validate/plan/show`. Never
   `set/add/remove/update/create/delete`. Prefer a dedicated read-only
   identity so the rule is enforced by IAM, not prose.
3. **Never synthesize Terraform state.** Plan JSON assertions
   (`verify_plan.py`) are the only accepted convergence evidence.
4. **Org-confidential output.** Workspace contents and anything derived
   from a real org (IDs, domains, principals, resource names, counts)
   never enter a repository or a shareable document unsanitized.
5. **Never rationalize residual diffs.** A diff believed benign becomes a
   *proposed* `benign-drift.yaml` entry with evidence, reviewed by a
   human. Until accepted, the run is red.

## 3. Convergence definition

A run is converged when, for the manifest-declared scope:

1. `coverage.py` exits 0 — every in-scope inventory key is mapped to
   emitted import blocks or human-waived; and
2. `verify_plan.py` exits 0 — every planned change is a clean import,
   no-op, or matches a reviewed benign-drift rule.

Both are required. The manifest bounds the claim: convergence says
nothing about undeclared types/levels, and the run report must say so
plainly.

## 4. Incremental discipline

- Existing Terraform addresses and `coverage-map.yaml` entries are
  immutable; re-runs extend the workspace for worklist entries only.
- Genuine re-keying (renames, refactors) requires `moved {}` blocks and a
  prominent note in the run report.
- Manifest changes only ever widen or narrow scope; they never license
  rewriting existing mappings.

## 5. Toolchain

Terraform >= 1.5; google + google-beta providers `>= 7.40, < 8`; Fabric
module refs pinned to released tags (surface unreleased-feature
trade-offs to the user instead of silently pinning SHAs). Provider or
Fabric ref bumps invalidate `benign-drift.yaml` verification stamps and
the cookbook's address table — re-verify before trusting a verdict.
