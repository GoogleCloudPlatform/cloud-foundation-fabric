#!/usr/bin/env python3
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# /// script
# requires-python = ">=3.10"
# dependencies = [
#    "pyyaml",
# ]
# ///
"""FROZEN SCRIPT — Cloud Asset Inventory enumeration for fabric-importer.

Produces the completeness denominator: a normalized inventory of every
asset the import manifest declares in scope. The model operating the skill
may RUN this tool but must never modify it; the coverage gate reconciles
the model's output against this inventory.

Modes:
  survey   enumerate every resource asset in scope (no type filter) to
           help draft a manifest:  inventory.py survey --scope ORG [--out F]
  collect  enumerate exactly what the manifest declares:
           inventory.py collect --manifest F [--out F]

Output: survey mode emits a bare JSON array of normalized entries;
collect mode wraps them with provenance metadata:
  {"_meta": {manifest hash, tool digest, per-type yields, ...},
   "assets": [{"key": ..., "asset_type": ..., "level": ...,
               "container": ...}, ...]}
  - resources:    key = CAI asset name
  - iam policies: key = "<asset name>#iam"
  - org policies: key = "<asset name>#org-policy/<constraint>"

Cloud Asset Inventory is the DEFAULT source of the denominator, not its
boundary: a manifest type CAI does not model is enumerated natively via
a read-only gcloud command declared in the manifest (`enumerate:`) and
merged into the same output. A declared type CAI rejects as unknown, and
for which no native enumerator exists, is fatal — an unenumerated asset
is invisible to both gates at once.

All gcloud interaction is read-only (`gcloud asset list`, plus the
list/describe commands declared by native enumerators). Requires
roles/cloudasset.viewer on the scope (see SKILL.md), plus per-service
viewer roles for any natively enumerated type.
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import time

import yaml

import integrity

PSEUDO_TYPES = ('iam', 'org-policy')
VALID_LEVELS = frozenset(('organization', 'folder', 'project', 'unknown'))
_LEVEL_BY_TYPE = {
    'cloudresourcemanager.googleapis.com/Organization': 'organization',
    'cloudresourcemanager.googleapis.com/Folder': 'folder',
    'cloudresourcemanager.googleapis.com/Project': 'project',
}

# Enumeration failures tolerated mid-run are recorded here and turned
# into a HARD failure at the end of collect(): a silently shrunken
# denominator is the one failure mode this tool must never have.
SWEEP_FAILURES = []

# Sweeps skipped because the API is disabled. Not fatal, but reported:
# a disabled service and a permission error can produce the same string.
SUPPRESSED_SWEEPS = []

# Declared types Cloud Asset Inventory refused as unknown. CAI is the
# DEFAULT source of the denominator, never the boundary of it: a type CAI
# does not model has to be enumerated by other means (gcloud first) and
# merged into the same denominator. Dropping it is the silent-gap failure
# this tool exists to prevent, so an unsupported type with no native
# enumerator is fatal, with instructions.
UNSUPPORTED_CAI_TYPES = []

# What each native (non-CAI) enumeration actually ran and yielded, for the
# provenance block: a denominator built partly outside CAI must say so.
NATIVE_SWEEPS = []

# Which CAI list-surface sibling types were swept for a declared unified
# type, and how many entries each contributed (see CAI_SPLIT_TYPES).
# Part of the denominator that would not exist under a literal reading of
# the manifest, so it is stamped rather than assumed.
SPLIT_TYPE_SWEEPS = []

# Results of the optional --verify-search-parity probe: assets the search
# surface returns for a split type that the list sweep did not produce.
# Non-empty means CAI_SPLIT_TYPES is stale against live CAI, and is
# FATAL — the whole point is that this class of gap must never be quiet.
SPLIT_PARITY_FINDINGS = []

# Privileged Access Manager grant bindings are machine-managed runtime
# state: PAM injects a temporary conditional role binding on grant
# activation and revokes it itself when the grant ends. They are NEVER
# configuration, so they are stripped from container IAM policies BEFORE
# the denominator is formed — never mapped, never waived. CAI models the
# Grant resource, which makes exclusion deterministic: (target, role,
# requester) come from the grant itself, not from string-matching the
# binding's condition (whose format Google does not publish). Every
# stripped binding is recorded here and stamped into
# _meta.pam_grant_exclusions.
PAM_GRANT_TYPE = 'privilegedaccessmanager.googleapis.com/Grant'
# Grant states during which the temporary binding may exist in the
# policy (activation and revocation are propagation windows).
PAM_ACTIVE_STATES = frozenset(('ACTIVATING', 'ACTIVE', 'REVOKING'))
PAM_EXCLUSIONS = []
AUTO_GENERATED_EXCLUSIONS = []

import shutil

# gcloud's wording when an asset type is not in the CAI catalogue. Both
# `asset list` and `asset search-all-resources` say it; matching the
# phrase is what separates "this type does not exist in CAI" from "you
# lack permission", which are the same exit code and must not be the same
# diagnosis.
_CAI_UNSUPPORTED_MARKERS = (
    'no supported asset type matches',
    'is not a supported asset type',
    'not a valid asset type',
)


def _is_unsupported_type_error(text):
  low = (text or '').lower()
  return any(m in low for m in _CAI_UNSUPPORTED_MARKERS)


# ---------------------------------------------------------------------------
# Surface-dependent asset-type taxonomies
# ---------------------------------------------------------------------------
# Cloud Asset Inventory does not have ONE asset-type taxonomy; it has
# two, and they disagree. For a handful of Compute types the
# list/export/query/monitor surface (`gcloud asset list`, which is this
# tool's primary sweep) splits a family by scope into SEPARATE asset
# types, while the search/analysis surface (`asset search-all-resources`)
# folds them into a single unified type. Google documents this per type
# on the supported-asset-types page, e.g.:
#
#   compute.googleapis.com/Address
#     "Returns global and regional addresses in the search and analysis
#      APIs, and only regional addresses in the list, export, query, and
#      monitor APIs."
#   compute.googleapis.com/GlobalAddress
#     "Not available in the analysis and search APIs. Use
#      compute.googleapis.com/Address instead in the search and analysis
#      APIs."
#
# The failure this causes is the one this tool exists to prevent, and
# every existing guard misses it (live-run finding, global PSC address):
# the declared type is SUPPORTED by `asset list`, so the
# unsupported-type fallback to `search-all-resources` never fires; the
# sweep succeeds, so nothing lands in SWEEP_FAILURES; and it returns a
# non-zero count, so the zero-yield warning stays quiet. The global
# addresses are simply never asked for, and an asset absent from the
# denominator is invisible to BOTH gates at once.
#
# So: declaring the unified (search-taxonomy) type ALSO sweeps its
# list-taxonomy siblings, and the siblings' entries are retyped back to
# the declared type — one manifest line means "all addresses", which is
# what an operator reading the supported-types page will believe it
# means. The list-surface type is preserved per entry as `cai_list_type`
# and stamped into _meta.split_type_sweeps, so nothing is laundered.
#
# This costs ZERO extra API calls: `asset list` takes a comma-separated
# --asset-types, so the siblings ride along in the existing sweep.
#
# This table is frozen, like NATIVE_ENUMERATORS and for the same reason:
# it decides part of what the denominator contains. It is a snapshot of
# a Google doc that changes, which is why --verify-search-parity exists
# to check it against the search surface rather than trusting it
# forever.
#
# Note on the source doc: the prose for BackendService says the list
# surface returns "only regional backend services" while naming
# RegionBackendService as the list-only sibling, which is
# self-contradictory and is almost certainly an upstream error. The
# PAIRING is what matters here and is unambiguous; the direction of the
# split is not something this table has to decide.
CAI_SPLIT_TYPES = {
    'compute.googleapis.com/Address': ('compute.googleapis.com/GlobalAddress',),
    'compute.googleapis.com/BackendService':
        ('compute.googleapis.com/RegionBackendService',),
    'compute.googleapis.com/Disk': ('compute.googleapis.com/RegionDisk',),
    'compute.googleapis.com/ForwardingRule':
        ('compute.googleapis.com/GlobalForwardingRule',),
}


def split_sibling_map(declared):
  """Maps list-surface sibling type -> declared unified type.

  A sibling the manifest declares in its own right is NOT remapped: an
  operator who names `compute.googleapis.com/GlobalAddress` explicitly
  wants it accounted as itself, and remapping would make their
  per-declared-type yield read zero.
  """
  declared = set(declared)
  return {
      sibling: unified for unified, siblings in CAI_SPLIT_TYPES.items()
      if unified in declared for sibling in siblings if sibling not in declared
  }


def retype_split_assets(assets, sibling_map):
  """Retypes split-off siblings to their declared unified type in place.

  Retyping happens BEFORE normalization so that apply_level_filter(),
  which keys off `asset_type`, applies the DECLARED type's `levels`. A
  sibling left under its own type would match no manifest entry and be
  filtered by the permissive default instead of by user intent.

  Returns a {declared_type: {sibling_type: count}} tally for provenance.
  The tally counts the RAW sweep — before the subtree/deleted/level
  filters — because its job is to record what CAI returned; how many of
  those survive into the denominator is a separate number, reconciled in
  the end-of-run NOTICE.
  """
  tally = {}
  for a in assets:
    unified = sibling_map.get(a.get('assetType', ''))
    if not unified:
      continue
    sibling = a['assetType']
    a['_cai_list_type'] = sibling
    a['assetType'] = unified
    tally.setdefault(unified, {})
    tally[unified][sibling] = tally[unified].get(sibling, 0) + 1
  return tally


# Page sizes. gcloud passes these straight through to the API, and each
# page is one HTTP request against the CAI quota, so the default of 100
# turned a 50,000-asset organization into 500 round trips. Both values
# are the documented maximum for their method: assets.list caps at 1000,
# searchAllResources at 500 ("Page size is capped at 500 even if a
# larger value is given"). Anything larger is silently clamped, so these
# are the ceiling, not a tuning knob.
#
# Deliberately NOT applied to `gcloud org-policies list` or to native
# enumerators: their page-size limits are per-service and undocumented
# here, and an out-of-range value would be a new failure mode bought for
# an unmeasured gain.
CAI_LIST_PAGE_SIZE = 1000
CAI_SEARCH_PAGE_SIZE = 500

# Every subprocess this tool runs, in order, with its outcome. Always
# RECORDED and summarized into the inventory's provenance block, so the
# cost of a collection is auditable after the fact; printed per call
# only under --verbose, because a large estate produces one pair of
# lines per in-scope container and that buries the warnings that matter.
API_CALLS = []
VERBOSE = False


def _log_call(index, cmd):
  if VERBOSE:
    print(f'[api {index:>3}] {" ".join(cmd)}', file=sys.stderr, flush=True)


def _log_result(index, outcome, elapsed, count=None):
  if VERBOSE:
    detail = '' if count is None else f', {count} item(s)'
    print(f'[api {index:>3}] {outcome} in {elapsed:.1f}s{detail}',
          file=sys.stderr, flush=True)


def run_json(cmd, ignore_errors=False, allow_disabled_service=False,
             timeout=300):
  executable = shutil.which(cmd[0]) or cmd[0]
  resolved_cmd = [executable] + cmd[1:]
  env = dict(os.environ, CLOUDSDK_CORE_DISABLE_PROMPTS='1')
  index = len(API_CALLS) + 1
  record = {'n': index, 'command': ' '.join(cmd), 'outcome': 'unknown'}
  API_CALLS.append(record)
  _log_call(index, cmd)
  started = time.monotonic()

  def finish(outcome, count=None):
    elapsed = time.monotonic() - started
    record['outcome'] = outcome
    record['seconds'] = round(elapsed, 2)
    if count is not None:
      record['item_count'] = count
    _log_result(index, outcome, elapsed, count)

  try:
    # encoding is pinned: gcloud always emits UTF-8, but `text=True`
    # decodes with the process locale, so a non-ASCII display name blew
    # up with UnicodeDecodeError under a non-UTF-8 LANG.
    res = subprocess.run(resolved_cmd, capture_output=True, text=True,
                         encoding='utf-8', errors='replace', env=env,
                         timeout=timeout)
  except FileNotFoundError:
    finish('NOT FOUND')
    if ignore_errors:
      msg = f'{" ".join(cmd)}: executable not found in PATH'
      SWEEP_FAILURES.append(msg)
      return []
    raise SystemExit(f"ERROR: executable '{cmd[0]}' not found in PATH")
  except subprocess.TimeoutExpired:
    finish('TIMEOUT')
    if ignore_errors:
      msg = f'{" ".join(cmd)}: command timed out after {timeout}s'
      SWEEP_FAILURES.append(msg)
      return []
    raise SystemExit(f"ERROR: command timed out: {' '.join(cmd)}")

  if res.returncode != 0:
    stderr = res.stderr.strip()
    if allow_disabled_service and any(
        phrase in stderr
        for phrase in ('SERVICE_DISABLED', 'API has not been used',
                       'has not enabled')):
      # Tolerated, but never silent: this is the only sweep that sees
      # dry-run-only org policies, so a permission or quota-project
      # error whose text happens to match one of these phrases would
      # remove a whole class of policies from the denominator.
      msg = f'{" ".join(cmd)}: {stderr.splitlines()[-1] if stderr else ""}'
      SUPPRESSED_SWEEPS.append(msg)
      finish('SKIPPED (service disabled)')
      print(f'WARNING: sweep suppressed as disabled-service: {msg}',
            file=sys.stderr)
      return []
    finish('FAILED')
    if ignore_errors:
      err_line = stderr.splitlines()[-1] if stderr else "unknown error"
      msg = f'{" ".join(cmd)}: {err_line}'
      SWEEP_FAILURES.append(msg)
      print(f'WARNING: enumeration failure (recorded): {msg}', file=sys.stderr)
      return []
    raise SystemExit(f'command failed: {" ".join(cmd)}\n{stderr}')
  payload = json.loads(res.stdout) if res.stdout.strip() else []
  finish('ok', len(payload) if isinstance(payload, list) else 1)
  return payload


def run_gcloud_json(args):
  return run_json([
      'gcloud', '--quiet', 'asset', 'list', '--format=json',
      f'--page-size={CAI_LIST_PAGE_SIZE}'
  ] + args)


def _is_deleted_container(asset):
  """Checks if a Folder or Project asset is in a deleted or pending-deletion lifecycle state."""
  t = asset.get('assetType', '')
  if t not in (
      'cloudresourcemanager.googleapis.com/Folder',
      'cloudresourcemanager.googleapis.com/Project',
  ):
    return False
  res_data = asset.get('resource', {}).get('data', {})
  state = (res_data.get('lifecycleState') or res_data.get('state') or
           asset.get('additionalAttributes', {}).get('lifecycleState'))
  if state:
    state_str = str(state).upper()
    if state_str in ('DELETE_REQUESTED', 'DELETE_IN_PROGRESS', 'DELETED'):
      return True
  return False


def _has_deleted_ancestor(asset, deleted_containers):
  """Checks if an asset itself or any ancestor is in deleted_containers."""
  if not deleted_containers:
    return False
  name = (asset.get('name', '') or
          '').removeprefix('//cloudresourcemanager.googleapis.com/')
  if name in deleted_containers:
    return True
  for a in asset.get('ancestors') or []:
    if a in deleted_containers:
      return True
  parent = (asset.get('parentFullResourceName', '') or
            '').removeprefix('//cloudresourcemanager.googleapis.com/')
  if parent in deleted_containers:
    return True
  for f in asset.get('folders') or []:
    if f in deleted_containers:
      return True
  if asset.get('project') in deleted_containers:
    return True
  return False


def _is_google_managed_logging_asset(asset):
  """Checks if an asset is a Google-managed default log sink or log bucket (_Default / _Required)."""
  t = asset.get('assetType', '')
  name = asset.get('name', '')
  if t == 'logging.googleapis.com/LogSink':
    if name.endswith('/sinks/_Default') or name.endswith('/sinks/_Required'):
      return True
  elif t == 'logging.googleapis.com/LogBucket':
    if name.endswith('/buckets/_Default') or name.endswith(
        '/buckets/_Required'):
      return True
  return False


def _is_pam_grant_asset(asset):
  """Checks if an asset is a Privileged Access Manager (PAM) Grant."""
  t = asset.get('assetType', '') or asset.get('asset_type', '')
  if t == 'privilegedaccessmanager.googleapis.com/Grant':
    return True
  name = asset.get('name', '') or asset.get('key', '')
  if '//privilegedaccessmanager.googleapis.com/' in name and '/grants/' in name:
    return True
  return False


def _is_auto_generated_route_asset(asset):
  """Checks if a Route asset is auto-generated by GCP (subnet-local, NCC, or peering next-hops)."""
  t = asset.get('assetType', '') or asset.get('asset_type', '')
  if t != 'compute.googleapis.com/Route':
    return False
  res_data = asset.get('resource', {}).get('data', {})
  if (res_data.get('nextHopNetwork') or res_data.get('nextHopHub') or
      res_data.get('nextHopPeering')):
    return True
  return False


AUTO_GENERATED_FILTERS = (
    ('logging-defaults', _is_google_managed_logging_asset,
     'Google-managed default log sink(s)/bucket(s) (_Default, _Required)'),
    ('pam-grants', _is_pam_grant_asset,
     'Privileged Access Manager (PAM) grant(s)'),
    ('routes', _is_auto_generated_route_asset,
     'auto-generated route(s) (subnet-local / NCC / peering next-hops)'),
)


def _resolve_included_auto_generated(include_auto_generated=None,
                                     include_logging_defaults=False,
                                     include_pam_grants=False):
  included = set()
  if include_auto_generated is True:
    included.update(family for family, _, _ in AUTO_GENERATED_FILTERS)
  elif isinstance(include_auto_generated, (list, set, tuple)):
    included.update(include_auto_generated)
  elif isinstance(include_auto_generated, str):
    included.update(
        f.strip() for f in include_auto_generated.split(',') if f.strip())
  if include_logging_defaults:
    included.add('logging-defaults')
  if include_pam_grants:
    included.add('pam-grants')
  valid_families = {family for family, _, _ in AUTO_GENERATED_FILTERS}
  unknown = included - valid_families
  if unknown:
    valid_list = ', '.join(sorted(valid_families))
    if len(unknown) == 1:
      bad_str = repr(next(iter(unknown)))
      raise SystemExit(f'unknown auto-generated filter family {bad_str}; '
                       f'valid families: {valid_list}')
    bad_str = ', '.join(sorted(repr(u) for u in unknown))
    raise SystemExit(f'unknown auto-generated filter families: {bad_str}; '
                     f'valid families: {valid_list}')
  return included


class ProjectRegistry:
  """Maintains bidirectional mapping between Project IDs and Project Numbers, and tracks deleted containers."""

  def __init__(self):
    self.id_to_num = {}
    self.num_to_id = {}
    self._unresolvable = set()
    self.deleted_containers = set()

  def register(self, num, pid, is_deleted=False):
    if num:
      num_str = str(num).removeprefix('projects/').strip()
      if pid:
        pid_str = str(pid).removeprefix('projects/').strip()
        self.id_to_num[pid_str] = num_str
        self.num_to_id[num_str] = pid_str
      if is_deleted:
        self.deleted_containers.add(f'projects/{num_str}')
        if pid:
          self.deleted_containers.add(f'projects/{pid_str}')

  def resolve(self, item):
    """Resolves a project string (ID, number, or path) returning (number, id)."""
    val = str(item).strip().removeprefix('projects/')
    if not val:
      return None, None
    if val.isdigit():
      num = val
      pid = self.num_to_id.get(num)
      return num, pid
    else:
      pid = val
      num = self.id_to_num.get(pid)
      if not num and pid not in self._unresolvable:
        # CAI `ancestors` are project NUMBERS, so failing to resolve an
        # id here does not raise: it makes in_subtree() match nothing,
        # which empties the denominator with exit 0. The failure has to
        # be recorded, and it has to be cached — an uncached miss
        # re-spawned this subprocess once per ASSET.
        cmd = [
            'gcloud', 'projects', 'describe', pid,
            '--format=json(projectNumber,projectId,lifecycleState)'
        ]
        out = run_json(cmd, ignore_errors=True, timeout=30)
        if isinstance(out, dict) and out.get('projectNumber'):
          num = str(out['projectNumber'])
          pid = str(out.get('projectId', pid))
          is_del = str(out.get('lifecycleState',
                               '')).upper() in ('DELETE_REQUESTED',
                                                'DELETE_IN_PROGRESS', 'DELETED')
          self.register(num, pid, is_deleted=is_del)
        else:
          self._unresolvable.add(pid)
          if not any(pid in m for m in SWEEP_FAILURES):
            msg = (f'gcloud projects describe {pid}: could not resolve '
                   'project id to a project number')
            SWEEP_FAILURES.append(msg)
      return num, pid

  def expand_target(self, target):
    """Returns a set of canonical target identifiers for matching."""
    t = str(target).strip()
    if not t:
      return set()
    if t.startswith('projects/') or (not t.startswith('organizations/') and
                                     not t.startswith('folders/')):
      val = t.removeprefix('projects/')
      num, pid = self.resolve(val)
      expanded = {f'projects/{val}'}
      if num:
        expanded.add(f'projects/{num}')
      if pid:
        expanded.add(f'projects/{pid}')
      return expanded
    return {t}

  def ingest_assets(self, assets):
    """Ingests Project and Folder resource assets into registry."""
    for a in assets:
      t = a.get('assetType', '')
      deleted = _is_deleted_container(a)
      if t == 'cloudresourcemanager.googleapis.com/Project':
        name = a.get('name', '')
        c_path = name.removeprefix('//cloudresourcemanager.googleapis.com/')
        num = c_path.removeprefix('projects/') if c_path.startswith(
            'projects/') else None
        res_data = a.get('resource', {}).get('data', {})
        pid = res_data.get('projectId') or a.get('additionalAttributes',
                                                 {}).get('projectId')
        p_num = res_data.get('projectNumber') or num
        if p_num and pid:
          self.register(p_num, pid, is_deleted=deleted)
        elif deleted:
          if p_num:
            self.deleted_containers.add(f'projects/{p_num}')
          if pid:
            self.deleted_containers.add(f'projects/{pid}')
      elif t == 'cloudresourcemanager.googleapis.com/Folder':
        name = a.get('name', '')
        c_path = name.removeprefix('//cloudresourcemanager.googleapis.com/')
        if deleted:
          self.deleted_containers.add(c_path)


def _level_of(path):
  for prefix, level in (('organizations/', 'organization'),
                        ('folders/', 'folder'), ('projects/', 'project')):
    if path.startswith(prefix):
      return level
  return None


def asset_level(asset):
  """CONTAINER level of an asset: organization, folder or project.

  Live-run finding: for resource-manager container
  assets (Organization/Folder/Project), `ancestors[0]` is the asset
  itself and `ancestors[1]` is its container; for leaf assets,
  `ancestors[0]` is the container. A top-level folder therefore has
  container level `organization`, a nested folder `folder`.
  """
  ancestors = asset.get('ancestors') or []
  t = asset.get('assetType', '')
  idx = 1 if t in _LEVEL_BY_TYPE else 0
  if idx < len(ancestors):
    level = _level_of(ancestors[idx])
    if level:
      return level
  if t in _LEVEL_BY_TYPE:
    # An organization has no container; classify it as its own level.
    return _LEVEL_BY_TYPE[t]
  name = asset.get('name', '')
  for marker, level in (('/organizations/', 'organization'),
                        ('/folders/', 'folder'), ('/projects/', 'project')):
    if marker in name:
      return level
  parent = (asset.get('parentFullResourceName', '') or
            asset.get('organization', '') or asset.get('project', ''))
  for marker, level in (('organizations/', 'organization'),
                        ('folders/', 'folder'), ('projects/', 'project')):
    if marker in parent:
      return level
  return 'unknown'


def apply_level_filter(entries, levels_by_type, report=True):
  """Applies per-type manifest level restrictions to collected entries.

  `unknown` is never silently dropped. A manifest's `levels` expresses
  CONTAINER-level intent ("org IAM yes, project IAM no"), so excluding
  organization/folder/project levels is a deliberate user choice. A level
  of `unknown` means `asset_level()` could not place the asset at all --
  a classifier limitation, not user intent. Dropping those would shrink
  the denominator with no warning, which is the exact silent-gap failure
  this tool exists to prevent.

  Live-run finding (round 15): ACM AccessLevel and ServicePerimeter
  assets carry a parent of
  `//accesscontextmanager.googleapis.com/accessPolicies/<id>`, which
  contains no `/organizations/` or `/projects/` marker, so both classify
  as `unknown`. Declared with the natural `levels: [organization]`, they
  disappeared from the denominator entirely and the gates still reported
  green. They are now kept and reported instead.
  """
  default_levels = {'organization', 'folder', 'project', 'unknown'}
  kept, unknown_kept = [], []
  for e in entries:
    allowed = levels_by_type.get(e['asset_type'], default_levels)
    if e['level'] in allowed:
      kept.append(e)
    elif e['level'] == 'unknown':
      kept.append(e)
      unknown_kept.append(e)
  if unknown_kept and report:
    by_type = {}
    for e in unknown_kept:
      by_type[e['asset_type']] = by_type.get(e['asset_type'], 0) + 1
    print(f'\nNOTICE: kept {len(unknown_kept)} asset(s) whose container '
          'level could not be classified.')
    print('They are IN the denominator and must be mapped or waived. They '
          'are NOT dropped')
    print('merely because the manifest lists explicit levels for their '
          'type:')
    for t, n in sorted(by_type.items()):
      print(f'  - {t}: {n}')
    print("Add `unknown` to that type's `levels` to silence this notice "
          'once reviewed.')
  return kept


def container_type_level(asset):
  """Level of a container asset ITSELF (org policy / IAM attachment
  semantics): an IAM policy on a folder is folder-level IAM regardless of
  where the folder sits."""
  return _LEVEL_BY_TYPE.get(asset.get('assetType', ''))


def in_subtree(asset, include, exclude, registry=None):
  """Applies manifest scope include / exclude ancestry filters."""
  ancestors = set(asset.get('ancestors') or [])
  if not ancestors:
    if asset.get('organization'):
      ancestors.add(asset['organization'])
    if asset.get('project'):
      ancestors.add(asset['project'])
    for f in asset.get('folders') or []:
      ancestors.add(f)
    if asset.get('parentFullResourceName'):
      p = asset['parentFullResourceName'].removeprefix(
          '//cloudresourcemanager.googleapis.com/')
      ancestors.add(p)

  expanded_ancestors = set(ancestors)
  if registry:
    for a in list(ancestors):
      if a.startswith('projects/'):
        val = a.removeprefix('projects/')
        num, pid = registry.resolve(val)
        if num:
          expanded_ancestors.add(f'projects/{num}')
        if pid:
          expanded_ancestors.add(f'projects/{pid}')

  if exclude:
    expanded_exclude = set()
    for item in exclude:
      if registry:
        expanded_exclude.update(registry.expand_target(item))
      else:
        expanded_exclude.add(item)
    if expanded_ancestors & expanded_exclude:
      return False

  if include:
    expanded_include = set()
    for item in include:
      if registry:
        expanded_include.update(registry.expand_target(item))
      else:
        expanded_include.add(item)
    return bool(expanded_ancestors & expanded_include)

  return True


def _normalize_resources(assets):
  out = []
  for a in assets:
    c = ''
    if a.get('ancestors'):
      c = a['ancestors'][0]
    elif a.get('parentFullResourceName'):
      c = a['parentFullResourceName'].removeprefix(
          '//cloudresourcemanager.googleapis.com/')
    elif a.get('organization'):
      c = a['organization']
    elif a.get('project'):
      c = a['project']
    entry = {
        'key': a['name'],
        'asset_type': a.get('assetType', ''),
        'level': asset_level(a),
        'container': c,
    }
    # Retyped split-surface sibling (see CAI_SPLIT_TYPES): the entry is
    # accounted under the declared unified type, but the type CAI's list
    # surface actually returned travels with it into the worklist, so a
    # reader never has to guess where it came from.
    if a.get('_cai_list_type'):
      entry['cai_list_type'] = a['_cai_list_type']
    out.append(entry)
  return out


def _normalize_leaf_iam(assets, iam_types):
  """IAM pseudo-entries for explicitly requested LEAF asset types.

  Container IAM (org/folder/project) is the `iam` pseudo-type; IAM
  attached to leaf assets (service accounts, tag values, buckets, ...)
  enters the denominator only when the manifest type entry opts in with
  `iam: true`. Entries carry the leaf's own asset type (so the type's
  `levels` restriction applies) and the key `<asset name>#iam`.
  """
  out = []
  for a in assets:
    t = a.get('assetType', '')
    if t not in iam_types or not a.get('iamPolicy'):
      continue
    out.append({
        'key': f'{a["name"]}#iam',
        'asset_type': t,
        'level': asset_level(a),
        'container': (a.get('ancestors') or [''])[0],
    })
  return out


def _normalize_iam(assets):
  """IAM pseudo-entries, restricted to container asset types.

  Live-run finding: without this restriction, IAM
  policies on leaf assets directly under the org (TagValues, buckets,
  service accounts, ...) pollute the organization-level IAM inventory.
  Leaf-asset IAM must be requested via its own resource type instead.
  The level is the container type itself (folder IAM = level folder).
  """
  out = []
  for a in assets:
    level = container_type_level(a)
    if level is None or not a.get('iamPolicy'):
      continue
    out.append({
        'key': f'{a["name"]}#iam',
        'asset_type': 'iam',
        'level': level,
        'container': (a.get('ancestors') or [''])[0],
    })
  return out


def _pam_grant_records(grant_assets, registry):
  """Normalizes active PAM grants for deterministic binding exclusion.

  Returns one record per grant in a binding-bearing state, carrying the
  canonicalized target container identifiers (project id AND number via
  the registry), the granted roles, and the requester — everything
  needed to identify the injected binding without guessing at its
  condition format.
  """
  records = []
  for a in grant_assets:
    data = a.get('resource', {}).get('data', {})
    state = str(data.get('state', '')).upper()
    if state not in PAM_ACTIVE_STATES:
      continue
    access = (data.get('privilegedAccess') or {}).get('gcpIamAccess') or {}
    name = data.get('name') or a.get('name', '')
    target = str(access.get('resource') or
                 '').removeprefix('//cloudresourcemanager.googleapis.com/')
    if not target:
      # Fall back to the grant's own name:
      # <container>/locations/<loc>/entitlements/<e>/grants/<g>
      target = name.removeprefix(
          '//privilegedaccessmanager.googleapis.com/').split('/locations/',
                                                             1)[0]
    records.append({
        'grant': name,
        'state': state,
        'requester': str(data.get('requester', '')).lower(),
        'targets': registry.expand_target(target),
        'roles': {
            rb.get('role')
            for rb in access.get('roleBindings') or []
            if rb.get('role')
        },
    })
  return records


def _strip_pam_grant_bindings(iam_assets, records):
  """Removes active PAM grant bindings from IAM policies, in place.

  Matching is deliberately narrow — all three must hold:
  conditional bindings only (PAM bindings always carry a time-bound
  condition, so a permanent binding that coincides with a grant is
  kept), role granted by a matching grant, member email equal to the
  grant's requester.

  A policy left with neither bindings nor audit configs is emptied
  entirely, so _normalize_iam() does not mint a `#iam` denominator
  entry for purely machine-managed state. Every stripped binding is
  appended to PAM_EXCLUSIONS for the provenance stamp.
  """
  for a in iam_assets:
    policy = a.get('iamPolicy') or {}
    bindings = policy.get('bindings') or []
    if not bindings:
      continue
    container = a.get('name',
                      '').removeprefix('//cloudresourcemanager.googleapis.com/')
    matching = [r for r in records if container in r['targets']]
    if not matching:
      continue
    kept_bindings = []
    for b in bindings:
      role = b.get('role')
      recs = [r for r in matching if role in r['roles']]
      if not b.get('condition') or not recs:
        kept_bindings.append(b)
        continue
      kept_members = []
      for m in b.get('members') or []:
        email = m.split(':', 1)[-1].lower()
        rec = next((r for r in recs if r['requester'] == email), None)
        if rec is None:
          kept_members.append(m)
        else:
          PAM_EXCLUSIONS.append({
              'container': container,
              'role': role,
              'member': m,
              'grant': rec['grant'],
              'state': rec['state'],
          })
      if kept_members:
        kept_bindings.append(dict(b, members=kept_members))
    if kept_bindings or policy.get('auditConfigs'):
      if len(kept_bindings) != len(bindings):
        a['iamPolicy'] = dict(policy, bindings=kept_bindings)
    else:
      a['iamPolicy'] = {}


def _normalize_org_policies(assets):
  out = []
  for a in assets:
    level = container_type_level(a)
    if level is None:
      continue
    for pol in a.get('orgPolicy') or []:
      constraint = pol.get('constraint', '')
      if constraint.startswith('constraints/'):
        constraint = constraint.split('/', 1)[1]
      out.append({
          'key': f'{a["name"]}#org-policy/{constraint}',
          'asset_type': 'org-policy',
          'level': level,
          'container': (a.get('ancestors') or [''])[0],
      })
  return out


def _org_policy_entry(parent, constraint):
  """Entry in the canonical '<attached asset>#org-policy/<constraint>'
  key format, shared by all three org-policy streams so they merge and
  dedupe cleanly."""
  return {
      'key': (f'//cloudresourcemanager.googleapis.com/{parent}'
              f'#org-policy/{constraint}'),
      'asset_type': 'org-policy',
      'level': _level_of(parent) or 'unknown',
      'container': parent,
  }


_ORG_POLICY_NAME = re.compile(
    r'^(?://orgpolicy\.googleapis\.com/)?'
    r'((?:organizations|folders|projects)/[^/]+)/policies/(.+)$')


def _normalize_org_policies_from_resources(assets):
  """Normalizes orgpolicy.googleapis.com/Policy resource assets.

  Live-run finding: the legacy `org-policy`
  content-type projection omits newer v2 constraints (observed:
  essentialcontacts.allowedContactDomains), while the Policy resource
  asset stream covers them.
  """
  out = []
  for a in assets:
    m = _ORG_POLICY_NAME.match(a.get('name', ''))
    if m:
      out.append(_org_policy_entry(m.group(1), m.group(2)))
  return out


def _normalize_org_policies_from_service(policies, container=''):
  """Normalizes `gcloud org-policies list --format=json` output.

  Live-run finding (round 3): BOTH CAI projections omit
  dry-run-only policies (dryRunSpec set, spec unset) entirely. The
  org-policy service API is the only complete enumeration, so collect()
  sweeps it per in-scope container and merges by key.

  Live gcloud org-policies list outputs `constraint` (not `name`), so
  the caller passes `container` when known.
  """
  out = []
  for p in policies:
    c = container
    constraint = p.get('constraint') or ''
    if p.get('name'):
      m = _ORG_POLICY_NAME.match(p['name'])
      if m:
        c, constraint = m.group(1), m.group(2)
    if constraint and c:
      if constraint.startswith('constraints/'):
        constraint = constraint.split('/', 1)[1]
      out.append(_org_policy_entry(c, constraint))
  return out


# ---------------------------------------------------------------------------
# Native (non-CAI) enumeration
#
# Rule: CAI is the default source of the denominator, not its boundary.
# Anything CAI does not support is retrieved by other means — `gcloud`
# first — and merged into the SAME denominator, so the completeness gate
# still has to account for it. "CAI cannot see it" is never a reason for
# an asset to be absent; it is a reason to enumerate it differently.
#
# A manifest type entry declares this with an `enumerate:` block:
#
#   - type: iam.googleapis.com/DenyPolicy
#     levels: [organization, folder]
#     enumerate:
#       command: [iam, policies, list, --kind=denypolicies]
#       container_arg: '--attachment-point=cloudresourcemanager.googleapis.com/{container}'
#       key: '//iam.googleapis.com/{container}/denypolicies/{item.name}'
#
# The command runs once per in-scope container at the declared levels,
# with --format=json and a container argument appended by this tool
# (--organization/--folder/--project=<id> unless `container_arg` gives
# the shape the command wants). The manifest is human-owned and
# human-committed at the scope-approval gate, which is what makes an
# operator-supplied command acceptable here; the guards below are what
# keep it from becoming a way to shrink the denominator quietly.
# ---------------------------------------------------------------------------

# Built-in enumerators, applied AUTOMATICALLY to any manifest type that
# names them. The default answer to "CAI does not model this type" is
# not "stop" and not "skip it" — it is "enumerate it another way" — so
# the knowledge of HOW lives here rather than being re-derived, by hand,
# in every engagement's manifest.
#
# This table is frozen, for the same reason the rest of this file is:
# it decides part of what the denominator contains. A manifest may
# override an entry (an operator who knows better wins) and may add
# blocks for types the table does not cover; neither requires editing
# this file. Entries earned in an engagement come back as a reviewed
# code change, so the next run starts with them.
#
# The bar for an entry: hierarchy-container-scoped (per-bucket or
# per-region commands cannot be expressed — see cai-blind-spots.md),
# read-only, JSON output, and a key that is stable and unique. Most
# non-CAI types fail one of those, which is why this table is short and
# the run report still carries out-of-band enumeration by hand.
NATIVE_ENUMERATORS = {
    # IAM deny policies: absent from the CAI catalogue, managed by
    # modules/organization, modules/folder and modules/project. The
    # policy `name` returned by the API already contains the attachment
    # point, so it is unique across containers on its own.
    # Command shape verified against gcloud 576; payload shape not yet
    # exercised against a live deny policy — a wrong key template fails
    # loudly (absent field, or non-unique key), never silently.
    'iam.googleapis.com/DenyPolicy': {
        'command': ['iam', 'policies', 'list', '--kind=denypolicies'],
        'container_arg':
            '--attachment-point=cloudresourcemanager.googleapis.com/'
            '{container}',
        'key': '//iam.googleapis.com/{item.name}',
    },
}

# Read-only verbs only. This is the manifest-side expression of the
# safety contract ("read-only against GCP"): the tool refuses to run a
# native enumerator that is not a list/describe.
_NATIVE_READ_VERBS = frozenset(('list', 'describe', 'get', 'search'))

# Flags the tool owns, or that reshape/limit output. A `--filter` or
# `--limit` in an enumerator shrinks the denominator with no trace, which
# is precisely the failure mode the gates exist to prevent; scope is
# expressed in the manifest's scope block, never in the command.
_NATIVE_FORBIDDEN_FLAGS = ('--format', '--filter', '--limit', '--page-size',
                           '--flatten', '--sort-by', '--uri')

_KEY_TOKEN = re.compile(r'\{([^{}]+)\}')


def _container_flag(container_path):
  return {
      'organizations': '--organization',
      'folders': '--folder',
      'projects': '--project',
  }.get(container_path.split('/', 1)[0])


def validate_native_spec(asset_type, spec):
  """Validates one `enumerate:` block, fail-closed."""
  if not isinstance(spec, dict):
    raise SystemExit(
        f'manifest type {asset_type!r}: `enumerate` must be a mapping with '
        '`command` and `key`')
  cmd = spec.get('command')
  if (not isinstance(cmd, list) or not cmd or
      not all(isinstance(c, str) and c.strip() for c in cmd)):
    raise SystemExit(
        f'manifest type {asset_type!r}: `enumerate.command` must be a '
        "non-empty list of gcloud arguments, e.g. [logging, sinks, list]")
  if cmd[0] == 'gcloud':
    raise SystemExit(
        f'manifest type {asset_type!r}: drop the leading `gcloud` from '
        '`enumerate.command`; the tool supplies it (and nothing else is '
        'executable from a manifest)')
  verbs = [c for c in cmd if not c.startswith('-')]
  if not verbs or verbs[-1] not in _NATIVE_READ_VERBS:
    raise SystemExit(
        f'manifest type {asset_type!r}: `enumerate.command` must end in a '
        f'read-only verb {sorted(_NATIVE_READ_VERBS)}; refusing to run '
        f'{verbs[-1] if verbs else cmd[-1]!r} against live infrastructure')
  for c in cmd:
    for bad in _NATIVE_FORBIDDEN_FLAGS:
      if c == bad or c.startswith(bad + '='):
        raise SystemExit(
            f'manifest type {asset_type!r}: `enumerate.command` may not '
            f'carry {bad}. Output shape is the tool\'s; narrowing belongs '
            'in the manifest scope, not in a flag that would shrink the '
            'denominator invisibly')
    if c.startswith('--impersonate-service-account'):
      raise SystemExit(
          f'manifest type {asset_type!r}: `enumerate.command` may not '
          'choose an identity; set CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT '
          'for the whole run instead')
  carg = spec.get('container_arg')
  if carg is not None:
    if not isinstance(carg, str) or not carg.startswith('--'):
      raise SystemExit(
          f'manifest type {asset_type!r}: `enumerate.container_arg` must be '
          "a flag template, e.g. "
          "'--attachment-point=cloudresourcemanager.googleapis.com/"
          "{container}'")
    tokens = _KEY_TOKEN.findall(carg)
    if not tokens or any(
        t not in ('container', 'container_id') for t in tokens):
      raise SystemExit(
          f'manifest type {asset_type!r}: `enumerate.container_arg` must '
          'reference {container} or {container_id} and nothing else — a '
          'container argument that does not vary per container would sweep '
          'the same place repeatedly and leave the rest unenumerated')
  key = spec.get('key')
  if not isinstance(key, str) or '{' not in key:
    raise SystemExit(
        f'manifest type {asset_type!r}: `enumerate.key` must be a template '
        "containing at least one field, e.g. "
        "'//logging.googleapis.com/{item.name}'")
  for token in _KEY_TOKEN.findall(key):
    if token not in ('container',
                     'container_id') and not token.startswith('item.'):
      raise SystemExit(
          f'manifest type {asset_type!r}: unknown key field {token!r}; use '
          '{container}, {container_id} or {item.<field>[.<field>...]}')


def _render_native_key(template, container, item):
  """Renders one key. Raises KeyError when a field is absent: a key that
  silently loses a field collapses distinct assets onto one key, which
  removes them from the denominator without removing them from the
  cloud."""

  def resolve(match):
    token = match.group(1)
    if token == 'container':
      return container
    if token == 'container_id':
      return container.split('/', 1)[1] if '/' in container else container
    value = item
    for part in token.split('.')[1:]:
      if not isinstance(value, dict) or part not in value:
        raise KeyError(token)
      value = value[part]
    if value is None or isinstance(value, (dict, list)):
      raise KeyError(token)
    return str(value)

  return _KEY_TOKEN.sub(resolve, template)


def _normalize_native(items, asset_type, container, key_template):
  """Normalizes one native sweep's JSON into inventory entries.

  `describe` commands emit an object, `list` commands an array; both are
  accepted. A key template that is not unique across the returned items
  is fatal rather than deduplicated — silently merging two assets into
  one entry is a shrunken denominator with a green gate.
  """
  if isinstance(items, dict):
    items = [items]
  if not isinstance(items, list):
    SWEEP_FAILURES.append(
        f'native enumeration for {asset_type} on {container}: expected a '
        'JSON object or array')
    return []
  out = []
  for item in items:
    if not isinstance(item, dict):
      continue
    try:
      key = _render_native_key(key_template, container, item)
    except KeyError as e:
      SWEEP_FAILURES.append(
          f'native enumeration for {asset_type} on {container}: key '
          f'template {key_template!r} references {e.args[0]!r}, absent from '
          'the returned item')
      return []
    out.append({
        'key': key,
        'asset_type': asset_type,
        'level': _level_of(container) or 'unknown',
        'container': container,
    })
  keys = {e['key'] for e in out}
  if len(keys) != len(out):
    SWEEP_FAILURES.append(
        f'native enumeration for {asset_type} on {container}: key template '
        f'{key_template!r} produced {len(keys)} distinct key(s) for '
        f'{len(out)} item(s); a non-unique key hides assets from the '
        'denominator')
    return []
  return out


def sweep_native(asset_type, spec, containers, source='manifest'):
  """Runs one type's native enumerator over every in-scope container."""
  entries = []
  for container, sweep_id in containers:
    if spec.get('container_arg'):
      container_arg = _render_native_key(spec['container_arg'], container, {})
    else:
      flag = _container_flag(container)
      if not flag:
        continue
      container_arg = f'{flag}={sweep_id}'
    cmd = (['gcloud', '--quiet'] + list(spec['command']) +
           [container_arg, '--format=json'])
    payload = run_json(cmd, ignore_errors=True, allow_disabled_service=True)
    got = _normalize_native(payload, asset_type, container, spec['key'])
    NATIVE_SWEEPS.append({
        'asset_type': asset_type,
        'source': source,
        'command': ' '.join(cmd),
        'container': container,
        'yield_count': len(got),
    })
    entries += got
  return entries


