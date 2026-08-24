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
"""FROZEN SCRIPT — completeness gate and incremental worklist.

Reconciles four artifacts:
  inventory.json    (from inventory.py: the in-scope denominator)
  coverage-map.yaml (model-maintained: inventory key -> [tf addresses])
  workspace tf/     (import blocks actually emitted)
  waivers.yaml      (HUMAN-owned: in-scope keys deliberately not modelled)

Verdict per in-scope inventory key:
  mapped    key in coverage-map AND every mapped address exists in an
            emitted import block
  waived    key in waivers.yaml (with reason)
  MISSING   neither -> listed in the worklist; gate fails

Also fails on: coverage-map addresses with no matching import block
(dangling), coverage-map keys not in inventory (stale), and waived keys
that are also mapped (contradiction).

Exit codes: 0 = fully reconciled, 2 = gaps found, 1 = malformed input.
The worklist output is the model's incremental to-do list: re-runs extend
the workspace for MISSING keys only and must never rewrite existing
addresses.
"""

import argparse
import glob
import json
import os
import re
import sys

import yaml

import integrity

_IMPORT_TO_RE = re.compile(r'^\s*to\s*=\s*(.+?)\s*$')
_IMPORT_ID_RE = re.compile(r'^\s*id\s*=\s*(.+?)\s*$')


def _clean_hcl_line(line):
  """Strips both # and // comments while respecting quotes and escapes."""
  in_quote = False
  out = []
  i = 0
  while i < len(line):
    c = line[i]
    if c == '"':
      bs_count = 0
      j = i - 1
      while j >= 0 and line[j] == '\\':
        bs_count += 1
        j -= 1
      if bs_count % 2 == 0:
        in_quote = not in_quote
    if not in_quote:
      if c == '#' or (c == '/' and i + 1 < len(line) and line[i + 1] == '/'):
        break
    out.append(c)
    i += 1
  return ''.join(out).strip()


def parse_import_blocks(tf_dir):
  """Extracts (to-address -> import id) from workspace `import {}` blocks.

  Recursively scans tf_dir for all *.tf files.
  """
  blocks = {}
  for root, _, files in os.walk(tf_dir):
    for filename in sorted(files):
      if filename.endswith('.tf'):
        path = os.path.join(root, filename)
        try:
          with open(path, 'r', encoding='utf-8') as f:
            in_import = False
            cur_to, cur_id = None, None
            for line in f:
              cleaned = _clean_hcl_line(line)
              if not cleaned:
                continue
              if cleaned.startswith('import {') or (cleaned.startswith('import')
                                                    and '{' in cleaned):
                in_import = True
                cur_to, cur_id = None, None
                continue
              if in_import:
                m = _IMPORT_TO_RE.match(cleaned)
                if m:
                  cur_to = m.group(1).strip()
                m = _IMPORT_ID_RE.match(cleaned)
                if m:
                  cur_id = m.group(1).strip().strip('"')
                if cleaned == '}' or cleaned.endswith('}'):
                  in_import = False
                  if cur_to:
                    blocks[cur_to] = cur_id
        except (IOError, OSError) as e:
          print(f'WARNING: could not read {path}: {e}', file=sys.stderr)
  return blocks


def parse_import_addresses(tf_dir):
  """Extracts every `import { to = ... }` address from workspace HCL."""
  return set(parse_import_blocks(tf_dir))


def unsigned_waivers(waivers):
  """Waiver keys with no `signed_by` attribution, in order."""
  return [
      w['key']
      for w in waivers
      if isinstance(w, dict) and str(w.get('key', '')).strip() and
      (not isinstance(w.get('signed_by'), str) or not w['signed_by'].strip())
  ]


