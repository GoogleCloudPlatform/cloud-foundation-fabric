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

All gcloud interaction is read-only (`gcloud asset list`). Requires
roles/cloudasset.viewer on the scope (see SKILL.md).
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys

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

import shutil


def run_json(cmd, ignore_errors=False, allow_disabled_service=False,
             timeout=300):
  executable = shutil.which(cmd[0]) or cmd[0]
  resolved_cmd = [executable] + cmd[1:]
  env = dict(os.environ, CLOUDSDK_CORE_DISABLE_PROMPTS='1')
  try:
    # encoding is pinned: gcloud always emits UTF-8, but `text=True`
    # decodes with the process locale, so a non-ASCII display name blew
    # up with UnicodeDecodeError under a non-UTF-8 LANG.
    res = subprocess.run(resolved_cmd, capture_output=True, text=True,
                         encoding='utf-8', errors='replace', env=env,
                         timeout=timeout)
  except FileNotFoundError:
    if ignore_errors:
      msg = f'{" ".join(cmd)}: executable not found in PATH'
      SWEEP_FAILURES.append(msg)
      return []
    raise SystemExit(f"ERROR: executable '{cmd[0]}' not found in PATH")
  except subprocess.TimeoutExpired:
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
      print(f'WARNING: sweep suppressed as disabled-service: {msg}',
            file=sys.stderr)
      return []
    if ignore_errors:
      err_line = stderr.splitlines()[-1] if stderr else "unknown error"
      msg = f'{" ".join(cmd)}: {err_line}'
      SWEEP_FAILURES.append(msg)
      print(f'WARNING: enumeration failure (recorded): {msg}', file=sys.stderr)
      return []
    raise SystemExit(f'command failed: {" ".join(cmd)}\n{stderr}')
  return json.loads(res.stdout) if res.stdout.strip() else []


def run_gcloud_json(args):
  return run_json(['gcloud', '--quiet', 'asset', 'list', '--format=json'] +
                  args)


class ProjectRegistry:
  """Maintains bidirectional mapping between Project IDs and Project Numbers."""

  def __init__(self):
    self.id_to_num = {}
    self.num_to_id = {}
    self._unresolvable = set()

  def register(self, num, pid):
    if num:
      num_str = str(num).removeprefix('projects/').strip()
      if pid:
        pid_str = str(pid).removeprefix('projects/').strip()
        self.id_to_num[pid_str] = num_str
        self.num_to_id[num_str] = pid_str

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
            '--format=json(projectNumber,projectId)'
        ]
        out = run_json(cmd, ignore_errors=True, timeout=30)
        if isinstance(out, dict) and out.get('projectNumber'):
          num = str(out['projectNumber'])
          pid = str(out.get('projectId', pid))
          self.register(num, pid)
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
    """Ingests Project resource assets into registry."""
    for a in assets:
      t = a.get('assetType', '')
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
          self.register(p_num, pid)


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
    out.append({
        'key': a['name'],
        'asset_type': a.get('assetType', ''),
        'level': asset_level(a),
        'container': c,
    })
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