def _verify_split_parity(assets, declared_types, sibling_map, scope,
                         search_scope):
  """Checks CAI_SPLIT_TYPES against the live search surface.

  CAI_SPLIT_TYPES is a frozen snapshot of a Google doc that changes. If
  a new split appears — or an existing pairing is renamed — the table
  goes quietly incomplete, which puts us back in the failure mode it was
  added to close. This probe asks the OTHER surface, which by
  construction unifies the families, and reports anything it returns
  that the list sweep did not.

  One call per scope, restricted to declared split types, so the cost is
  bounded and does not scale with the type list. Comparison is against
  the RAW sweep output, before the manifest's subtree filters: the
  question under test is taxonomy, not scope, and mixing the two would
  make every excluded subtree look like a parity failure.
  """
  split_declared = sorted(t for t in declared_types if t in CAI_SPLIT_TYPES)
  if not split_declared:
    return
  family = set(split_declared) | set(sibling_map)
  listed = {
      a['name']
      for a in assets
      if a.get('assetType', '') in family and a.get('name')
  }
  found = run_json([
      'gcloud', '--quiet', 'asset', 'search-all-resources',
      f'--scope={search_scope}', f'--asset-types={",".join(split_declared)}',
      '--format=json', f'--page-size={CAI_SEARCH_PAGE_SIZE}'
  ], ignore_errors=True)
  searched = {r['name'] for r in found if r.get('name')}
  # Recorded even when clean: a probe that ran and found nothing is
  # evidence, and its absence from the provenance block is how a reader
  # tells "checked" from "not checked".
  SPLIT_PARITY_FINDINGS.append({
      'scope': scope,
      'asset_types': split_declared,
      'listed_count': len(listed),
      'searched_count': len(searched),
      'only_in_search': sorted(searched - listed),
  })


