# CAI blind spots — where the denominator is incomplete

The completeness gate is only as strong as Cloud Asset Inventory's
coverage. An asset type CAI does not model is invisible to BOTH gates
simultaneously (not enumerated → not required by coverage; not emitted →
not diffed by plan). Treat this list as living documentation: verify and
extend it per engagement.

## The rule

**CAI is the DEFAULT source of the denominator, never the boundary of
it.** Anything CAI does not support is retrieved by other means and
merged into the same denominator, so the completeness gate still has to
account for it. "CAI cannot see it" is not a reason for an asset to be
absent; it is a reason to enumerate it differently.

The ladder, in order of preference:

1. **CAI** (`gcloud asset list`, `asset search-all-resources`) — default,
   because one sweep covers a whole hierarchy and returns ancestry.
2. **`gcloud <service> list|describe`** — the preferred alternative.
   Read-only, already installed, already authenticated as the run's
   read-only identity, and machine-readable with `--format=json`.
   Declare it in the manifest as a native enumerator (below) so the
   entries land in `inventory.json` like any others.
3. **The service REST API** (`curl` with `gcloud auth print-access-token`)
   — only where gcloud has no surface at all. Enumerate out of band,
   record the exact call in the run report, and treat any assets found
   as in scope for mapping.
4. **A signed waiver plus a run-report entry** — the last resort, and a
   deliberate, attributed decision. "Not enumerable" is a fact to
   publish, never a silence.

`inventory.py` enforces step 1→2: a declared type CAI rejects as unknown
now fails the run with the remedy, instead of a generic enumeration
failure. It cannot enforce 3 and 4 — that is the operator's honesty, and
the run report is where it is spent.

## Declaring a native enumerator

A manifest type entry may carry an `enumerate:` block. The type is then
never sent to CAI; the declared gcloud command runs once per in-scope
container at the type's `levels`, and its JSON becomes inventory
entries:

```yaml
types:
  # IAM deny policies: managed by modules/organization, modules/folder
  # and modules/project, and absent from the CAI catalogue entirely.
  - type: iam.googleapis.com/DenyPolicy
    levels: [organization, folder]
    enumerate:
      # `gcloud` is implicit and is the only executable a manifest can
      # name. The tool appends --format=json and one container argument.
      command: [iam, policies, list, --kind=denypolicies]
      # Optional: the shape of that container argument, when the command
      # does not take --organization/--folder/--project=<id>. Fields:
      # {container} (e.g. organizations/1) and {container_id} (1).
      container_arg: '--attachment-point=cloudresourcemanager.googleapis.com/{container}'
      # Key template. Fields: {container}, {container_id} and
      # {item.<dotted.path>} into each returned JSON object. Where the
      # type has a CAI name format, mirror it, so entries from the two
      # sources dedupe instead of double-counting.
      key: '//iam.googleapis.com/{container}/denypolicies/{item.name}'
```

Run the command by hand once before committing the block: the key
template has to match the payload the command actually returns, and a
first run is the cheapest place to find out that it does not. A field
that is absent is a hard failure, and a yield of zero is reported
loudly — neither is silent, but neither belongs in a run either.

Guard rails, all fail-closed, all for the same reason — a native
enumerator is a hand-written piece of the denominator, and the
denominator is the one thing in this skill nobody is allowed to shrink
quietly:

- the command must end in a read-only verb (`list`, `describe`, `get`,
  `search`); anything else is refused before a single call is made;
- `--format`, `--filter`, `--limit`, `--page-size`, `--flatten`,
  `--sort-by` and `--uri` are refused. Narrowing belongs in the
  manifest's `scope` block, where it is reviewed; a `--filter` inside an
  enumerator shrinks the denominator with no trace;
- the command may not select an identity — impersonation is set once for
  the whole run via `CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT`;
- a key template that renders the same key for two items, or that
  references a field the payload does not have, is a hard failure. Two
  assets collapsing onto one key is a shrunken denominator with a green
  gate;
- every native sweep is stamped into `inventory.json`'s `_meta`
  (`native_sweeps`: type, verbatim command, container, yield) and
  announced on stderr. A reviewer can re-run each command by hand.

