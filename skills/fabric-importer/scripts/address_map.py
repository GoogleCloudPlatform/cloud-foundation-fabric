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
"""Linter and renderer for the address map — NOT a gate.

`mapping-cookbook.md` mixes two kinds of knowledge. The fielded tuples
(asset type, module, address, import ID, verification round) are uniform
and mechanically checkable. The reasoning around them — ForceNew traps,
provider quirks, waiver postures — is causal prose that only degrades
when squeezed into a schema. This tool owns the first kind and touches
nothing of the second.

It exists because the first kind kept being duplicated. Addresses lived
both in per-type prose and in a hand-maintained markdown table, and
three families were once documented twice because no check could see it.
`--lint-cookbook` makes that class of drift a CI failure instead of a
reviewer's lucky catch.

THIS IS NOT A GATE, and it is deliberately not wired into `coverage.py`
or `verify_plan.py`. The gates judge a workspace against live reality.
A wrong entry in the address map is caught by `terraform plan` erroring
loudly, unlike a wrong `benign-drift.yaml` entry which would silently
pass a gate. Different blast radius, different rigour budget.

So the split is:

  - THIS FILE is in `integrity.FROZEN_FILES`. Everything executable
    that ships in `scripts/` is tamper-evident, with no exceptions to
    reason about — a reader cannot tell a gate from a linter by
    looking, so the invariant stays unqualified.
  - `references/address-map.yaml` is NOT frozen, and must not become
    so. It is human-owned data that grows every time someone maps a new
    type; putting it behind the digest would add gate ceremony to
    routine note-taking and would imply the map is authoritative, which
    it is not.

`--check-workspace` is an ADVISORY reader for the same reason: it
reports unrecognised addresses and always exits 0. The cookbook is
deliberately incomplete; an unknown address is a normal finding, not an
error.

Usage:

    uv run scripts/address_map.py --validate
    uv run scripts/address_map.py --lint-cookbook
    uv run scripts/address_map.py --render-cookbook [--check]
    uv run scripts/address_map.py --check-workspace tf/
"""

import argparse
import os
import re
import sys

import yaml

_HERE = os.path.dirname(os.path.abspath(__file__))
_SKILL = os.path.dirname(_HERE)

DEFAULT_MAP = os.path.join(_SKILL, 'references', 'address-map.yaml')
DEFAULT_COOKBOOK = os.path.join(_SKILL, 'references', 'mapping-cookbook.md')

BEGIN_MARKER = '<!-- BEGIN ADDRESS-MAP (generated) -->'
END_MARKER = '<!-- END ADDRESS-MAP -->'

REQUIRED = ('resource', 'module', 'address', 'import_id')
OPTIONAL = ('asset_type', 'verified', 'note', 'disambiguation')
SLUG_RE = re.compile(r'^[a-z0-9]+(-[a-z0-9]+)*$')
VERIFIED_RE = re.compile(r'^r\d+$')
# `### Heading (`modules/x`)` — the per-type section convention.
SECTION_RE = re.compile(r'^###\s+(?P<title>.+?)\s*$')
MODULE_IN_TITLE_RE = re.compile(r'`(modules/[a-z0-9-]+)`')


def load(path=DEFAULT_MAP):
  """Reads and shallowly type-checks the address map."""
  with open(path, encoding='utf-8') as f:
    doc = yaml.safe_load(f)
  if not isinstance(doc, dict):
    raise SystemExit(f'{path}: top level must be a mapping')
  if doc.get('version') != 1:
    raise SystemExit(f'{path}: unsupported version {doc.get("version")!r}')
  entries = doc.get('entries')
  if not isinstance(entries, dict) or not entries:
    raise SystemExit(f'{path}: `entries` must be a non-empty mapping')
  return entries