def validate_manifest_types(types, where='manifest'):
  """Fails closed on manifest mistakes that silently shrink the
  denominator. Called once per scope: each scope carries its own
  `types:` list, and `where` names the scope in every message.

  - An unrecognised `levels` value (e.g. `org` for `organization`) used
    to drop every entry of that type with no output at all — the exact
    silent-gap failure apply_level_filter() exists to prevent, one layer
    up (hardening round 19).
  - Duplicate `type:` entries were last-wins under a dict comprehension,
    so a copy-paste while widening scope could silently narrow levels.
  """
  seen = set()
  for t in types:
    tt = t.get('type')
    if not tt:
      raise SystemExit(f'{where} type entry without a `type:` field')
    if tt in seen:
      raise SystemExit(
          f'{where} declares type {tt!r} more than once; duplicate '
          'entries silently narrow the denominator (last one wins) — '
          'merge them into a single entry')
    seen.add(tt)
    if tt == PAM_GRANT_TYPE:
      raise SystemExit(
          f'{where} type {tt!r} is machine-managed runtime state: active '
          'PAM grants are enumerated automatically whenever IAM is '
          'collected, and their temporary bindings are stripped from the '
          'denominator (never mapped, never waived — see '
          '_meta.pam_grant_exclusions). PAM grants are never imported')
    if t.get('enumerate') is not None:
      if tt in PSEUDO_TYPES:
        raise SystemExit(
            f'{where} type {tt!r} is a pseudo-type enumerated by this tool; '
            '`enumerate` is for types CAI does not model')
      validate_native_spec(tt, t['enumerate'])
    bad = set(t.get('levels') or []) - VALID_LEVELS
    if bad:
      raise SystemExit(
          f'{where} type {tt!r} declares invalid level(s) '
          f'{sorted(bad)}; valid levels: {sorted(VALID_LEVELS)}. An '
          'unrecognised level would silently drop every entry of this '
          'type from the denominator')


