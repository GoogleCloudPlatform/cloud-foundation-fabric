# CAI blind spots — where the denominator is incomplete

The completeness gate is only as strong as Cloud Asset Inventory's
coverage. An asset type CAI does not model is invisible to BOTH gates
simultaneously (not enumerated → not required by coverage; not emitted →
not diffed by plan). Treat this list as living documentation: verify and
extend it per engagement.

## Known or suspected gaps (verify per engagement)

| Area | Concern | Mitigation |
|---|---|---|
| Service coverage | CAI supports several hundred asset types but not every GCP service/resource; niche or very new resources may be absent | Check the [CAI supported types list](https://cloud.google.com/asset-inventory/docs/supported-asset-types) for every service the user cares about; for uncovered services, enumerate with the service API (`gcloud <svc> list`) and merge into the inventory manually |
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
   supported-types list; if not, add a manual enumeration step and record
   it in the run report.
2. Any count mismatch between CAI and a service API is a **failure to
   investigate**, never noise to average over.
3. New blind spots discovered during an engagement get added here (this
   file is reference documentation, not a frozen tool).
