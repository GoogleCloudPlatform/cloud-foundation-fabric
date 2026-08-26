# CAI blind spots — where the denominator is incomplete

The completeness gate is only as strong as Cloud Asset Inventory's
coverage. An asset type CAI does not model is invisible to BOTH gates
simultaneously (not enumerated → not required by coverage; not emitted →
not diffed by plan). Treat this list as living documentation: verify and
extend it per engagement.

There are two distinct blind spots, and they need different remedies:

1. **CAI does not model the type at all.** The classic case, and what
   most of this document is about. Remedy: enumerate it by other means
   and merge it into the same denominator.
2. **CAI models the type under a different NAME on the surface you
   queried.** Rarer, much quieter, and not a blind spot in CAI at all —
   a blind spot in the question. See
   [Surface-dependent type taxonomies](#surface-dependent-type-taxonomies).

## The rule

**CAI is the DEFAULT source of the denominator, never the boundary of
it.** Anything CAI does not support is retrieved by other means and
merged into the same denominator, so the completeness gate still has to
account for it. "CAI cannot see it" is not a reason for an asset to be
absent; it is a reason to enumerate it differently.

The ladder, in order of preference:

1. **CAI** (`gcloud asset list`, `asset search-all-resources`) — default,
   because one sweep covers a whole hierarchy and returns ancestry.
2. **CAI answered, but incompletely (field-level blind spots)** — CAI models
   the asset type but omits specific resource fields. Note the critical
   asymmetry: an unsupported type fails loudly (gcloud errors, the run refuses
   with a clear remedy), whereas a missing field fails silently (`.get()`
   returns `None`, a filter predicate answers "no", and the run looks healthy).
   A filter predicate must never depend on a field whose presence in the live
   payload has not been verified. When a discriminator field is unavailable or
   unverified, the filter must **fail open** — keep the asset in the
   denominator for a human to waive, never drop it.
3. **`gcloud <service> list|describe`** — the preferred alternative when CAI
   does not model the type. Read-only, already installed, already authenticated
   as the run's read-only identity, and machine-readable with `--format=json`.
   Declare it in the manifest as a native enumerator (below) so the entries
   land in `inventory.json` like any others.
4. **The service REST API** (`curl` with `gcloud auth print-access-token`)
   — only where gcloud has no surface at all. Enumerate out of band,
   record the exact call in the run report, and treat any assets found
   as in scope for mapping.
5. **A signed waiver plus a run-report entry** — the last resort, and a
   deliberate, attributed decision. "Not enumerable" is a fact to
   publish, never a silence.

`inventory.py` walks steps 1→2 by itself. It ships a table of built-in
enumerators (`NATIVE_ENUMERATORS`) for types known to be absent from the
CAI catalogue: declaring such a type in the manifest is enough, and the
tool announces that it took the gcloud route. A declared type that CAI
rejects and no enumerator covers fails the run with the remedy, instead
of a generic enumeration failure. Steps 3 and 4 it cannot enforce — that
is the operator's honesty, and the run report is where it is spent.

## Surface-dependent type taxonomies

CAI does not have one asset-type taxonomy. It has two, and for a handful
of Compute families they disagree:

- the **list / export / query / monitor** surface (`gcloud asset list`,
  this tool's primary sweep) splits a family by scope into **separate
  asset types**;
- the **search / analysis** surface (`gcloud asset
  search-all-resources`) folds those same resources into a **single
  unified type**.

Google documents this per type on the
[supported types list](https://cloud.google.com/asset-inventory/docs/supported-asset-types),
but only in the per-type prose, which is easy to read past:

> `compute.googleapis.com/Address` — Returns global and regional
> addresses in the search and analysis APIs, and only regional addresses
> in the list, export, query, and monitor APIs.
>
> `compute.googleapis.com/GlobalAddress` — Not available in the analysis
> and search APIs. Use `compute.googleapis.com/Address` instead in the
> search and analysis APIs.

The documented pairs:

| Declared (search taxonomy) | List-surface sibling swept alongside it |
|---|---|
| `compute.googleapis.com/Address` | `compute.googleapis.com/GlobalAddress` |
| `compute.googleapis.com/BackendService` | `compute.googleapis.com/RegionBackendService` |
| `compute.googleapis.com/Disk` | `compute.googleapis.com/RegionDisk` |
| `compute.googleapis.com/ForwardingRule` | `compute.googleapis.com/GlobalForwardingRule` |

### Reproducing it, if you ever need to

The silent-gap condition needs a family whose declared type yields
**non-zero** while still being incomplete: at least one REGIONAL address
and at least one GLOBAL address, in the same in-scope project. With only
global addresses present the declared type yields zero, the pre-existing
zero-yield warning fires, and the tool is loud — a real bug, but not
THIS bug. A test estate built only from a freshly created global address
therefore validates that siblings are swept, and validates nothing about
the silence.

### Why this one is worse than an unsupported type

An unsupported type fails loudly. This one fails **silently, past every
guard the tool has** — which is why it needed a mechanism rather than a
sharper error message. Live-run finding: a global Private Service
Connect address never entered the denominator, because

- the declared type IS supported by `asset list`, so the
  unsupported-type fallback to `search-all-resources` never fired;
- the sweep SUCCEEDED, so nothing landed in `SWEEP_FAILURES`;
- it returned 33 regional addresses, so the zero-yield warning stayed
  quiet;
- the asset was never collected, so `apply_level_filter`'s `unknown`
  safety net never saw it either.

The operator had already hand-written the correct `import {}` block, so
the only signal that fired was `coverage.py` reporting it as an **orphan
import block** — and an orphan was read as a coverage-map problem and
waived, rather than as evidence that the denominator was short.

**An orphan import block for a resource you know is live is evidence the
denominator is short.** Investigate the enumeration before waiving it;
a waiver signed over a short denominator makes the gap permanent and
attributed to a human.

### What `inventory.py` does

`CAI_SPLIT_TYPES` is a frozen table of the pairs above. Declaring the
unified type sweeps its list-surface siblings too, and the siblings'
entries are **retyped back to the declared type**, so one manifest line
means "all addresses" — which is what an operator reading the
supported-types page will believe it means. This costs **zero extra API
calls**: `asset list` takes a comma-separated `--asset-types`, so the
siblings ride along in the existing sweep.

Nothing is laundered by the retyping:

- each retyped entry carries `cai_list_type` with the type CAI actually
  returned it as, and that field travels into `coverage.py`'s worklist;
- `_meta.split_type_sweeps` records declared type, list-surface type,
  scope and the RAW swept count — what CAI returned, before the
  subtree/deleted/level filters;
- collection prints a NOTICE naming every sibling that contributed, and
  reconciles swept against in-the-denominator itself (e.g. `3 swept …,
  2 in the denominator (1 excluded by scope/level/deleted filters)`) —
  the filters apply to retyped entries like to any other asset, and the
  subtraction is the tool's to show, not the reader's to derive.

A sibling the manifest declares **in its own right** is not remapped: an
operator who names `compute.googleapis.com/GlobalAddress` explicitly
wants it accounted as itself, and remapping would make their
per-declared-type yield read zero.

### Checking the table against live CAI

The table is a frozen snapshot of a document Google changes. A new split
— or a renamed pairing — would put the tool straight back into the
failure mode the table closes, so there is a probe:

```bash
uv run scripts/inventory.py collect --manifest import-manifest.yaml \
  --out inventory.json --verify-search-parity
```

One extra `search-all-resources` call per scope, restricted to declared
split types. It compares against the **raw** sweep output, before the
manifest's subtree filters, because the question under test is taxonomy
and not scope. Anything the search surface returns that the list sweep
did not is **fatal** (exit 3) with the offending resource names: the
table is stale and the denominator is incomplete.

The probe is opt-in, for two reasons: it costs a call per scope, and it
imports the search index's propagation lag as a possible false positive.
Run it at least once per engagement, and quote the result in the run
report. `_meta.split_parity` is **empty** when the probe did not run; a
probe that ran and found nothing is a RECORD whose `only_in_search` is
empty. Read the record, not the key — "not checked" and "checked, clean"
are different claims and must not be reported as the same one.

If the probe fires, identify the list-surface type of the missing assets
(`gcloud asset list` with no `--asset-types`, then match on name) and
report it: `CAI_SPLIT_TYPES` needs a new entry, which is a reviewed
change to a frozen file, not a local patch.

CAI **retiring** a split is the convergence this table is waiting for.
A sibling type that `asset list` no longer recognises is therefore
reported as a possibly-stale table, not as a failed run — a sibling is
tool-supplied, not operator-declared, so it must never fail someone
else's collection.

## Built-in enumerators

| Asset type | How it is enumerated | Status |
|---|---|---|
| `iam.googleapis.com/DenyPolicy` | `gcloud iam policies list --kind=denypolicies --attachment-point=cloudresourcemanager.googleapis.com/<container>` | Command shape verified against gcloud 576; payload shape not yet exercised live |

The table is short on purpose. To qualify, an enumerator has to be
hierarchy-container-scoped, read-only, JSON-emitting, and produce a key
that is stable and unique. Most non-CAI types fail one of those —
usually the first — and stay in the blind-spot table below, enumerated
by hand and named in the run report.

The table is frozen, like the rest of `inventory.py`: it decides part of
what the denominator contains. Nothing about extending it requires
editing a frozen file, though — a manifest block covers a type the table
does not, and overrides an entry when an operator knows better. An
enumerator earned in an engagement should come back as a reviewed change
to the table, so the next run starts with it.

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

**The mechanism is per hierarchy container**, because that is the shape
of the manifest's `levels`. A command that enumerates inside another
resource — `gcloud storage managed-folders list gs://BUCKET` — cannot be
expressed as an `enumerate:` block: there is no container flag to fill
in. Those types are enumerated out of band and named in the run report
(step 3 of the ladder), or waived deliberately. Do not force them into a
block by hard-coding one bucket; a container argument that does not vary
sweeps one place and leaves the rest silently unenumerated, which is why
the tool refuses it.

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
| Right type string, wrong surface | A type that is correct for `search-all-resources` can cover only PART of its family under `asset list`, which splits some Compute families by scope into separate types. No error, non-zero yield, silent gap. Live example: a global PSC address typed `compute.googleapis.com/GlobalAddress` by the list surface, absent from a `compute.googleapis.com/Address` sweep | **Handled automatically** for the documented pairs — `CAI_SPLIT_TYPES` sweeps the siblings and accounts them under the declared type. Run `--verify-search-parity` once per engagement to check the frozen table against live CAI; see [Surface-dependent type taxonomies](#surface-dependent-type-taxonomies) |
| IAM deny policies | `iam.googleapis.com/DenyPolicy` is not a CAI asset type. Fabric manages deny policies at all three container levels (`iam_deny_policies`) | **Handled automatically** — built-in enumerator; just declare the type |
| Log exclusions | `logging.googleapis.com/LogExclusion` is not a CAI asset type, and current `gcloud` has no `logging exclusions` group either — the ladder falls through to the REST API (`v2/{parent}/exclusions`). Fabric manages exclusions in `modules/organization`, `modules/folder` and `modules/project` | Enumerate out of band, map them, and record the enumeration method in the run report; do not let their absence from CAI read as absence from the estate |
| Org-policy content-type lag | `--content-type=org-policy` can lag behind newly introduced v2 constraints; the `orgpolicy.googleapis.com/Policy` resource asset stream is more complete | `inventory.py` merges both CAI streams; keep cross-checking counts with `gcloud org-policies list` |
| Org-policy dry-run specs | CAI `orgpolicy.googleapis.com/Policy` resource stream returns policies where `spec` is present (with or without `dryRunSpec`), but completely **omits dry-run-only policies** where `spec` is unset | `inventory.py collect` sweeps `gcloud org-policies list` per in-scope container and merges by key, so dry-run-only policies enter the denominator automatically |
| IAM conditions | The `iam-policy` content type returns version-3 policies with conditional bindings intact | Verified in live testing |
| IAM on leaf assets | `inventory.py` restricts the `iam` pseudo-type to container assets (`Organization`, `Folder`, `Project`); leaf IAM needs explicit per-type manifest entries (`iam: true`) | Documented in the manifest reference |
| Audit configs | `auditConfigs` block is present and fully preserved in the CAI `iam-policy` payload | Verified in live testing |
| Deleted / pending-delete resources | CAI reflects live state; soft-deleted roles or pending-delete projects may or may not appear | Decide policy per type; document in the run report |
| Propagation lag | CAI can lag live changes by minutes | Re-run inventory immediately before the final gate pass; treat count mismatches with service APIs as failures, not noise |
| Cloud Storage below the bucket | The Cloud Storage section of the CAI catalogue contains exactly one type, `storage.googleapis.com/Bucket`. Objects (`google_storage_bucket_object`), managed folders (`google_storage_managed_folder`) and managed-folder IAM are not modelled | `gcloud storage ls` / `gcloud storage managed-folders list` take a bucket URL, not a container flag, so they do not fit an `enumerate:` block. Enumerate per bucket out of band, map, and record the method in the run report |
| Terraform-only resources | Some `google_*` resources correspond to no asset at all. `google_project_service_identity` triggers creation of a Google-managed service agent: the state row is real, the CAI asset is not, and Fabric's `modules/project` handles service agents internally | Map through the owning module and note it in the report; there is nothing to enumerate and nothing to waive |
| Leaf IAM read as a missing type | `google_storage_bucket_iam_binding`, `google_tags_tag_value_iam_binding` and friends are not asset types. They are the `iam-policy` content type on an asset CAI already models, and enter the denominator via `iam: true` on the PARENT type entry | Never waive these as unsupported. `manifest_from_state.py` maps the common ones to their parent with the flag already set |
| Data-plane / child resources | Some child resources (e.g. per-bucket notification configs, dataset ACL entries) are attributes of the parent in CAI, not assets | The plan gate covers them once the parent is imported; note them in the report if the user expects per-child coverage |
| Access Context Manager | CAI `asset list --content-type=resource` rejects ACM types, requiring `asset search-all-resources`; `parentFullResourceName` lacks standard container prefixes | Handled in `inventory.py` via dedicated search and level classification |

## Rules

1. When the manifest declares a type, confirm it appears in the CAI
   supported-types list. If it does not, it gets a native enumerator, an
   out-of-band enumeration recorded in the report, or a signed waiver —
   one of the three, always. Never a quiet removal from the manifest.
2. Any count mismatch between CAI and a service API is a **failure to
   investigate**, never noise to average over. The same applies between
   CAI's own two surfaces: `asset list` and `search-all-resources`
   disagreeing about a type is a taxonomy split to identify, not a
   discrepancy to pick a winner from.
3. An **orphan import block** reported by `coverage.py` for a resource
   you know is live is evidence the denominator is short. Investigate
   the enumeration first; a waiver over a short denominator makes the
   gap permanent and signs a human's name to it.
4. Every entry that did not come from CAI is named in the run report,
   with the command that produced it. `_meta.native_sweeps` in
   `inventory.json` carries this for declared enumerators;
   `_meta.split_type_sweeps` carries entries that came from CAI under a
   different type than the one declared; out-of-band enumeration is on
   you to quote.
5. New blind spots discovered during an engagement get added here (this
   file is reference documentation, not a frozen tool).