def reconcile(inventory, coverage_map, waivers, import_addresses,
              require_signed=False):
  inv_keys = {e['key'] for e in inventory}
  mapped_keys = set(coverage_map)

  problems = []
  clean_waivers = []
  for i, w in enumerate(waivers):
    if not isinstance(w, dict) or not str(w.get('key', '')).strip():
      problems.append(f'malformed waiver entry #{i + 1}: {w!r}')
      continue
    clean_waivers.append(w)
  waived = {w['key']: w.get('reason', '') for w in clean_waivers}

  for key, reason in waived.items():
    if not reason:
      problems.append(f'waiver without reason: {key}')
    if key in mapped_keys:
      problems.append(f'key both waived and mapped: {key}')
  for key in sorted(set(waived) - inv_keys):
    problems.append(f'waived key not in inventory (stale?): {key}')
  if require_signed:
    for key in unsigned_waivers(clean_waivers):
      problems.append(f'waiver without signed_by attribution: {key}')

  stale = sorted(mapped_keys - inv_keys)
  for key in stale:
    problems.append(f'coverage-map key not in inventory (stale?): {key}')

  addr_claims = {}
  for key in mapped_keys:
    addrs = coverage_map[key]
    if addrs is not None and not isinstance(addrs, list):
      problems.append(f'coverage-map value must be a list of addresses: {key}')
      continue
    for a in addrs or []:
      addr_claims.setdefault(a, []).append(key)

  for a, keys in sorted(addr_claims.items()):
    if len(keys) > 1:
      problems.append(f'address claimed by {len(keys)} coverage-map keys '
                      f'(must be unique): {a} <- {sorted(keys)}')

  dangling = []
  for key in sorted(mapped_keys & inv_keys):
    addrs = coverage_map[key]
    if addrs is not None and not isinstance(addrs, list):
      continue
    if not addrs:
      problems.append(f'coverage-map entry with no addresses: {key}')
    for a in addrs or []:
      if a not in import_addresses:
        dangling.append((key, a))
  for key, a in dangling:
    problems.append(f'mapped address has no import block: {key} -> {a}')

  for a in sorted(set(import_addresses) - set(addr_claims)):
    problems.append(
        f'orphan import block (address not claimed by any coverage-map '
        f'key): {a}')

  missing = sorted(inv_keys - mapped_keys - set(waived))
  return missing, problems


