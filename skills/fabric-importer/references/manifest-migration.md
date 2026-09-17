# Manifest migration — from the retired grammar to scopes-only

The import-manifest grammar changed once, and this file is the record of
it. If `inventory.py` refused your manifest with *"manifest declares
retired top-level key(s)"*, you are holding a manifest written for the
old grammar; this page is the complete migration path.

## What changed, and why

**Old grammar (retired).** A manifest declared WHERE to look and WHAT to
collect in two separate places: a singular `scope:` (or a `scopes:`
list) for the subtrees, and one manifest-global `types:` list shared by
every scope. The only per-scope discrimination was the `levels` axis
(organization / folder / project / unknown): a type declared anywhere
was swept in every scope whose levels intersected its own.

**New grammar (current).** `scopes:` is the only form, and **every scope
carries its own `types:` list**. There is no top-level `types:` and no
singular `scope:`. What a scope collects is exactly what is written on
it.

The motivation is per-scope type declarations — different resource
types under different subtrees (org governance at org/folder level, the
connectivity stack under the networking folder, project IAM only in
named workload projects), which the global list could not express
without waiving every out-of-domain asset by hand. Making the new form
the ONLY form, rather than an option next to the old one, makes three
whole classes of silent-denominator failure unrepresentable instead of
merely validated: there is no inheritance to half-apply, no global list
to go stale behind the scopes, and no mixed manifest whose meaning
depends on which scope the reviewer happened to read.

The tool refuses the old grammar rather than silently accepting half of
it, because a half-read manifest would change what the denominator
means — the exact failure the gates exist to prevent.

## Migration: singular `scope:`

Wrap the scope as a one-element `scopes:` list and move the `types:`
list inside it (indent by four spaces). Nothing else changes — same
types, same levels, same include/exclude, same collected denominator.

```yaml
# OLD (refused)                     # NEW
scope:                              scopes:
  root: organizations/123            - root: organizations/123
  include:                             include:
    - folders/456                        - folders/456
types:                                 types:
  - type: org-policy                     - type: org-policy
    levels: [organization]                 levels: [organization]
  - type: iam                            - type: iam
    levels: [organization, folder]         levels: [organization, folder]
```

## Migration: `scopes:` list with a shared top-level `types:`

Copy the top-level list into EVERY scope, then (optionally, later)
narrow each copy. The unnarrowed copy is semantically identical to the
old manifest: the collect-time intersection of a type's `levels` with
each scope's `levels` is unchanged, so the same assets enter the
denominator.

```yaml
# OLD (refused)
scopes:
  - name: org-foundation
    root: organizations/123
    levels: [organization, folder]
  - name: stage-projects
    root: organizations/123
    levels: [project]
    include: [projects/111111111111]
types:
  - type: iam
    levels: [organization, folder, project]
  - type: cloudresourcemanager.googleapis.com/Folder
    levels: [organization, folder]

# NEW — verbatim copy first, narrow later
scopes:
  - name: org-foundation
    root: organizations/123
    levels: [organization, folder]
    types:
      - type: iam
        levels: [organization, folder, project]
      - type: cloudresourcemanager.googleapis.com/Folder
        levels: [organization, folder]
  - name: stage-projects
    root: organizations/123
    levels: [project]
    include: [projects/111111111111]
    types:
      - type: iam
        levels: [organization, folder, project]
```

Note the second scope: `cloudresourcemanager.googleapis.com/Folder`
was NOT copied into it. A per-scope entry whose `levels` cannot
intersect its scope's `levels` is refused as a dead declaration
(`[organization, folder] ∩ [project] = ∅`), so a verbatim copy is only
valid where the type could actually fire. Under the old grammar that
entry was silently inactive for the scope; now it is an error — drop
it from the scopes it cannot fire in. Entries whose `levels` include
`unknown` are exempt and may be copied everywhere.

If YAML repetition bothers you, anchors keep shared lists in one
place:

```yaml
scopes:
  - name: teams
    root: organizations/123
    include: [folders/111]
    types: &folder-types
      - type: cloudresourcemanager.googleapis.com/Folder
        levels: [organization, folder]
  - name: rest
    root: organizations/123
    exclude: [folders/111]
    types: *folder-types
```

## Key mappings, old → new

| Old | New |
|---|---|
| `scope:` (singular) | `scopes:` with one entry |
| top-level `types:` | each scope's own `types:` (copy, then narrow) |
| top-level `emission:` (manifest-wide default) | `scopes[].emission` on each scope that wants a non-default style; an omitted family falls back to the built-in default (`per-instance`; `additive` for `iam`), not to another scope |
| `enumerate:` block, declared once | declared in the `types:` list of every scope that needs the sweep — per-scope lists never inherit, so the block is repeated per scope (a different scope may even carry a different block for the same type) |
| `iam: true` leaf opt-in, declared once | per scope, like everything else on a type entry: a scope that omits it collects the resource without its leaf IAM |
| type silently inactive in a scope (empty levels intersection) | refused as a dead declaration (drop the entry from that scope; `unknown` entries exempt) |

## What did NOT change

- The type entry schema: `type`, `levels`, `iam`, `enumerate` are
  unchanged, including all `enumerate:` guard rails.
- Scope fields: `name`, `root`, `include`, `exclude`, `levels` are
  unchanged, including numeric-id resolution for include/exclude.
- Collect-time semantics for a faithful copy: same sweeps, same
  intersection rule, same deduplicated denominator. A migrated
  manifest that copies the old list into every (compatible) scope
  yields the same `assets` — diffing old and new `inventory.json`
  asset keys is the cheap proof.
- Gates and waivers: `coverage.py` and `verify_plan.py` are untouched;
  existing workspaces, coverage maps and waiver ledgers keep working.

## New output you should start reading

- `_meta.scopes[].declared_types` / `zero_yield_types` — per-scope
  yield tables. The aggregate `_meta.declared_types` cannot show a type
  that yields zero in one scope while non-zero in another; the
  per-scope record (and its stderr warning) can. Quote the per-scope
  tables in the step-5 report.
- Every inventory entry carries `scopes: [...]` — the scope(s) that
  collected it, merged and sorted when scopes overlap.

## Migration checklist

1. Rewrite the manifest as above (or regenerate:
   `manifest_from_state.py` and `manifest_init.py` emit the new
   grammar directly).
2. Run `inventory.py collect` — validation is fail-closed and runs
   before any API call, so a wrong migration is a refused manifest
   with the reason, never a shrunken denominator.
3. Diff the new `inventory.json` asset keys against the last
   pre-migration one. Identical keys = faithful migration. Missing
   keys = you narrowed while migrating; deliberate narrowing belongs
   in its own reviewed manifest change, not folded into the migration.
4. The manifest is human-owned: the migrated file goes through the
   same Scope Approval gate as any other manifest edit.

Worked references: `examples/import-manifest.org-foundation.yaml`
(single scope) and `examples/import-manifest.multi-domain.yaml` (four
scopes, per-scope types). The fail-closed rules live in SKILL.md
step 0 and the cookbook's "Per-scope type declaration" subsection.