The manifest is human-owned and committed at the scope-approval gate,
which is what makes an operator-supplied command acceptable at all. An
agent may draft one; a human signs it, exactly as with waivers.

## Known or suspected gaps (verify per engagement)

| Area | Concern | Mitigation |
|---|---|---|
| Service coverage | CAI supports several hundred asset types but not every GCP service/resource; niche or very new resources may be absent | Check the [CAI supported types list](https://cloud.google.com/asset-inventory/docs/supported-asset-types) for every service the user cares about; for uncovered types, declare a native enumerator (above) so they still enter the denominator |
| Wrong type string | A type string that does not exist in the catalogue is not a blind spot but a typo, and it presents as one. `gcloud asset list` answers `INVALID_ARGUMENT: No supported asset type matches: <type>` | `inventory.py` classifies that error separately from a permission failure and stops with instructions. Live example: `logging.googleapis.com/OrganizationSettings` does not exist — CAI models the Logs Router settings singleton as `logging.googleapis.com/Settings` at every container level |
| IAM deny policies | `iam.googleapis.com/DenyPolicy` is not a CAI asset type. Fabric manages deny policies at all three container levels (`iam_deny_policies`) | Declare a native enumerator around `gcloud iam policies list --kind=denypolicies` (the worked example above) |
| Log exclusions | `logging.googleapis.com/LogExclusion` is not a CAI asset type, and current `gcloud` has no `logging exclusions` group either — the ladder falls through to the REST API (`v2/{parent}/exclusions`). Fabric manages exclusions in `modules/organization`, `modules/folder` and `modules/project` | Enumerate out of band, map them, and record the enumeration method in the run report; do not let their absence from CAI read as absence from the estate |
| Org-policy content-type lag | `--content-type=org-policy` can lag behind newly introduced v2 constraints; the `orgpolicy.googleapis.com/Policy` resource asset stream is more complete | `inventory.py` merges both CAI streams; keep cross-checking counts with `gcloud org-policies list` |
| Org-policy dry-run specs | CAI `orgpolicy.googleapis.com/Policy` resource stream returns policies where `spec` is present (with or without `dryRunSpec`), but completely **omits dry-run-only policies** where `spec` is unset | `inventory.py collect` sweeps `gcloud org-policies list` per in-scope container and merges by key, so dry-run-only policies enter the denominator automatically |
| IAM conditions | The `iam-policy` content type returns version-3 policies with conditional bindings intact | Verified in live testing |
| IAM on leaf assets | `inventory.py` restricts the `iam` pseudo-type to container assets (`Organization`, `Folder`, `Project`); leaf IAM needs explicit per-type manifest entries (`iam: true`) | Documented in the manifest reference |
| Audit configs | `auditConfigs` block is present and fully preserved in the CAI `iam-policy` payload | Verified in live testing |
| Deleted / pending-delete resources | CAI reflects live state; soft-deleted roles or pending-delete projects may or may not appear | Decide policy per type; document in the run report |
| Propagation lag | CAI can lag live changes by minutes | Re-run inventory immediately before the final gate pass; treat count mismatches with service APIs as failures, not noise |
| Data-plane / child resources | Some child resources (e.g. per-bucket notification configs, dataset ACL entries) are attributes of the parent in CAI, not assets | The plan gate covers them once the parent is imported; note them in the report if the user expects per-child coverage |
| Access Context Manager | CAI `asset list --content-type=resource` rejects ACM types, requiring `asset search-all-resources`; `parentFullResourceName` lacks standard container prefixes | Handled in `inventory.py` via dedicated search and level classification |

## Rules

1. When the manifest declares a type, confirm it appears in the CAI
   supported-types list. If it does not, it gets a native enumerator, an
   out-of-band enumeration recorded in the report, or a signed waiver —
   one of the three, always. Never a quiet removal from the manifest.
2. Any count mismatch between CAI and a service API is a **failure to
   investigate**, never noise to average over.
3. Every entry that did not come from CAI is named in the run report,
   with the command that produced it. `_meta.native_sweeps` in
   `inventory.json` carries this for declared enumerators; out-of-band
   enumeration is on you to quote.
4. New blind spots discovered during an engagement get added here (this
   file is reference documentation, not a frozen tool).
