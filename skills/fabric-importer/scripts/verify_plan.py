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
"""FROZEN SCRIPT — machine-checked convergence verdict for a Terraform plan.

Reads `terraform show -json <planfile>` output (file argument or stdin)
and classifies every resource change:

  clean import (importing + no-op)                      -> OK
  no-op / read                                          -> OK
  update whose changed attributes ALL match a benign
    rule in benign-drift.yaml                           -> BENIGN (pass,
                                                           reported)
  anything else (create/update/replace/delete)          -> RESIDUAL (fail)

The benign ruleset ships with this tool and is HUMAN-owned: the model may
propose new entries (a template is printed for unmatched updates) but must
never edit the ruleset itself. Rationalizing a residual diff in prose is
not an accepted outcome; encoding it as a reviewed rule is.

Exit codes: 0 = converged, 2 = residual changes, 1 = malformed input.
"""

import argparse
import json
import os
import sys

import yaml

import integrity

DEFAULT_RULES = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             'benign-drift.yaml')


def load_rules(path):
  if not path or not os.path.exists(path):
    return []
  try:
    with open(path, 'r', encoding='utf-8') as f:
      data = yaml.safe_load(f) or {}
      if isinstance(data, list):
        return data
      elif isinstance(data, dict):
        return data.get('rules', [])
      return []
  except yaml.YAMLError as e:
    print(f'WARNING: failed to parse benign rules {path}: {e}', file=sys.stderr)
    return []


def strip_unknown(value, unknown):
  """Returns `value` with every subtree marked unknown removed.

  `unknown` mirrors the shape of the value in Terraform's `after_unknown`:
  `True` marks a fully-computed leaf, while dicts/lists mark only SOME
  nested members as computed. Masking the computed parts leaves the
  known remainder, which is the only part that can be compared
  meaningfully between `before` and `after`.
  """
  if unknown is True:
    return None
  if isinstance(unknown, dict) and isinstance(value, dict):
    return {
        k: strip_unknown(v, unknown.get(k, False))
        for k, v in value.items()
        if unknown.get(k) is not True
    }
  if isinstance(unknown, list) and isinstance(value, list):
    out = []
    for i, item in enumerate(value):
      sub = unknown[i] if i < len(unknown) else False
      if sub is True:
        continue
      out.append(strip_unknown(item, sub))
    return out
  return value


def changed_paths(change):
  """Top-level attributes that differ between before and after, plus
  whether every change is only computed (after_unknown).

  A partially-computed attribute (a block where only some members are
  unknown) must NOT be treated as computed wholesale: the known members
  are compared with the unknown subtrees masked out, and a difference
  there is real drift. Treating any truthy `after_unknown` entry as
  "computed" let genuine in-block drift ride the `all-changes-computed`
  rule into a benign verdict — a silent-gap mechanism, fixed here and
  covered by tests.
  """
  before = change.get('before') or {}
  after = change.get('after') or {}
  unknown = change.get('after_unknown') or {}
  paths = set()
  computed_only = True
  for k in set(before) | set(after) | set(unknown):
    u = unknown.get(k, False)
    if u:
      paths.add(k)
      # Fail closed: only the computed parts get a pass. If the known
      # remainder still differs, this is real drift, not a refresh
      # artifact.
      if strip_unknown(before.get(k), u) != strip_unknown(after.get(k), u):
        computed_only = False
      continue
    if before.get(k) != after.get(k):
      paths.add(k)
      computed_only = False
  return paths, computed_only


def match_benign(resource_type, paths, computed_only, rules, before=None):
  """Returns the reasons list if every changed path is covered by rules.

  A rule with `when_before: {<attr>: <value>}` applies only when every
  listed attribute has exactly that value in the plan's `before` state.
  This scopes rules to a specific live condition (e.g. empty-string
  description) instead of allowing any drift on the attribute.

  `match: all-changes-computed` rules are NO LONGER supported and are
  ignored: `after_unknown` means Terraform cannot prove the value, and a
  gate must never translate "cannot verify" into "no change". A change
  whose every attribute is unknown at plan time is a residual (hardening
  round 19); benign rules must name a resource type and attributes.
  """
  del computed_only  # no longer grants anything; see docstring.
  before = before or {}
  reasons = []
  covered = set()
  for rule in rules:
    if rule.get('match'):
      continue  # unsupported rule kind; fail closed by ignoring it.
    r_type = rule.get('resource', '*')
    if r_type not in ('*', resource_type):
      continue
    cond = rule.get('when_before')
    if cond and any(before.get(k) != v for k, v in cond.items()):
      continue
    attrs = set(rule.get('attributes') or [])
    hit = paths & attrs
    if hit:
      covered |= hit
      reasons.append(rule.get('reason', f'benign: {sorted(hit)}'))
  if paths and paths <= covered:
    return reasons
  return None