def validate(entries):
  """Returns a list of human-readable schema and invariant violations."""
  errors = []
  by_address = {}
  by_asset_type = {}

  for slug, entry in entries.items():
    where = f'entries.{slug}'
    if not SLUG_RE.match(slug):
      errors.append(f'{where}: slug must be kebab-case')
    if not isinstance(entry, dict):
      errors.append(f'{where}: must be a mapping')
      continue

    unknown = set(entry) - set(REQUIRED) - set(OPTIONAL)
    if unknown:
      errors.append(f'{where}: unknown keys {sorted(unknown)}')
    for key in REQUIRED:
      value = entry.get(key)
      if not isinstance(value, str) or not value.strip():
        errors.append(
            f'{where}: `{key}` is required and must be a non-empty string')

    verified = entry.get('verified', False)
    if verified is not False and not (isinstance(verified, str) and
                                      VERIFIED_RE.match(verified)):
      errors.append(f'{where}: `verified` must be false or match r<digits>, '
                    f'got {verified!r}')

    for key in ('note', 'disambiguation'):
      value = entry.get(key)
      if value is None:
        continue
      if not isinstance(value, str):
        errors.append(f'{where}: `{key}` must be a string')
      elif '\n' in value.strip():
        errors.append(f'{where}: `{key}` must be a single line — multi-line '
                      f'reasoning belongs in mapping-cookbook.md')

    address = entry.get('address')
    if isinstance(address, str):
      by_address.setdefault(address, []).append(slug)

    asset_type = entry.get('asset_type')
    if isinstance(asset_type, str) and asset_type.strip():
      by_asset_type.setdefault(asset_type, []).append(slug)

  # Invariant: an address pattern is claimed exactly once. This is the
  # check that would have caught the duplicated DNS/NAT/NCC sections.
  for address, slugs in sorted(by_address.items()):
    if len(slugs) > 1:
      errors.append(f'duplicate address {address!r} claimed by {sorted(slugs)}')

  # Invariant: a CAI type serviced by more than one module is ambiguous
  # for whoever is mapping, so every entry sharing it must say how to
  # tell them apart. `compute.googleapis.com/Router` is the live case:
  # net-cloudnat and net-vpn-ha both create one.
  for asset_type, slugs in sorted(by_asset_type.items()):
    modules = {entries[s].get('module') for s in slugs}
    if len(modules) < 2:
      continue
    for slug in sorted(slugs):
      value = entries[slug].get('disambiguation')
      if not (isinstance(value, str) and value.strip()):
        errors.append(
            f'entries.{slug}: asset_type {asset_type!r} maps to modules '
            f'{sorted(m for m in modules if m)} — `disambiguation` is required')
  return errors


def lint_cookbook(path=DEFAULT_COOKBOOK):
  """Flags per-type sections that name a module already documented.

  The concrete failure this prevents: a contributor appends a section
  for a module that already has one further up, and the two silently
  disagree. Duplicate advice is worse than no advice, because the reader
  has no way to know which copy is current.
  """
  errors = []
  seen = {}
  with open(path, encoding='utf-8') as f:
    lines = f.read().split('\n')
  for number, line in enumerate(lines, start=1):
    match = SECTION_RE.match(line)
    if not match:
      continue
    title = match.group('title')
    for module in MODULE_IN_TITLE_RE.findall(title):
      if module in seen:
        first_line, first_title = seen[module]
        errors.append(f'{path}:{number}: section "{title}" re-documents '
                      f'{module}, already covered by "{first_title}" at '
                      f'line {first_line} — merge them')
      else:
        seen[module] = (number, title)
  return errors


def render_table(entries):
  """Renders the fielded map as the cookbook's markdown table."""
  out = [
      '| Resource | Module | Address pattern | Import ID | Verified |',
      '|---|---|---|---|---|',
  ]
  for slug in sorted(entries, key=lambda s: (entries[s]['module'], s)):
    entry = entries[slug]
    verified = entry.get('verified', False)
    verified = verified if isinstance(verified, str) else '—'
    module = entry['module']
    module = module if module == 'raw' else f'`{module}`'
    out.append(f'| {entry["resource"]} | {module} | `{entry["address"]}` | '
               f'`{entry["import_id"]}` | {verified} |')
  return '\n'.join(out)