def parse_and_validate_scopes(manifest, registry=None):
  """Parses and validates the manifest's `scopes` list.

  The grammar is scopes-only: `scopes:` is required and every scope
  carries its own `types:` list. The retired top-level `scope:` /
  `types:` grammar is refused with migration instructions rather than
  a bare unknown-key error — silently accepting half of it would
  change what the denominator means.
  """
  legacy = [k for k in ('scope', 'types') if k in manifest]
  if legacy:
    raise SystemExit(
        f'manifest declares retired top-level key(s) {legacy}. The '
        'grammar is scopes-only and every scope carries its own '
        "'types:' list:\n"
        '  scopes:\n'
        '    - root: organizations/<id>\n'
        '      levels: [organization, folder]\n'
        '      types:\n'
        '        - type: iam\n'
        '          levels: [organization, folder]\n'
        "Move the old top-level 'types:' entries into every scope that "
        'should collect them.')
  scopes = manifest.get('scopes')
  if not isinstance(scopes, list) or not scopes:
    raise SystemExit("manifest must declare a non-empty 'scopes' list")

  validated_scopes = []
  for i, s in enumerate(scopes):
    if not isinstance(s, dict):
      raise SystemExit(f"scope entry #{i + 1} must be a dictionary")
    root = s.get('root', '')
    if not root:
      raise SystemExit(
          f"scope entry #{i + 1} missing required 'root' attribute")
    if '/' not in root:
      # If bare project ID or number given as root
      root = f'projects/{root}'
    kind = root.split('/')[0]
    if kind not in ('organizations', 'folders', 'projects'):
      raise SystemExit(f"unsupported scope root in scope #{i + 1}: {root!r}")

    # Eagerly register root if project
    if kind == 'projects' and registry:
      registry.resolve(root.split('/', 1)[1])

    # Validate include/exclude BEFORE expanding. Anything without a
    # recognised prefix was silently coerced to a project, so `exclude:
    # [12345]` meaning folder 12345 became projects/12345, matched
    # nothing, and the exclusion no-oped with exit 0; the same typo in
    # `include` emptied the denominator just as quietly.
    for field in ('include', 'exclude'):
      for item in s.get(field) or []:
        text = str(item).strip()
        if not text:
          raise SystemExit(f"scope #{i + 1} has an empty {field} entry")
        if '/' in text:
          prefix = text.split('/')[0]
          if prefix not in ('organizations', 'folders', 'projects'):
            raise SystemExit(
                f"scope #{i + 1} {field} entry {text!r} has an "
                f"unsupported prefix {prefix!r}; use organizations/<id>, "
                "folders/<id>, projects/<id-or-number>, or a bare "
                "project id")
        elif text.isdigit():
          raise SystemExit(
              f"scope #{i + 1} {field} entry {text!r} is a bare number, "
              "which is ambiguous: it was read as a project. Write "
              f"folders/{text} or projects/{text} explicitly.")

    # Eagerly register include/exclude items if projects
    if registry:
      for inc in s.get('include') or []:
        registry.expand_target(inc)
      for exc in s.get('exclude') or []:
        registry.expand_target(exc)

    scope_levels = set(s.get('levels') or VALID_LEVELS)
    bad_levels = scope_levels - VALID_LEVELS
    if bad_levels:
      raise SystemExit(
          f"scope #{i + 1} declares invalid level(s) {sorted(bad_levels)}; "
          f"valid levels: {sorted(VALID_LEVELS)}")

    name = s.get('name', f'scope-{i + 1}')
    label = f'#{i + 1} ({name!r})'
    if 'types' not in s:
      raise SystemExit(
          f"scope {label} declares no 'types' list. Every scope carries "
          'its own list — a scope without one would collect nothing '
          'while reading as in scope')
    scope_types = s['types']
    if not isinstance(scope_types, list) or not scope_types:
      raise SystemExit(
          f"scope {label} has an empty or non-list 'types'. An empty "
          'list is a scope that collects nothing, and that is the one '
          'thing no scope may say quietly — delete the scope or declare '
          'what it collects')
    validate_manifest_types(scope_types, where=f'scope {label}')
    for t in scope_types:
      t_levels = set(t.get('levels') or ('organization', 'folder', 'project'))
      if 'unknown' in t_levels or t_levels & scope_levels:
        continue
      raise SystemExit(
          f'scope {label} declares type {t["type"]!r} at levels '
          f'{sorted(t_levels)} but its own levels are '
          f'{sorted(scope_levels)}: the declaration can never match an '
          'asset. A per-scope entry that cannot fire reads as coverage '
          'and produces none — fix the levels or remove the entry')

    validated_scopes.append({
        'name': name,
        'root': root,
        'include': s.get('include') or [],
        'exclude': s.get('exclude') or [],
        'levels': scope_levels,
        'types': scope_types,
    })
  return validated_scopes


