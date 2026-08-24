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
"""Drafts an import manifest from a survey inventory.

Part of the agent-assisted manifest workflow (SKILL.md step 0):

  1. python3 scripts/inventory.py survey --scope organizations/ID \
       --out survey.json
  2. python3 scripts/manifest_init.py --survey survey.json \
       --scope organizations/ID --out import-manifest.yaml
  3. The agent walks the user through the draft: every discovered asset
     type is listed with counts per level, commented out; the user (with
     the agent) uncomments what to import and trims levels.

The draft is a starting point for a human decision, not a decision.
"""

import argparse
import json
import sys
from collections import defaultdict

# Types the drafted manifest enables by default (the organization
# foundation the legacy pipeline covered). Everything else is emitted
# commented out.
FOUNDATION_TYPES = {
    'cloudresourcemanager.googleapis.com/Folder': ['organization', 'folder'],
    'iam.googleapis.com/Role': ['organization'],
    'logging.googleapis.com/LogSink': ['organization'],
}
FOUNDATION_PSEUDO = {
    'iam': ['organization', 'folder'],
    'org-policy': ['organization'],
}


def draft_manifest(survey_entries, scope_root):
  counts = defaultdict(lambda: defaultdict(int))
  for e in survey_entries:
    if isinstance(e, dict) and 'asset_type' in e and 'level' in e:
      counts[e['asset_type']][e['level']] += 1

  lines = [
      '# Import manifest drafted by manifest_init.py — review with care.',
      '# Uncomment the types you want under management; restrict levels',
      '# and scope to keep plans small. See examples/ for a documented',
      '# reference manifest.',
      '',
      'scope:',
      f'  root: {scope_root}',
      '  # include: [folders/1234]   # optional subtree restriction',
      '  # exclude: [projects/foo]   # optional subtree exclusion',
      '',
      'types:',
  ]

  def type_block(asset_type, levels, count_note, enabled):
    prefix = '  ' if enabled else '  # '
    out = [f'{prefix}- type: {asset_type}{count_note}']
    out.append(f'{prefix}  levels: [{", ".join(levels)}]')
    return out

  # Pseudo-types first (IAM policies and org policies are content types in
  # CAI, not asset types, so a survey cannot count them).
  lines.append('  # -- IAM policies and org policies (pseudo-types; not')
  lines.append('  #    counted by a resource survey) --')
  for pseudo, levels in FOUNDATION_PSEUDO.items():
    lines += type_block(pseudo, levels, '', enabled=True)
  lines.append('')
  lines.append('  # -- discovered resource types (count by level) --')

  for asset_type in sorted(counts):
    per_level = counts[asset_type]
    note = '   # ' + ', '.join(
        f'{lvl}: {n}' for lvl, n in sorted(per_level.items()))
    if asset_type in FOUNDATION_TYPES:
      levels = FOUNDATION_TYPES[asset_type]
      lines += type_block(asset_type, levels, note, enabled=True)
    else:
      levels = sorted(per_level)
      lines += type_block(asset_type, levels, note, enabled=False)

  return '\n'.join(lines) + '\n'


def main():
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('--survey', required=True,
                 help='survey inventory JSON from inventory.py survey')
  p.add_argument('--scope', required=True, help='e.g. organizations/123')
  p.add_argument('--out', default='import-manifest.yaml')
  args = p.parse_args()

  try:
    with open(args.survey, 'r', encoding='utf-8') as f:
      raw = json.load(f)
  except FileNotFoundError:
    print(f'ERROR: survey file not found: {args.survey}', file=sys.stderr)
    return 1
  except json.JSONDecodeError as e:
    print(f'ERROR: invalid JSON in survey {args.survey}: {e}', file=sys.stderr)
    return 1

  entries = raw.get('assets', raw) if isinstance(raw, dict) else raw
  if not isinstance(entries, list):
    print(f'ERROR: unexpected survey structure in {args.survey}',
          file=sys.stderr)
    return 1

  draft = draft_manifest(entries, args.scope)
  try:
    with open(args.out, 'w', encoding='utf-8') as f:
      f.write(draft)
  except (IOError, OSError) as e:
    print(f'ERROR: could not write to {args.out}: {e}', file=sys.stderr)
    return 1

  print(f'drafted manifest with {len(entries)} surveyed assets '
        f'-> {args.out}')
  print('Review it with the user before running inventory.py collect.')
  return 0


if __name__ == '__main__':
  sys.exit(main())