def validate_manifest_types(types):
  """Fails closed on manifest mistakes that silently shrink the
  denominator.

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
      raise SystemExit('manifest type entry without a `type:` field')
    if tt in seen:
      raise SystemExit(
          f'manifest declares type {tt!r} more than once; duplicate '
          'entries silently narrow the denominator (last one wins) — '
          'merge them into a single entry')
    seen.add(tt)
    bad = set(t.get('levels') or []) - VALID_LEVELS
    if bad:
      raise SystemExit(
          f'manifest type {tt!r} declares invalid level(s) '
          f'{sorted(bad)}; valid levels: {sorted(VALID_LEVELS)}. An '
          'unrecognised level would silently drop every entry of this '
          'type from the denominator')


def parse_and_validate_scopes(manifest, registry=None):
  """Parses single or multiple scopes from manifest and validates them."""
  if 'scopes' in manifest:
    scopes = manifest['scopes']
    if not isinstance(scopes, list) or not scopes:
      raise SystemExit("manifest 'scopes' must be a non-empty list")
  elif 'scope' in manifest:
    scopes = [manifest['scope']]
  else:
    raise SystemExit("manifest must declare either 'scope' or 'scopes'")

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

    validated_scopes.append({
        'name': s.get('name', f'scope-{i + 1}'),
        'root': root,
        'include': s.get('include') or [],
        'exclude': s.get('exclude') or [],
        'levels': scope_levels,
    })
  return validated_scopes


def collect(manifest):
  # Module-level accumulators: reset so a second collect() in the same
  # process cannot inherit the first run's failures (or hide behind
  # them).
  del SWEEP_FAILURES[:]
  del SUPPRESSED_SWEEPS[:]
  registry = ProjectRegistry()
  scopes = parse_and_validate_scopes(manifest, registry)
  types = manifest.get('types') or []
  validate_manifest_types(types)

  manifest_levels_by_type = {
      t['type']: set(t.get('levels') or ['organization', 'folder', 'project'])
      for t in types
  }
  iam_types = {
      t['type']
      for t in types
      if t.get('iam') and t.get('type') not in PSEUDO_TYPES
  }

  all_entries = []
  scope_summaries = []

  for s in scopes:
    root = s['root']
    scope_levels = s['levels']
    include = s['include']
    exclude = s['exclude']

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
        t['type']
        for t in types
        if t.get('type') not in PSEUDO_TYPES and (effective_levels_by_type[
            t['type']] or 'unknown' in manifest_levels_by_type[t['type']])
    })

    scope_entries = []

    if active_resource_types:
      try:
        assets = run_gcloud_json([
            scope_arg, '--content-type=resource',
            f'--asset-types={",".join(active_resource_types)}'
        ])
      except SystemExit:
        assets = []
        for rt in active_resource_types:
          try:
            assets += run_gcloud_json(
                [scope_arg, '--content-type=resource', f'--asset-types={rt}'])
          except SystemExit:
            search_scope = scope_arg.replace(
                '--organization=', 'organizations/').replace(
                    '--folder=', 'folders/').replace('--project=', 'projects/')
            assets += run_json([
                'gcloud', '--quiet', 'asset', 'search-all-resources',
                f'--scope={search_scope}', f'--asset-types={rt}',
                '--format=json'
            ], ignore_errors=True)
      registry.ingest_assets(assets)
      filtered_res = [
          a for a in assets if in_subtree(a, include, exclude, registry)
      ]
      scope_entries += _normalize_resources(filtered_res)

    if ('iam' in effective_levels_by_type and
        effective_levels_by_type['iam']) or iam_types:
      assets = [
          a for a in run_gcloud_json([scope_arg, '--content-type=iam-policy'])
          if in_subtree(a, include, exclude, registry)
      ]
      registry.ingest_assets(assets)
      if 'iam' in effective_levels_by_type and effective_levels_by_type['iam']:
        scope_entries += _normalize_iam(assets)
      if iam_types:
        scope_entries += _normalize_leaf_iam(assets, iam_types)

    if 'org-policy' in effective_levels_by_type and effective_levels_by_type[
        'org-policy']:
      assets = run_gcloud_json([scope_arg, '--content-type=org-policy'])
      scope_entries += _normalize_org_policies(
          a for a in assets if in_subtree(a, include, exclude, registry))
      pol_assets = run_gcloud_json([
          scope_arg, '--content-type=resource',
          '--asset-types=orgpolicy.googleapis.com/Policy'
      ])
      scope_entries += _normalize_org_policies_from_resources(
          a for a in pol_assets if in_subtree(a, include, exclude, registry))

      levels = effective_levels_by_type['org-policy']
      containers = []
      if 'organization' in levels and root.startswith('organizations/'):
        containers.append((root, root.split('/', 1)[1]))
      cont_asset_types = []
      if 'folder' in levels:
        cont_asset_types.append('cloudresourcemanager.googleapis.com/Folder')
      if 'project' in levels:
        cont_asset_types.append('cloudresourcemanager.googleapis.com/Project')
      if cont_asset_types:
        cont_assets = run_gcloud_json([
            scope_arg, '--content-type=resource',
            f'--asset-types={",".join(cont_asset_types)}'
        ])
        registry.ingest_assets(cont_assets)
        for a in cont_assets:
          if in_subtree(a, include, exclude, registry):
            c_path = a['name'].removeprefix(
                '//cloudresourcemanager.googleapis.com/')
            if a.get(
                'assetType') == 'cloudresourcemanager.googleapis.com/Project':
              pid = a.get('resource', {}).get(
                  'data', {}).get('projectId') or c_path.split('/', 1)[1]
              containers.append((c_path, pid))
            else:
              containers.append((c_path, c_path.split('/', 1)[1]))
      for container, sweep_id in containers:
        kind = container.split('/', 1)[0]
        flag = {
            'organizations': '--organization',
            'folders': '--folder',
            'projects': '--project'
        }.get(kind)
        if not flag:
          continue
        scope_entries += _normalize_org_policies_from_service(
            run_json([
                'gcloud', '--quiet', 'org-policies', 'list',
                f'{flag}={sweep_id}', '--format=json'
            ], ignore_errors=True, allow_disabled_service=True),
            container=container)

    # Filter this scope's entries by its effective levels
    scope_entries = apply_level_filter(scope_entries, effective_levels_by_type,
                                       report=False)
    scope_summaries.append({
        'name': s['name'],
        'root': root,
        'levels': sorted(scope_levels),
        'yield_count': len({e['key'] for e in scope_entries}),
    })
    all_entries += scope_entries

  # Dedupe merged streams across all scopes
  entries = list({e['key']: e for e in all_entries}.values())
  entries.sort(key=lambda e: e['key'])

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


def survey(scope_root):
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
  return _normalize_resources(assets)


def main():
  p = argparse.ArgumentParser(description=__doc__)
  sub = p.add_subparsers(dest='mode', required=True)
  ps = sub.add_parser('survey')
  ps.add_argument('--scope', required=True,
                  help='e.g. organizations/123, folders/456')
  ps.add_argument('--out', default='-')
  pc = sub.add_parser('collect')
  pc.add_argument('--manifest', required=True)
  pc.add_argument('--out', default='-')
  args = p.parse_args()

  if args.mode == 'survey':
    entries = survey(args.scope)
    payload = json.dumps(entries, indent=2)
  else:
    with open(args.manifest, 'rb') as f:
      manifest_raw = f.read()
    manifest = yaml.safe_load(manifest_raw)
    entries, registry, scope_summaries = collect(manifest)

    # Per-declared-type yield table.
    declared = [t['type'] for t in manifest.get('types') or []]
    type_counts = {
        d: sum(1 for e in entries if e['asset_type'] == d) for d in declared
    }
    print('\nper-declared-type yield:', file=sys.stderr)
    for d in declared:
      print(f'  {d}: {type_counts[d]}', file=sys.stderr)
    zero_yield = [d for d in declared if type_counts[d] == 0]
    if zero_yield:
      print(
          '\nWARNING: declared type(s) yielded ZERO entries. Confirm '
          'each type string\nagainst live `gcloud asset list` output '
          '(a mistyped asset type matches\nnothing and exits 0):',
          file=sys.stderr)
      for d in zero_yield:
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
                'scopes':
                    scope_summaries,
                'resolved_projects':
                    registry.id_to_num,
            },
            'assets': entries,
        }, indent=2)
  if args.out == '-':
    print(payload)
  else:
    with open(args.out, 'w', encoding='utf-8') as f:
      f.write(payload + '\n')
    print(f'wrote {len(entries)} inventory entries to {args.out}',
          file=sys.stderr)


if __name__ == '__main__':
  main()