def main():
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('--inventory', required=True)
  p.add_argument('--workspace', required=True,
                 help='directory containing generated *.tf')
  p.add_argument('--coverage-map', default=None,
                 help='default: <workspace>/coverage-map.yaml')
  p.add_argument('--waivers', default=None,
                 help='human-owned waiver file (optional)')
  p.add_argument(
      '--require-signed-waivers', action='store_true',
      help='fail if any waiver lacks signed_by attribution; use '
      'when a human is available to accept them')
  p.add_argument(
      '--allow-empty-inventory', action='store_true',
      help='accept an inventory with zero entries; by default '
      'that fails, because an empty denominator makes '
      'every completeness claim vacuous')
  p.add_argument('--worklist-out', default=None,
                 help='write MISSING keys as YAML worklist')
  args = p.parse_args()

  try:
    with open(args.inventory, 'r', encoding='utf-8') as f:
      raw_inventory = json.load(f)
  except FileNotFoundError:
    print(f'ERROR: inventory file not found: {args.inventory}', file=sys.stderr)
    return 1
  except json.JSONDecodeError as e:
    print(f'ERROR: malformed JSON in inventory {args.inventory}: {e}',
          file=sys.stderr)
    return 1

  legacy_inventory = False
  if isinstance(raw_inventory, dict) and 'assets' in raw_inventory:
    inventory = raw_inventory['assets']
  elif isinstance(raw_inventory, list):
    inventory = raw_inventory
    legacy_inventory = True
  else:
    print(
        'ERROR: inventory JSON is neither a {_meta, assets} object nor '
        'a bare entry list', file=sys.stderr)
    return 1
  if not inventory and not args.allow_empty_inventory:
    print(
        'ERROR: empty denominator — the inventory contains zero '
        'entries, so there is\nnothing to reconcile and RECONCILED '
        'would be vacuous. Common causes: a\nscope.include entry using '
        'a project ID instead of the project NUMBER, a\nmistyped asset '
        'type, or the wrong manifest. Fix the enumeration, or pass\n'
        '--allow-empty-inventory if zero in-scope assets is genuinely '
        'expected.', file=sys.stderr)
    return 1
  cmap_path = args.coverage_map or os.path.join(args.workspace,
                                                'coverage-map.yaml')
  coverage_map = {}
  if os.path.exists(cmap_path):
    try:
      with open(cmap_path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f) or {}
        if not isinstance(data, dict):
          print(
              f'ERROR: coverage-map {cmap_path} must be a YAML mapping (key -> addresses)',
              file=sys.stderr)
          return 1
        coverage_map = data
    except yaml.YAMLError as e:
      print(f'ERROR: invalid YAML in coverage-map {cmap_path}: {e}',
            file=sys.stderr)
      return 1

  waivers = []
  if args.waivers and os.path.exists(args.waivers):
    try:
      with open(args.waivers, 'r', encoding='utf-8') as f:
        raw_w = yaml.safe_load(f) or {}
        if isinstance(raw_w, list):
          waivers = raw_w
        elif isinstance(raw_w, dict):
          waivers = raw_w.get('waivers', [])
        else:
          print(
              f'ERROR: waivers in {args.waivers} must be a list or mapping with a "waivers" list',
              file=sys.stderr)
          return 1
    except yaml.YAMLError as e:
      print(f'ERROR: invalid YAML in waivers {args.waivers}: {e}',
            file=sys.stderr)
      return 1

  import_addresses = parse_import_addresses(args.workspace)
  missing, problems = reconcile(inventory, coverage_map, waivers,
                                import_addresses, args.require_signed_waivers)

  n_inv = len({e['key'] for e in inventory})
  print(integrity.stamp())
  print(integrity.input_stamp('inventory', args.inventory))
  if legacy_inventory:
    print('WARNING: inventory has no provenance metadata (legacy bare-'
          'list format);\nit cannot be tied to the manifest that '
          'produced it. Regenerate with the\ncurrent inventory.py.')
  if os.path.exists(cmap_path):
    print(integrity.input_stamp('coverage-map', cmap_path))
  if args.waivers and os.path.exists(args.waivers):
    print(integrity.input_stamp('waivers', args.waivers))
  tf_files = []
  for root, _, files in os.walk(args.workspace):
    for filename in sorted(files):
      if filename.endswith('.tf'):
        tf_files.append(os.path.join(root, filename))
  print(
      integrity.tree_stamp('workspace', tf_files,
                           integrity.display_path(args.workspace)))
  print(f'coverage: {n_inv} in scope, {len(coverage_map)} mapped, '
        f'{len(waivers)} waived, {len(missing)} missing, '
        f'{len(problems)} problem(s)')

  unsigned = unsigned_waivers(waivers)
  if unsigned and not args.require_signed_waivers:
    print(f'  note: {len(unsigned)} of {len(waivers)} waiver(s) carry no '
          'signed_by attribution.')
    print('  A waiver shrinks what this gate checks. Record who accepted '
          'each one before')
    print('  treating the run as complete (--require-signed-waivers makes '
          'this a failure).')

  if problems:
    print('\nPROBLEMS:')
    for pr in problems:
      print(f'  - {pr}')

  if missing:
    missing_set = set(missing)
    print('\nWORKLIST (in scope, not mapped, not waived):')
    by_type = {}
    for e in inventory:
      if e['key'] in missing_set:
        by_type.setdefault(e['asset_type'], []).append(e)
    for t in sorted(by_type):
      print(f'  {t}: {len(by_type[t])}')
      for e in by_type[t][:5]:
        print(f'    - {e["key"]}')
      if len(by_type[t]) > 5:
        print(f'    ... and {len(by_type[t]) - 5} more')
    if args.worklist_out:
      try:
        with open(args.worklist_out, 'w', encoding='utf-8') as f:
          yaml.safe_dump(
              {'worklist': [e for e in inventory if e['key'] in missing_set]},
              f, sort_keys=False)
        print(f'\nworklist written to {args.worklist_out}')
      except (IOError, OSError) as e:
        print(f'ERROR: could not write worklist to {args.worklist_out}: {e}',
              file=sys.stderr)
        return 1

  if missing or problems:
    print('\nNOT RECONCILED: extend the workspace for missing keys '
          '(never rewrite existing addresses) or obtain human-signed '
          'waivers.')
    return 2
  print('RECONCILED: every in-scope asset is mapped or waived.')
  return 0


if __name__ == '__main__':
  sys.exit(main())