def api_call_summary():
  """One line of cost accounting: how many commands ran, how long they
  took, and which family they belonged to.

  A gcloud invocation is one or more HTTP requests — it pages until the
  results run out — so this counts commands, not requests. With
  `--page-size` at the API maximum, the two are equal for any scope
  under 1000 assets of a type and diverge slowly above it.
  """
  by_family = {}
  for call in API_CALLS:
    parts = call['command'].split()
    family = ' '.join(p for p in parts[1:4] if not p.startswith('-'))
    by_family[family] = by_family.get(family, 0) + 1
  seconds = sum(c.get('seconds', 0) for c in API_CALLS)
  failed = sum(1 for c in API_CALLS if c['outcome'] not in ('ok', 'unknown'))
  families = ', '.join(f'{k} x{v}' for k, v in sorted(by_family.items()))
  return (f'{len(API_CALLS)} gcloud call(s) in {seconds:.1f}s'
          f'{f", {failed} not ok" if failed else ""}: {families}')


def collect(manifest, include_deleted=False, include_auto_generated=None,
            include_logging_defaults=False, include_pam_grants=False,
            verify_search_parity=False):
  # Module-level accumulators: reset so a second collect() in the same
  # process cannot inherit the first run's failures (or hide behind
  # them).
  del SWEEP_FAILURES[:]
  del SUPPRESSED_SWEEPS[:]
  del UNSUPPORTED_CAI_TYPES[:]
  del NATIVE_SWEEPS[:]
  del SPLIT_TYPE_SWEEPS[:]
  del SPLIT_PARITY_FINDINGS[:]
  del API_CALLS[:]
  del PAM_EXCLUSIONS[:]
  del AUTO_GENERATED_EXCLUSIONS[:]
  included_auto_generated = _resolve_included_auto_generated(
      include_auto_generated, include_logging_defaults=include_logging_defaults,
      include_pam_grants=include_pam_grants)
  registry = ProjectRegistry()
  scopes = parse_and_validate_scopes(manifest, registry)

  # Every scope carries its own `types:` list, so every type-derived
  # structure (levels, leaf-IAM opt-ins, native enumerators) is resolved
  # per scope inside the loop below. Built-in native-enumerator notices
  # are printed once here, for the union across scopes.
  builtin_native = sorted({
      t['type']
      for s in scopes
      for t in s['types']
      if t['type'] in NATIVE_ENUMERATORS and t['type'] not in PSEUDO_TYPES and
      not t.get('enumerate')
  })
  for t in builtin_native:
    print(
        f'NOTICE: {t} is not modelled by Cloud Asset Inventory; using '
        'the built-in gcloud\nenumerator. It stays in the denominator '
        'and must be mapped or waived like any other asset.', file=sys.stderr)

  all_entries = []
  scope_summaries = []
  excluded_defaults_count = 0
  excluded_pam_grants_count = 0

  for s in scopes:
    root = s['root']
    scope_levels = s['levels']
    include = s['include']
    exclude = s['exclude']
    types = s['types']

    # This scope's type-derived structures. A scope's list REPLACES any
    # other scope's — there is no manifest-global list to fall back to.
    manifest_levels_by_type = {
        t['type']: set(
            t.get('levels') or
            ['organization', 'folder', 'project']) for t in types
    }
    iam_types = {
        t['type']
        for t in types
        if t.get('iam') and t.get('type') not in PSEUDO_TYPES
    }
    # Types this scope enumerates natively are never sent to CAI: that
    # is the whole point of declaring one. Built-in enumerators apply
    # automatically; a manifest block overrides one for the same type,
    # in the scope that declares it.
    declared = {t['type'] for t in types}
    native_specs = {
        t: dict(spec)
        for t, spec in NATIVE_ENUMERATORS.items()
        if t in declared and t not in PSEUDO_TYPES
    }
    native_sources = {t: 'builtin' for t in native_specs}
    for t in types:
      if t.get('enumerate'):
        native_specs[t['type']] = t['enumerate']
        native_sources[t['type']] = 'manifest'

    scope_flag = {
        'organizations': '--organization',
        'folders': '--folder',
        'projects': '--project',
    }.get(root.split('/')[0])
    scope_arg = f'{scope_flag}={root.split("/", 1)[1]}'

    # Effective levels for this scope
    effective_levels_by_type = {
        t: (levels & scope_levels)
        for t, levels in manifest_levels_by_type.items()
    }
    # Keep types that have at least one valid level in this scope (or unknown)
    active_resource_types = sorted({
        t['type'] for t in types if t.get('type') not in PSEUDO_TYPES and
        t['type'] not in native_specs and (effective_levels_by_type[
            t['type']] or 'unknown' in manifest_levels_by_type[t['type']])
    })

    # CAI's list surface splits some Compute families by scope into
    # separate asset types that its search surface unifies (see
    # CAI_SPLIT_TYPES). Declaring the unified type must sweep the
    # siblings too, or the split-off assets never enter the denominator
    # and are invisible to BOTH gates.
    sibling_map = split_sibling_map(active_resource_types)
    sweep_resource_types = sorted(set(active_resource_types) | set(sibling_map))

    scope_entries = []

    # In-scope containers at a given set of levels, resolved once per
    # (scope, levels) and shared by the org-policy sweep and every
    # native enumerator.
    container_cache = {}

    def containers_for(levels, _cache=container_cache, _scope_arg=scope_arg,
                       _root=root, _include=include, _exclude=exclude):
      ck = tuple(sorted(levels))
      if ck in _cache:
        return _cache[ck]
      out = []
      if 'organization' in levels and _root.startswith('organizations/'):
        out.append((_root, _root.split('/', 1)[1]))
      cont_asset_types = []
      if 'folder' in levels:
        cont_asset_types.append('cloudresourcemanager.googleapis.com/Folder')
      if 'project' in levels:
        cont_asset_types.append('cloudresourcemanager.googleapis.com/Project')
      if cont_asset_types:
        cont_assets = run_gcloud_json([
            _scope_arg, '--content-type=resource',
            f'--asset-types={",".join(cont_asset_types)}'
        ])
        registry.ingest_assets(cont_assets)
        for a in cont_assets:
          if not include_deleted and _is_deleted_container(a):
            continue
          if in_subtree(a, _include, _exclude, registry):
            c_path = a['name'].removeprefix(
                '//cloudresourcemanager.googleapis.com/')
            if a.get(
                'assetType') == 'cloudresourcemanager.googleapis.com/Project':
              pid = a.get('resource', {}).get(
                  'data', {}).get('projectId') or c_path.split('/', 1)[1]
              out.append((c_path, pid))
            else:
              out.append((c_path, c_path.split('/', 1)[1]))
      _cache[ck] = out
      return out

    search_scope = scope_arg.replace(
        '--organization=',
        'organizations/').replace('--folder=',
                                  'folders/').replace('--project=', 'projects/')

    if sweep_resource_types:
      try:
        assets = run_gcloud_json([
            scope_arg, '--content-type=resource',
            f'--asset-types={",".join(sweep_resource_types)}'
        ])
      except SystemExit:
        assets = []
        for rt in sweep_resource_types:
          try:
            assets += run_gcloud_json(
                [scope_arg, '--content-type=resource', f'--asset-types={rt}'])
          except SystemExit as e:
            if _is_unsupported_type_error(str(e)):
              # Not a permission problem and not retryable: CAI does not
              # model this type at all. `search-all-resources` would
              # fail identically, so skip it and raise the real issue —
              # the type needs a native enumerator.
              #
              # A SIBLING is tool-supplied, not operator-declared, so it
              # is not fatal: CAI retiring a split type is exactly the
              # convergence CAI_SPLIT_TYPES is waiting for. It is still
              # reported, because a stale frozen table is a fact about
              # the denominator.
              if rt in sibling_map:
                msg = (f'{rt} (list-surface sibling of '
                       f'{sibling_map[rt]}) is no longer a CAI type; '
                       'CAI_SPLIT_TYPES may be stale')
                if msg not in SUPPRESSED_SWEEPS:
                  SUPPRESSED_SWEEPS.append(msg)
              elif rt not in UNSUPPORTED_CAI_TYPES:
                UNSUPPORTED_CAI_TYPES.append(rt)
              continue
            assets += run_json([
                'gcloud', '--quiet', 'asset', 'search-all-resources',
                f'--scope={search_scope}', f'--asset-types={rt}',
                '--format=json', f'--page-size={CAI_SEARCH_PAGE_SIZE}'
            ], ignore_errors=True)
      registry.ingest_assets(assets)
      # Account split-off siblings under the DECLARED type, before the
      # level filter (which keys off asset_type) ever sees them.
      for unified, per_sibling in sorted(
          retype_split_assets(assets, sibling_map).items()):
        for sibling, n in sorted(per_sibling.items()):
          SPLIT_TYPE_SWEEPS.append({
              'declared_type': unified,
              'cai_list_type': sibling,
              'scope': root,
              'swept_count': n,
          })
      if verify_search_parity:
        _verify_split_parity(assets, active_resource_types, sibling_map, root,
                             search_scope)
      filtered_res = []
      for a in assets:
        if not include_deleted and (_is_deleted_container(a) or
                                    _has_deleted_ancestor(
                                        a, registry.deleted_containers)):
          continue
        matched_filter = None
        for family, predicate, reason in AUTO_GENERATED_FILTERS:
          if family not in included_auto_generated and predicate(a):
            matched_filter = (family, reason)
            break
        if matched_filter:
          fam, reason = matched_filter
          key = a.get('name', '') or a.get('key', '')
          atype = a.get('assetType', '') or a.get('asset_type', '')
          AUTO_GENERATED_EXCLUSIONS.append({
              'key': key,
              'asset_type': atype,
              'family': fam,
              'reason': reason,
          })
          continue
        if in_subtree(a, include, exclude, registry):
          filtered_res.append(a)
      scope_entries += _normalize_resources(filtered_res)

    if ('iam' in effective_levels_by_type and
        effective_levels_by_type['iam']) or iam_types:
      raw_iam_assets = run_gcloud_json([scope_arg, '--content-type=iam-policy'])
      assets = []
      for a in raw_iam_assets:
        if not include_deleted and _has_deleted_ancestor(
            a, registry.deleted_containers):
          continue
        matched_filter = None
        for family, predicate, reason in AUTO_GENERATED_FILTERS:
          if family not in included_auto_generated and predicate(a):
            matched_filter = (family, reason)
            break
        if matched_filter:
          fam, reason = matched_filter
          key = a.get('name', '') or a.get('key', '')
          atype = a.get('assetType', '') or a.get('asset_type', '')
          AUTO_GENERATED_EXCLUSIONS.append({
              'key': key,
              'asset_type': atype,
              'family': fam,
              'reason': reason,
          })
          continue
        if in_subtree(a, include, exclude, registry):
          assets.append(a)
      registry.ingest_assets(assets)
      # Active PAM grants are ALWAYS enumerated alongside IAM (one CAI
      # call per scope, covered by the same cloudasset.viewer grant) so
      # their machine-managed temporary bindings can be deterministically
      # stripped before normalization. A failure of this sweep is fatal
      # like any other enumeration failure: an invisible grant would put
      # a machine-managed binding back into the denominator.
      pam_records = _pam_grant_records(
          run_gcloud_json([
              scope_arg, '--content-type=resource',
              f'--asset-types={PAM_GRANT_TYPE}'
          ]), registry)
      if pam_records:
        _strip_pam_grant_bindings(assets, pam_records)
      if 'iam' in effective_levels_by_type and effective_levels_by_type['iam']:
        scope_entries += _normalize_iam(assets)
      if iam_types:
        scope_entries += _normalize_leaf_iam(assets, iam_types)

    if 'org-policy' in effective_levels_by_type and effective_levels_by_type[
        'org-policy']:
      assets = run_gcloud_json([scope_arg, '--content-type=org-policy'])
      scope_entries += _normalize_org_policies(
          a for a in assets
          if (include_deleted or
              not _has_deleted_ancestor(a, registry.deleted_containers)) and
          in_subtree(a, include, exclude, registry))
      pol_assets = run_gcloud_json([
          scope_arg, '--content-type=resource',
          '--asset-types=orgpolicy.googleapis.com/Policy'
      ])
      scope_entries += _normalize_org_policies_from_resources(
          a for a in pol_assets
          if (include_deleted or
              not _has_deleted_ancestor(a, registry.deleted_containers)) and
          in_subtree(a, include, exclude, registry))

      for container, sweep_id in containers_for(
          effective_levels_by_type['org-policy']):
        flag = _container_flag(container)
        if not flag:
          continue
        scope_entries += _normalize_org_policies_from_service(
            run_json([
                'gcloud', '--quiet', 'org-policies', 'list',
                f'{flag}={sweep_id}', '--format=json'
            ], ignore_errors=True, allow_disabled_service=True),
            container=container)

    # Natively enumerated types: everything CAI does not model. Same
    # denominator, different source.
    for atype, spec in sorted(native_specs.items()):
      levels = effective_levels_by_type.get(atype) or set()
      if not levels:
        continue
      scope_entries += sweep_native(atype, spec, containers_for(levels),
                                    source=native_sources.get(atype))

    # Filter this scope's entries by its effective levels
    scope_entries = apply_level_filter(scope_entries, effective_levels_by_type,
                                       report=False)
    # Stamp provenance: which scope collected the entry. Overlapping
    # scopes are merged at dedupe time into a sorted list, so the field
    # is honest about multiple collectors instead of last-wins.
    for e in scope_entries:
      e['scopes'] = [s['name']]
    # Per-scope yield table. The aggregate table alone cannot show a
    # type that yields zero in one scope and non-zero in another — the
    # exact shape of a type declared in the wrong scope.
    uniq = {e['key']: e['asset_type'] for e in scope_entries}
    declared_list = [t['type'] for t in types]
    per_type = {d: 0 for d in declared_list}
    for at in uniq.values():
      if at in per_type:
        per_type[at] += 1
    scope_summaries.append({
        'name': s['name'],
        'root': root,
        'levels': sorted(scope_levels),
        'yield_count': len(uniq),
        'declared_types': per_type,
        'zero_yield_types': [d for d in declared_list if per_type[d] == 0],
    })
    all_entries += scope_entries

  # Dedupe merged streams across all scopes, merging scope attribution:
  # an asset that two scopes both collect names both, deterministically.
  merged = {}
  for e in all_entries:
    prev = merged.get(e['key'])
    if prev is None:
      merged[e['key']] = e
    else:
      for n in e.get('scopes', []):
        if n not in prev.setdefault('scopes', []):
          prev['scopes'].append(n)
  entries = list(merged.values())
  for e in entries:
    e['scopes'] = sorted(e.get('scopes', []))
  entries.sort(key=lambda e: e['key'])

  print(f'\n{api_call_summary()}', file=sys.stderr)

  if registry.deleted_containers and not include_deleted:
    print(
        f'\nNOTICE: excluded {len(registry.deleted_containers)} soft-deleted / pending-deletion container(s) and their child resources.',
        file=sys.stderr)
    print('Use --include-deleted to retain them in the denominator.',
          file=sys.stderr)

  if PAM_EXCLUSIONS:
    print(
        f'\nNOTICE: stripped {len(PAM_EXCLUSIONS)} active PAM grant '
        'binding(s) from the IAM denominator (machine-managed runtime '
        'state; never mapped, never waived). Details in '
        '_meta.pam_grant_exclusions.', file=sys.stderr)

  if AUTO_GENERATED_EXCLUSIONS:
    by_family = {}
    for excl in AUTO_GENERATED_EXCLUSIONS:
      by_family.setdefault(excl['family'], []).append(excl)
    total_excl = len(AUTO_GENERATED_EXCLUSIONS)
    print(
        f'\nNOTICE: excluded {total_excl} auto-generated / default asset(s) from the denominator:',
        file=sys.stderr)
    for fam, items in sorted(by_family.items()):
      reason = items[0].get('reason', fam)
      print(f'  - {fam}: {len(items)} asset(s) ({reason})', file=sys.stderr)
    print(
        'Use --include-auto-generated (or --include-auto-generated=<family>) '
        'to retain them in the denominator.', file=sys.stderr)

  if NATIVE_SWEEPS:
    by_type = {}
    for sw in NATIVE_SWEEPS:
      agg = by_type.setdefault(sw['asset_type'], {
          'containers': 0,
          'yield_count': 0
      })
      agg['containers'] += 1
      agg['yield_count'] += sw['yield_count']
    print(
        f'\nNOTICE: {len(by_type)} type(s) were enumerated natively '
        '(outside Cloud Asset Inventory). They are IN the denominator '
        'and must be\nmapped or waived like any other asset; name the '
        'command in the run report:', file=sys.stderr)
    for t, agg in sorted(by_type.items()):
      print(
          f'  - {t}: {agg["yield_count"]} entr(ies) over '
          f'{agg["containers"]} container(s)', file=sys.stderr)

  if SPLIT_TYPE_SWEEPS:
    by_declared = {}
    for sw in SPLIT_TYPE_SWEEPS:
      agg = by_declared.setdefault(sw['declared_type'], {})
      agg[sw['cai_list_type']] = (agg.get(sw['cai_list_type'], 0) +
                                  sw['swept_count'])
    # Swept and in-the-denominator are DIFFERENT numbers: the sweep is
    # raw, and the subtree/deleted/level filters apply to retyped
    # entries like to any other asset. Reconcile the two here rather
    # than leaving the subtraction to the reader (a live validation run
    # had to do exactly that by hand).
    in_denom = {}
    for e in entries:
      lt = e.get('cai_list_type')
      if lt:
        key = (e['asset_type'], lt)
        in_denom[key] = in_denom.get(key, 0) + 1
    print(
        f'\nNOTICE: {len(by_declared)} declared type(s) are split by '
        "scope in Cloud Asset Inventory's list surface but\nunified in "
        'its search surface. The list-only sibling type(s) were swept '
        'too and are\naccounted under the declared type; the ones in '
        'scope are IN the denominator and\nmust be mapped or waived '
        'like any other asset (details in _meta.split_type_sweeps):',
        file=sys.stderr)
    for t, agg in sorted(by_declared.items()):
      for sibling, n in sorted(agg.items()):
        kept = in_denom.get((t, sibling), 0)
        excluded = ('' if kept == n else
                    f' ({n - kept} excluded by scope/level/deleted filters)')
        print(
            f'  - {t}: {n} swept from {sibling}, {kept} in the '
            f'denominator{excluded}', file=sys.stderr)
    if not SPLIT_PARITY_FINDINGS:
      print(
          'The split-type table is a frozen snapshot of a Google doc '
          'that changes. Pass\n--verify-search-parity to check it '
          'against the live search surface (one extra call\nper scope).',
          file=sys.stderr)

  parity_gaps = [f for f in SPLIT_PARITY_FINDINGS if f['only_in_search']]
  if parity_gaps:
    total = sum(len(f['only_in_search']) for f in parity_gaps)
    print(
        f'\nERROR: --verify-search-parity found {total} asset(s) that '
        "Cloud Asset Inventory's search\nsurface returns and the list "
        'sweep did not. The frozen split-type table is stale '
        'against\nlive CAI, so the denominator is INCOMPLETE and cannot '
        'be trusted:', file=sys.stderr)
    for f in parity_gaps:
      print(
          f'  - scope {f["scope"]}: listed {f["listed_count"]}, '
          f'searched {f["searched_count"]}', file=sys.stderr)
      for name in f['only_in_search'][:10]:
        print(f'      {name}', file=sys.stderr)
      if len(f['only_in_search']) > 10:
        print(f'      ... and {len(f["only_in_search"]) - 10} more',
              file=sys.stderr)
    print(
        'Identify the list-surface asset type of the missing asset(s) '
        '(`gcloud asset list` with\nno --asset-types, then match on '
        'name) and report it: CAI_SPLIT_TYPES needs a new\nentry, which '
        'is a reviewed change to a frozen file. Never proceed on a '
        'partial\ndenominator.', file=sys.stderr)
    raise SystemExit(3)

  if UNSUPPORTED_CAI_TYPES:
    print(
        f'\nERROR: {len(UNSUPPORTED_CAI_TYPES)} declared type(s) are not '
        'modelled by Cloud Asset Inventory:', file=sys.stderr)
    for t in UNSUPPORTED_CAI_TYPES:
      print(f'  - {t}', file=sys.stderr)
    print(
        'CAI is the DEFAULT source of the denominator, not its boundary. '
        'A type CAI does not\nsupport is retrieved by other means — '
        '`gcloud` first — and merged into the same\ndenominator; it is '
        'never dropped, because an unenumerated asset is invisible to '
        'BOTH\ngates at once. No built-in enumerator covers the type(s) '
        'above, so this needs a\ndecision. Do one of:\n'
        '  1. check the type string against\n'
        '     https://cloud.google.com/asset-inventory/docs/'
        'supported-asset-types\n'
        '     (a wrong spelling is the common cause — e.g. CAI calls the '
        'Logs Router\n'
        '     settings singleton logging.googleapis.com/Settings, not '
        '.../OrganizationSettings);\n'
        '  2. give the type a native enumerator in the manifest:\n'
        '       - type: <type>\n'
        '         levels: [organization]\n'
        '         enumerate:\n'
        '           command: [<read-only gcloud command>]   # no leading '
        '`gcloud`\n'
        "           key: '//<service>/{item.name}'\n"
        '     see references/cai-blind-spots.md;\n'
        '  3. drop the type from the manifest and record the gap in a '
        'signed waiver and\n     in the run report — deliberately, never '
        'silently.\n'
        'Never proceed on a partial denominator.', file=sys.stderr)
    raise SystemExit(3)

  if SUPPRESSED_SWEEPS:
    print(
        f'\nWARNING: {len(SUPPRESSED_SWEEPS)} sweep(s) were skipped as '
        'disabled-service. A disabled API and a permissions or '
        'quota-project error can produce the same message, so confirm '
        'each one is genuinely a disabled service:', file=sys.stderr)
    for m in SUPPRESSED_SWEEPS:
      print(f'  - {m}', file=sys.stderr)

  if SWEEP_FAILURES:
    print(
        f'\nERROR: {len(SWEEP_FAILURES)} enumeration failure(s) were '
        'tolerated during collection; the denominator may be '
        'incomplete and CANNOT be trusted:', file=sys.stderr)
    for m in SWEEP_FAILURES:
      print(f'  - {m}', file=sys.stderr)
    print(
        'Fix permissions/types or narrow scope; never proceed on a '
        'partial denominator.', file=sys.stderr)
    raise SystemExit(3)

  return entries, registry, scope_summaries