def render_cookbook(entries, path=DEFAULT_COOKBOOK, check=False):
  """Replaces the generated block in the cookbook. Returns True if changed."""
  with open(path, encoding='utf-8') as f:
    content = f.read()
  if BEGIN_MARKER not in content or END_MARKER not in content:
    raise SystemExit(f'{path}: missing {BEGIN_MARKER} / {END_MARKER} markers')
  head, rest = content.split(BEGIN_MARKER, 1)
  _, tail = rest.split(END_MARKER, 1)
  block = f'{BEGIN_MARKER}\n\n{render_table(entries)}\n\n{END_MARKER}'
  updated = f'{head}{block}{tail}'
  if updated == content:
    return False
  if not check:
    with open(path, 'w', encoding='utf-8') as f:
      f.write(updated)
  return True


def _address_regex(pattern):
  """Turns an address pattern into a regex, with <placeholder> as a wildcard.

  Module instance names and for_each keys are chosen per engagement, so
  only the resource-type skeleton is comparable.
  """
  parts = re.split(r'<[a-z_]+>', pattern)
  return re.compile('^' + '[^.\\[\\]"]*'.join(re.escape(p) for p in parts) +
                    '$')


def check_workspace(entries, workspace):
  """ADVISORY: reports emitted import targets matching no known pattern.

  Never fails. A miss means the cookbook has not seen the type yet,
  which SKILL.md calls the normal case, not an error.
  """
  patterns = [_address_regex(e['address']) for e in entries.values()]
  targets = []
  target_re = re.compile(r'^\s*to\s*=\s*(?P<addr>\S.*?)\s*$')
  for root, _, files in os.walk(workspace):
    for name in sorted(files):
      if not name.endswith('.tf'):
        continue
      full = os.path.join(root, name)
      with open(full, encoding='utf-8') as f:
        for number, line in enumerate(f, start=1):
          match = target_re.match(line)
          if match:
            targets.append((full, number, match.group('addr')))
  unknown = [t for t in targets if not any(p.match(t[2]) for p in patterns)]
  return targets, unknown


def main(argv=None):
  parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
  parser.add_argument('--map', default=DEFAULT_MAP)
  parser.add_argument('--cookbook', default=DEFAULT_COOKBOOK)
  parser.add_argument('--validate', action='store_true')
  parser.add_argument('--lint-cookbook', action='store_true')
  parser.add_argument('--render-cookbook', action='store_true')
  parser.add_argument('--check', action='store_true',
                      help='with --render-cookbook, fail instead of writing')
  parser.add_argument('--check-workspace', metavar='DIR')
  args = parser.parse_args(argv)

  if not any((args.validate, args.lint_cookbook, args.render_cookbook,
              args.check_workspace)):
    args.validate = args.lint_cookbook = True

  entries = load(args.map)
  failed = False

  if args.validate:
    errors = validate(entries)
    for error in errors:
      print(f'ERROR {error}', file=sys.stderr)
    print(f'address map: {len(entries)} entries, {len(errors)} error(s)')
    failed |= bool(errors)

  if args.lint_cookbook:
    errors = lint_cookbook(args.cookbook)
    for error in errors:
      print(f'ERROR {error}', file=sys.stderr)
    print(f'cookbook lint: {len(errors)} error(s)')
    failed |= bool(errors)

  if args.render_cookbook:
    changed = render_cookbook(entries, args.cookbook, check=args.check)
    if args.check and changed:
      print('ERROR generated table is stale — run --render-cookbook',
            file=sys.stderr)
      failed = True
    else:
      print(f'cookbook table: {"rewritten" if changed else "up to date"}')

  if args.check_workspace:
    targets, unknown = check_workspace(entries, args.check_workspace)
    for path, number, address in unknown:
      print(f'ADVISORY {path}:{number}: {address} matches no known pattern')
    print(f'workspace: {len(targets)} import target(s), '
          f'{len(unknown)} unrecognised (advisory only)')

  return 1 if failed else 0


if __name__ == '__main__':
  sys.exit(main())
