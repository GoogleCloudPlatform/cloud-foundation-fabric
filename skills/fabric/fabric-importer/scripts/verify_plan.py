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

Exit codes: 0 = converged, 1 = malformed input, 2 = residual changes,
3 = converged but ADVISORY (a substituted --rules file; never a passing
gate). A residual plan judged by a substituted ruleset still exits 2.
"""

import argparse
import json
import os
import re
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
        rules = data.get('rules', [])
        if not isinstance(rules, list):
          print(f'WARNING: `rules` in {path} is not a list; no rules loaded',
                file=sys.stderr)
          return []
        return rules
      print(
          f'WARNING: unexpected top-level shape in {path} '
          f'({type(data).__name__}); no rules loaded', file=sys.stderr)
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


_MISSING = object()


def match_benign(resource_type, paths, rules, before=None, after=None,
                 unknown=None):
  """Returns the reasons list if every changed path is covered by rules.

  A rule scopes itself to a live condition with these guards:

    when_before: {<attr>: <value>}   exact value in the plan's `before`
    when_after:  {<attr>: <value>}   exact value in the plan's `after`
    when_after_matches: {<attr>: <regex>}
                                     `after` is a string fully matching
                                     the regex, on one line
    when_after_computed: [<attr>, …] or true
                                     `after` is FULLY unknown at plan
                                     time, i.e. the provider computes it
    when_unchanged: [<attr>, …]      these attributes must not appear in
                                     the diff at all

  Every rule must BOUND THE DIFF, and `bound` is checked, not trusted:
  either every attribute the rule covers carries a direct destination
  guard (`when_after`/`when_after_matches`/`when_after_computed`), or the
  rule declares `when_unchanged` naming the live-affecting siblings that
  prove the diff inert (the `terraform_labels` case: provider bookkeeping
  is harmless exactly while `labels` and `effective_labels` are
  untouched). `when_unchanged` must be disjoint from `attributes`.

  Guarding only `when_before` was a silent hole: a rule matching a live
  empty description accepted ANY new description, so the gate reported
  CONVERGED for a plan that would really write a value to the live
  resource on apply. A benign rule asserts "this diff changes nothing",
  which is a claim about the destination as much as the source.

  `match: all-changes-computed` rules are NO LONGER supported and are
  ignored: `after_unknown` means Terraform cannot prove the value, and a
  gate must never translate "cannot verify" into "no change". A change
  whose every attribute is unknown at plan time is a residual (hardening
  round 19); benign rules must name a resource type and attributes.
  """
  before = before or {}
  after = after or {}
  unknown = unknown or {}
  reasons = []
  covered = set()
  for rule in rules:
    if rule.get('match'):
      continue  # unsupported rule kind; fail closed by ignoring it.
    r_type = rule.get('resource', '*')
    if r_type not in ('*', resource_type):
      continue
    attrs = set(rule.get('attributes') or [])
    hit = paths & attrs
    if not hit:
      continue
    problem = rule_guard_problem(rule)
    if problem:
      _warn_once(f'WARNING: ignoring benign rule for {r_type} '
                 f'{sorted(attrs)}: {problem}')
      continue
    cond = rule.get('when_before') or {}
    if any(before.get(k, _MISSING) != v for k, v in cond.items()):
      continue
    cond = rule.get('when_after') or {}
    # An unknown destination is not a matching destination: `after` holds
    # null for a computed value exactly as it does for an absent key, so
    # without this check `when_after: {x: null}` would silently accept
    # "the provider will decide later" as "no change".
    if any(unknown.get(k) for k in cond):
      continue
    if any(after.get(k, _MISSING) != v for k, v in cond.items()):
      continue
    if not _match_after_patterns(rule.get('when_after_matches'), after,
                                 unknown):
      continue
    if not _match_after_computed(rule.get('when_after_computed'), hit, unknown,
                                 before, after):
      continue
    unchanged = rule.get('when_unchanged') or []
    if any(k in paths for k in unchanged):
      continue
    covered |= hit
    reasons.append(rule.get('reason', f'benign: {sorted(hit)}'))
  if paths and paths <= covered:
    return reasons
  return None


_WARNED = set()


def _warn_once(message):
  """A malformed rule must not print once per resource in a large plan."""
  if message not in _WARNED:
    _WARNED.add(message)
    print(message, file=sys.stderr)


def _guard_keys(rule):
  """Attributes for which the rule bounds the destination directly."""
  attrs = set(rule.get('attributes') or [])
  keys = set()
  for field in ('when_after', 'when_after_matches'):
    val = rule.get(field)
    if isinstance(val, dict):
      keys |= set(val)
  computed = rule.get('when_after_computed')
  if computed is True:
    keys |= attrs
  elif isinstance(computed, (list, tuple, set)):
    keys |= set(computed)
  return keys


def rule_guard_problem(rule):
  """Why the rule may not be applied, or None if it is well formed.

  Shape errors are refusals, not crashes: this file is edited by humans,
  and a YAML slip that silently disabled a rule (or raised an
  AttributeError mid-gate) would be indistinguishable from a rule that
  simply did not match.
  """
  attrs = set(rule.get('attributes') or [])
  if not attrs:
    return 'no `attributes` list, so the rule can never apply'
  for field in ('when_before', 'when_after', 'when_after_matches'):
    if field in rule and not isinstance(rule[field], dict):
      return f'`{field}` must be a mapping of attribute to value'
  computed = rule.get('when_after_computed')
  if computed is not None and computed is not True and not isinstance(
      computed, (list, tuple, set)):
    return '`when_after_computed` must be true or a list of attributes'
  unchanged = rule.get('when_unchanged')
  if unchanged is not None and not isinstance(unchanged, (list, tuple, set)):
    return '`when_unchanged` must be a list of attributes'
  unchanged = set(unchanged or [])
  if unchanged & attrs:
    return (f'`when_unchanged` overlaps `attributes` '
            f'({sorted(unchanged & attrs)}): an attribute cannot be both '
            'waived and required to be untouched')
  ungoverned = attrs - _guard_keys(rule)
  if ungoverned and not unchanged:
    return (f'no destination guard for {sorted(ungoverned)}. Add '
            '`when_after`, `when_after_matches` or `when_after_computed` '
            'for those attributes, or `when_unchanged` naming the '
            'live-affecting siblings that make the diff inert. A rule '
            'that does not bound the diff cannot assert it is benign.')
  return None


def _match_after_patterns(patterns, after, unknown=None):
  """Every listed attribute's `after` value fully matches its regex.

  Anchored and single-line on purpose: `re.DOTALL` would let `.+` span
  newlines, so a suffix pattern could be satisfied by an attacker- or
  model-authored multi-line value carrying arbitrary text above it.
  """
  unknown = unknown or {}
  if not patterns:
    return True
  for k, pattern in patterns.items():
    if unknown.get(k):
      return False
    val = after.get(k)
    if not isinstance(val, str):
      return False
    try:
      if not re.fullmatch(pattern, val):
        return False
    except re.error as e:
      _warn_once(f'WARNING: invalid when_after_matches regex for {k}: {e}')
      return False
  return True


def _match_after_computed(spec, hit, unknown, before, after):
  """Every named attribute is FULLY unknown at plan time.

  `true` means every covered attribute in this diff. Two traps this
  guards against, both previously live:

  - `after_unknown` for a block is a per-key structure, so a non-empty
    dict is truthy while nothing inside it is actually computed. Only
    `is True` — a fully-computed leaf — counts.
  - even then, the known remainder must agree, or a partially computed
    block would carry real drift past the guard. This is the same
    fail-closed rule `changed_paths` applies.
  """
  if not spec:
    return True
  names = sorted(hit) if spec is True else list(spec)
  for k in names:
    u = unknown.get(k)
    if u is not True:
      return False
    if strip_unknown(before.get(k), u) != strip_unknown(after.get(k), u):
      return False
  return True


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
    reasons = match_benign(resource_change.get('type', ''), paths, rules,
                           change.get('before') or {},
                           change.get('after') or {},
                           change.get('after_unknown') or {})
    if reasons is not None:
      return 'benign', {'paths': sorted(paths), 'reasons': reasons}
    detail = {'paths': sorted(paths)}
    if computed_only and paths:
      detail['note'] = ('all changed attributes are unknown at plan '
                        'time; cannot verify')
    return 'residual', detail
  return 'residual', {'actions': actions}


def propose_rule(rc, detail):
  """A rule template pre-filled with the OBSERVED before/after values.

  Both ends are populated deliberately. An `attributes`-only rule waives
  every future change to that attribute, including the whole subtree
  under a block attribute, because `changed_paths` reports top-level
  keys only. Emitting the observed values makes the narrow rule the
  default and the broad one a deliberate deletion by the reviewer.
  """
  change = rc.get('change', {})
  before = change.get('before') or {}
  after = change.get('after') or {}
  unknown = change.get('after_unknown') or {}
  paths = detail.get('paths', [])
  proposal = {
      'resource': rc.get('type', ''),
      'attributes': paths,
      'when_before': {
          k: before.get(k) for k in paths
      },
  }
  computed = [k for k in paths if unknown.get(k)]
  if computed:
    proposal['when_after_computed'] = computed
  known = [k for k in paths if not unknown.get(k)]
  if known:
    proposal['when_after'] = {k: after.get(k) for k in known}
  proposal['reason'] = 'TODO: justify why this diff is benign'
  proposal['verified_against'] = {'provider': 'TODO'}
  return proposal


def proposable(detail):
  """False when no rule could be written for this residual.

  An `update` with no comparable changed attributes (only sensitivity or
  metadata differs) would yield a template with empty `attributes`,
  which the guard checker refuses — handing the reviewer a rule that is
  ignored with a warning the moment they commit it.
  """
  return bool(detail.get('paths'))


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
  for rule in rules:
    problem = rule_guard_problem(rule) if isinstance(
        rule, dict) else ('rule is not a mapping')
    if problem and not (isinstance(rule, dict) and rule.get('match')):
      print(
          f'WARNING: benign rule {rule.get("resource", "?") if isinstance(rule, dict) else rule!r} '
          f'will be ignored: {problem}', file=sys.stderr)

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
  substituted_rules = rules_path != os.path.abspath(DEFAULT_RULES)
  if substituted_rules:
    print('WARNING: non-default rules file in force. The verdict below '
          'is NOT judged by the\nfrozen human-owned ruleset; a reviewer '
          'must inspect the file hashed above.\nThis run is ADVISORY: it '
          'can never exit 0. Editing the frozen ruleset is forbidden, so '
          'pointing\nthe gate at another file must not be the cheaper way '
          'to reach a green exit code.')
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
      if (rc.get('change', {}).get('actions') == ['update'] and
          proposable(detail)):
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
  if substituted_rules:
    print('ADVISORY ONLY: judged by a substituted ruleset, not the '
          'frozen one. Not a passing gate.')
    return 3
  return 0


if __name__ == '__main__':
  sys.exit(main())