def survey(scope_root, include_deleted=False, include_auto_generated=None,
           include_logging_defaults=False, include_pam_grants=False):
  if '/' not in scope_root:
    scope_root = f'projects/{scope_root}'
  scope_flag = {
      'organizations': '--organization',
      'folders': '--folder',
      'projects': '--project',
  }.get(scope_root.split('/')[0])
  if not scope_flag:
    raise SystemExit(f'unsupported scope: {scope_root!r}')
  assets = run_gcloud_json([
      f'{scope_flag}={scope_root.split("/", 1)[1]}', '--content-type=resource'
  ])
  registry = ProjectRegistry()
  registry.ingest_assets(assets)
  included_auto_generated = _resolve_included_auto_generated(
      include_auto_generated, include_logging_defaults=include_logging_defaults,
      include_pam_grants=include_pam_grants)
  if not include_deleted:
    assets = [
        a for a in assets if not _is_deleted_container(a) and
        not _has_deleted_ancestor(a, registry.deleted_containers)
    ]
  filtered = []
  for a in assets:
    if any(family not in included_auto_generated and predicate(a)
           for family, predicate, _ in AUTO_GENERATED_FILTERS):
      continue
    filtered.append(a)
  return _normalize_resources(filtered)


def main():
  global VERBOSE
  p = argparse.ArgumentParser(description=__doc__)
  # Shared by both subcommands. The flag goes AFTER the subcommand
  # (`collect --verbose`): declaring it on the top-level parser too
  # would let argparse's subparser default silently overwrite it.
  common = argparse.ArgumentParser(add_help=False)
  common.add_argument(
      '-v', '--verbose', action='store_true',
      help='print every gcloud command as it runs, with its outcome, '
      'duration and item count. The same log is always written to '
      "the output file's _meta.api_calls regardless of this flag")
  common.add_argument(
      '--include-deleted', action='store_true', help=
      'include soft-deleted / pending-deletion folders and projects (default: active only)'
  )
  common.add_argument(
      '--include-auto-generated',
      nargs='?',
      const=True,
      default=None,
      help=
      'include auto-generated / default assets in denominator (all, or comma-separated family names: logging-defaults,pam-grants,routes)',
  )
  common.add_argument(
      '--include-logging-defaults',
      action='store_true',
      help='alias for --include-auto-generated=logging-defaults',
  )
  common.add_argument(
      '--include-pam-grants',
      action='store_true',
      help='alias for --include-auto-generated=pam-grants',
  )
  sub = p.add_subparsers(dest='mode', required=True)
  ps = sub.add_parser('survey', parents=[common])
  ps.add_argument('--scope', required=True,
                  help='e.g. organizations/123, folders/456')
  ps.add_argument('--out', default='-')
  pc = sub.add_parser('collect', parents=[common])
  pc.add_argument('--manifest', required=True)
  pc.add_argument('--out', default='-')
  pc.add_argument(
      '--verify-search-parity', action='store_true',
      help="check the frozen split-type table against Cloud Asset Inventory's "
      'search surface (one extra call per scope). Fails the run if search '
      'returns an asset the list sweep did not — i.e. if CAI_SPLIT_TYPES '
      'has gone stale')
  args = p.parse_args()
  VERBOSE = args.verbose

  if args.mode == 'survey':
    kwargs = {}
    if args.include_deleted:
      kwargs['include_deleted'] = True
    if args.include_auto_generated is not None:
      kwargs['include_auto_generated'] = args.include_auto_generated
    if args.include_logging_defaults:
      kwargs['include_logging_defaults'] = True
    if args.include_pam_grants:
      kwargs['include_pam_grants'] = True
    entries = survey(args.scope, **kwargs)
    payload = json.dumps(entries, indent=2)
  else:
    with open(args.manifest, 'rb') as f:
      manifest_raw = f.read()
    manifest = yaml.safe_load(manifest_raw)
    kwargs = {}
    if args.include_deleted:
      kwargs['include_deleted'] = True
    if args.include_auto_generated is not None:
      kwargs['include_auto_generated'] = args.include_auto_generated
    if args.include_logging_defaults:
      kwargs['include_logging_defaults'] = True
    if args.include_pam_grants:
      kwargs['include_pam_grants'] = True
    if args.verify_search_parity:
      kwargs['verify_search_parity'] = True
    entries, registry, scope_summaries = collect(manifest, **kwargs)

    # Per-declared-type yield table: aggregate across scopes, then per
    # scope. With per-scope type lists the aggregate alone can hide a
    # scope whose own declaration yielded nothing.
    declared = sorted(
        {d for ss in scope_summaries for d in ss.get('declared_types', {})})
    type_counts = {
        d: sum(1 for e in entries if e['asset_type'] == d) for d in declared
    }
    print('\nper-declared-type yield (all scopes):', file=sys.stderr)
    for d in declared:
      print(f'  {d}: {type_counts[d]}', file=sys.stderr)
    zero_yield = [d for d in declared if type_counts[d] == 0]
    if zero_yield:
      print(
          '\nWARNING: declared type(s) yielded ZERO entries in every '
          'scope that declares\nthem. Confirm each type string against '
          'live `gcloud asset list` output\n(a mistyped asset type '
          'matches nothing and exits 0):', file=sys.stderr)
      for d in zero_yield:
        print(f'  - {d}', file=sys.stderr)
    for ss in scope_summaries:
      hidden = [
          d for d in ss.get('zero_yield_types', []) if d not in zero_yield
      ]
      if hidden:
        print(
            f'\nWARNING: scope {ss["name"]!r} declared type(s) that '
            'yielded ZERO entries in\nthat scope. The aggregate table '
            'above cannot show this (the type is\nnon-zero elsewhere); '
            'confirm the declaration belongs in this scope:', file=sys.stderr)
        for d in hidden:
          print(f'  - {d}', file=sys.stderr)

    # Provenance metadata
    payload = json.dumps(
        {
            '_meta': {
                'manifest':
                    integrity.display_path(args.manifest),
                'manifest_sha256':
                    hashlib.sha256(manifest_raw).hexdigest(),
                'generated':
                    datetime.datetime.now(datetime.timezone.utc
                                         ).isoformat(timespec='seconds'),
                'tool_digest':
                    integrity.frozen_digest(),
                'declared_types':
                    type_counts,
                'zero_yield_types':
                    zero_yield,
                'suppressed_sweeps':
                    list(SUPPRESSED_SWEEPS),
                # Which part of the denominator did NOT come from CAI,
                # and the exact command that produced it. A reviewer can
                # re-run these by hand.
                'native_sweeps':
                    list(NATIVE_SWEEPS),
                # Entries that entered the denominator because a
                # declared type is split by scope in CAI's list surface
                # (see CAI_SPLIT_TYPES). They are accounted under the
                # declared type, so this block is the only place the
                # list-surface type they were actually returned as is
                # aggregated.
                'split_type_sweeps':
                    list(SPLIT_TYPE_SWEEPS),
                # Result of --verify-search-parity. EMPTY means the
                # probe did not run, which is not the same as clean: a
                # probe that ran and found nothing appears here as a
                # record whose `only_in_search` is empty. Read the
                # record, not the key.
                'split_parity':
                    list(SPLIT_PARITY_FINDINGS),
                # Every command this collection ran, in order, with its
                # outcome and duration. Makes the cost of a scope
                # auditable after the fact, and a slow or failing sweep
                # attributable to a command rather than to a feeling.
                'api_calls':
                    list(API_CALLS),
                'api_call_summary':
                    api_call_summary(),
                'scopes':
                    scope_summaries,
                # Machine-managed PAM grant bindings stripped from the
                # denominator before normalization: the deterministic
                # exclusion artifact step 3 works from, and the reviewer
                # re-checks. These are structurally exempt, not waived.
                'pam_grant_exclusions':
                    list(PAM_EXCLUSIONS),
                'auto_generated_exclusions':
                    list(AUTO_GENERATED_EXCLUSIONS),
                'resolved_projects':
                    registry.id_to_num,
                'excluded_deleted_containers':
                    sorted(list(registry.deleted_containers)),
            },
            'assets': entries,
        },
        indent=2)
  if args.out == '-':
    print(payload)
  else:
    with open(args.out, 'w', encoding='utf-8') as f:
      f.write(payload + '\n')
    print(f'wrote {len(entries)} inventory entries to {args.out}',
          file=sys.stderr)


if __name__ == '__main__':
  main()