def classify(resource_change, rules):
  """Returns (verdict, detail) for one resource change entry.

  verdict: ok-import | ok | benign | residual
  """
  change = resource_change.get('change', {})
  actions = change.get('actions', [])
  # Synthetic in-memory resources (terraform_data precondition assertions
  # injected by Fabric modules) cannot touch cloud state. The exemption
  # is deliberately narrow (hardening round 19): exact builtin-provider
  # match AND create-only. Anything else on a terraform_data — a delete,
  # or a resource merely NAMED terraform_data from another provider —
  # goes through normal classification.
  if (resource_change.get('type') == 'terraform_data' and
      resource_change.get('provider_name') == 'terraform.io/builtin/terraform'
      and actions == ['create']):
    return 'ok', None
  importing = bool(change.get('importing'))
  if actions in (['no-op'], ['read']):
    return ('ok-import' if importing else 'ok'), None
  if actions == ['update']:
    paths, computed_only = changed_paths(change)
    reasons = match_benign(resource_change.get('type', ''), paths,
                           computed_only, rules,
                           change.get('before') or {})
    if reasons is not None:
      return 'benign', {'paths': sorted(paths), 'reasons': reasons}
    detail = {'paths': sorted(paths)}
    if computed_only and paths:
      detail['note'] = ('all changed attributes are unknown at plan '
                        'time; cannot verify')
    return 'residual', detail
  return 'residual', {'actions': actions}


def propose_rule(rc, detail):
  return {
      'resource': rc.get('type', ''),
      'attributes': detail.get('paths', []),
      'reason': 'TODO: justify why this diff is benign',
      'verified_against': {
          'provider': 'TODO'
      },
  }


def main():
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('plan', nargs='?', help='plan JSON file (default: stdin)')
  p.add_argument('--rules', default=DEFAULT_RULES,
                 help='benign-drift ruleset (default: alongside tool)')
  p.add_argument(
      '--allow-empty-plan', action='store_true',
      help='accept a plan whose resource_changes list is '
      'empty; by default that fails, because an empty '
      'plan is indistinguishable from an empty or wrong '
      'workspace')
  args = p.parse_args()

  if args.plan:
    with open(args.plan, 'rb') as f:
      raw = f.read()
    plan_origin = integrity.display_path(args.plan)
  else:
    stream = getattr(sys.stdin, 'buffer', sys.stdin)
    raw = stream.read()
    if isinstance(raw, str):
      raw = raw.encode('utf-8')
    plan_origin = '<stdin>'
  try:
    plan = json.loads(raw)
  except json.JSONDecodeError as e:
    print(f'ERROR: input is not valid JSON: {e}', file=sys.stderr)
    return 1
  # Fail closed on anything that is not a terraform plan JSON: `{}`,
  # truncated files, and `terraform show -json` STATE output (which has
  # format_version but no resource_changes) all used to sail through as
  # a vacuous CONVERGED verdict.
  if (not isinstance(plan, dict) or 'format_version' not in plan or
      'resource_changes' not in plan):
    print(
        'ERROR: input is not a terraform plan JSON '
        '(format_version and resource_changes are both required). '
        'Did you run `terraform show -json` without the plan file, '
        'which dumps STATE instead of a plan?', file=sys.stderr)
    return 1
  rules = load_rules(args.rules)

  counts = {'ok-import': 0, 'ok': 0, 'benign': 0}
  benign_notes = []
  residuals = []
  for rc in plan.get('resource_changes') or []:
    verdict, detail = classify(rc, rules)
    if verdict == 'residual':
      residuals.append((rc, detail))
    else:
      counts[verdict] += 1
      if verdict == 'benign':
        benign_notes.append((rc.get('address'), detail))

  print(integrity.stamp())
  print(integrity.data_stamp('plan', raw, plan_origin))
  rules_path = os.path.abspath(args.rules)
  if os.path.exists(rules_path):
    print(integrity.input_stamp('rules', rules_path))
  else:
    print(f'input rules: {rules_path} MISSING (no rules loaded)')
  if rules_path != os.path.abspath(DEFAULT_RULES):
    print('WARNING: non-default rules file in force. The verdict below '
          'is NOT judged by the\nfrozen human-owned ruleset; a reviewer '
          'must inspect the file hashed above.')
  print(f'plan verification: {counts["ok-import"]} clean import(s), '
        f'{counts["ok"]} no-op(s), {counts["benign"]} benign change(s), '
        f'{len(residuals)} residual change(s)')

  if not plan.get('resource_changes'):
    print('WARNING: plan contains zero resource changes. That proves '
          'nothing was planned,\nnot that the workspace converged — an '
          'empty workspace or the wrong -chdir plans\nempty too.')
    if not args.allow_empty_plan:
      print('Refusing the empty plan (pass --allow-empty-plan only if a '
            'zero-change plan\nis genuinely expected, e.g. a re-run '
            'after state was applied).')
      return 2

  if benign_notes:
    print('\nBENIGN CHANGES (allowed by ruleset, review periodically):')
    for addr, detail in benign_notes:
      print(f'  {addr}: {detail["paths"]} — {"; ".join(detail["reasons"])}')

  if residuals:
    print('\nRESIDUAL CHANGES (config does not match live '
          'infrastructure):')
    proposals = []
    for rc, detail in residuals:
      actions = '/'.join(rc.get('change', {}).get('actions', []))
      print(f'  [{actions}] {rc.get("address")} '
            f'{detail.get("paths", detail.get("actions", ""))}')
      if rc.get('change', {}).get('actions') == ['update']:
        proposals.append(propose_rule(rc, detail))
    if proposals:
      print('\nIf (and only if) a human confirms these diffs are provider '
            'artifacts,\nadd reviewed entries to benign-drift.yaml, e.g.:\n')
      print(yaml.safe_dump({'rules': proposals}, sort_keys=False))
    print('The workspace has NOT converged. Fix the mapping or obtain a '
          'reviewed benign rule; never apply.')
    return 2

  print('CONVERGED: every planned change is a clean import, no-op, or '
        'reviewed-benign.')
  return 0


if __name__ == '__main__':
  sys.exit(main())
