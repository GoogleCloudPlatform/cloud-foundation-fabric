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
# dependencies = []
# ///
"""FROZEN SCRIPT — flags destructive changes in a Terraform plan.

Reads `terraform show -json <planfile>` output (file argument or stdin)
after a FAST upgrade and classifies every resource change:

  no-op, read, moved (new address only), clean import   -> expected
  create, update                                        -> review
  update of authoritative IAM, org policies, VPC-SC     -> SENSITIVE
  delete, replace (delete and create, in any order)     -> DESTRUCTIVE
  forget (removed from state, not destroyed)            -> reported

An upgrade should plan in-place updates, moves covered by `moved` blocks
and new resources. This tool never approves a delete or a replace: it
explains why Terraform planned it and leaves the decision to a human.

Exit codes: 0 = no destructive change, 1 = malformed input,
2 = destructive changes found (a human reviews each one before apply).
"""

import argparse
import collections
import hashlib
import json
import os
import re
import sys

import provenance

# Resource types whose loss hurts a landing zone most, with the reason.
CRITICAL_TYPES = (
    (r'^google_project$', 'deleting a project shuts down everything in it, '
     'and project IDs can never be reused'),
    (r'^google_folder$', 'a re-created folder gets a new ID: IAM, org '
     'policies and tags that reference it break'),
    (r'^google_(organization|project)_iam_custom_role$',
     'a deleted custom role keeps its ID reserved for weeks'),
    (r'^google_kms_(crypto_key|key_ring)', 'destroying a key destroys its '
     'versions: data encrypted with it becomes unreadable'),
    (r'^google_storage_bucket$', 'deleting a bucket deletes its objects, '
     'for example Terraform state'),
    (r'^google_logging_\w*(bucket_config|sink)$',
     'audit log routing or retention is lost'),
    (r'^google_access_context_manager_', 'VPC Service Controls changes can '
     'block or expose protected services'),
    (r'^google_(org_policy_policy|\w*organization_policy)$',
     'the organization policy stops being enforced'),
    (r'^google_org_policy_custom_constraint$',
     'a deleted custom constraint cannot be re-created with the same name '
     'right away (see the v52.0.0 note in fast/stages/UPGRADING.md)'),
    (r'^google_compute_(network|subnetwork)$',
     'attached workloads lose connectivity'),
    (r'^google_compute_shared_vpc_',
     'service projects lose access to the host network'),
    (r'^google_service_account$', 'a re-created service account has a new '
     'unique ID: existing bindings do not follow it'),
    (r'^google_tags_tag_(key|value)$',
     'tag bindings and IAM conditions that reference its ID break'),
    (r'^google_iam_workload_identity_pool',
     'deleted pools and providers keep their ID reserved for a while'),
    (r'^google_secret_manager_secret$',
     'deleting a secret deletes all its versions'),
    (r'^google_bigquery_dataset$', 'deleting a dataset deletes its tables'),
    (r'^google_dns_managed_zone$', 'records are lost and delegation breaks'),
    (r'^google_billing_', 'billing access or budgets change'),
    (r'^google_privileged_access_manager_entitlement$',
     'break-glass access through PAM is lost'),
)

# Updates that are not destructive but can silently remove access.
SENSITIVE_TYPES = (
    (r'^google_\w+_iam_(policy|binding)$',
     'authoritative IAM: members not in the code are removed'),
    (r'^google_(org_policy_policy|\w*organization_policy)$',
     'organization policy change'),
    (r'^google_access_context_manager_service_perimeters?$',
     'VPC Service Controls perimeter change'),
    (r'^google_\w+_iam_audit_config$', 'audit log configuration change'),
)

# Terraform's action_reason values, translated into next steps.
REASON_HINTS = {
    'delete_because_no_resource_config':
        'the resource block is gone: if it moved, add a `moved` block',
    'delete_because_no_module':
        'its module call is gone: if the module was renamed or moved, '
        'add a `moved` block',
    'delete_because_wrong_repetition':
        'count/for_each was added or removed: a `moved` block maps the old '
        'address',
    'delete_because_count_index':
        'its count index no longer exists: a `moved` block maps the old '
        'index',
    'delete_because_each_key':
        'its for_each key changed: a `moved` block from the old key avoids '
        'the re-create',
    'delete_because_no_move_target':
        'a `moved` block points to an address that does not exist',
    'replace_because_cannot_update':
        'an attribute that forces replacement changed (see replace paths)',
    'replace_because_tainted':
        'the object is tainted',
    'replace_by_request':
        'replacement was requested with -replace',
    'replace_by_triggers':
        'replace_triggered_by fired',
}

DESTRUCTIVE = ('delete', 'replace')


def _match(rules, resource_type):
  for pattern, reason in rules:
    if re.search(pattern, resource_type or ''):
      return reason
  return None


def classify(rc):
  """Returns (kind, detail) for one resource change entry.

  kind: read | no-op | moved | import | create | update | delete |
  replace | forget | unknown
  """
  change = rc.get('change') or {}
  actions = list(change.get('actions') or [])
  address = rc.get('address')
  previous = rc.get('previous_address')
  detail = {
      'address': address,
      'type': rc.get('type'),
      'actions': actions,
  }
  if previous and previous != address:
    detail['moved_from'] = previous
  if change.get('importing') is not None:
    detail['importing'] = True
  if rc.get('deposed'):
    detail['deposed'] = rc['deposed']
  if rc.get('action_reason'):
    detail['reason'] = rc['action_reason']
    hint = REASON_HINTS.get(rc['action_reason'])
    if hint:
      detail['hint'] = hint
  if change.get('replace_paths'):
    detail['replace_paths'] = change['replace_paths']
  if rc.get('mode') == 'data' or actions == ['read']:
    return 'read', detail
  if actions in ([], ['no-op']):
    if detail.get('importing'):
      return 'import', detail
    return ('moved' if 'moved_from' in detail else 'no-op'), detail
  if actions == ['create']:
    return 'create', detail
  if actions == ['update']:
    return 'update', detail
  if actions == ['forget']:
    return 'forget', detail
  if actions == ['delete']:
    return 'delete', detail
  if sorted(actions) == ['create', 'delete']:
    return 'replace', detail
  return 'unknown', detail


def review(plan):
  """Returns the review of a parsed plan as a dict."""
  counts = collections.Counter()
  destructive, sensitive, moved, forget, unknown = [], [], [], [], []
  for rc in plan.get('resource_changes') or []:
    kind, detail = classify(rc)
    counts[kind] += 1
    if kind in DESTRUCTIVE:
      critical = _match(CRITICAL_TYPES, detail['type'])
      if critical:
        detail['critical'] = critical
      destructive.append(detail)
    elif kind == 'update':
      reason = _match(SENSITIVE_TYPES, detail['type'])
      if reason:
        detail['sensitive'] = reason
        sensitive.append(detail)
    elif kind == 'forget':
      forget.append(detail)
    elif kind == 'unknown':
      unknown.append(detail)
    if 'moved_from' in detail:
      moved.append({'from': detail['moved_from'], 'to': detail['address']})
  destructive.sort(key=lambda d: (not d.get('critical'), d['address'] or ''))
  return {
      'counts': dict(counts),
      'destructive': destructive,
      'sensitive': sensitive,
      'moved': moved,
      'forget': forget,
      'unknown': unknown,
      'drift': len(plan.get('resource_drift') or []),
      'verdict': 'destructive' if destructive or unknown else 'safe',
  }


def load_plan(raw):
  """Parses plan JSON bytes. Returns (plan, error)."""
  try:
    plan = json.loads(raw)
  except (ValueError, UnicodeDecodeError) as e:
    return None, f'input is not valid JSON: {e}'
  # State output (`terraform show -json` without a plan file) has
  # format_version and values, but neither planned_values nor changes.
  if (not isinstance(plan, dict) or 'format_version' not in plan or
      ('resource_changes' not in plan and 'planned_values' not in plan)):
    return None, ('input is not a terraform plan JSON. Run `terraform show '
                  '-json <planfile>` on a saved plan (without a plan file, '
                  'terraform show prints state instead).')
  return plan, None


def _line(d):
  text = f'[{"/".join(d["actions"]) or "?"}] {d["address"]}'
  if d.get('deposed'):
    text += f' (deposed {d["deposed"]})'
  return text


def render(result, origin, digest):
  lines = [
      f'fast-upgrade plan-review | tools {result["tool"]["digest"]}',
      f'input plan {origin} sha256:{digest}',
  ]
  counts = result['counts']
  order = ('create', 'update', 'moved', 'import', 'delete', 'replace', 'forget',
           'unknown')
  summary = ', '.join(f'{counts.get(k, 0)} {k}' for k in order)
  lines.append(f'changes: {summary} ({counts.get("no-op", 0)} no-op, '
               f'{counts.get("read", 0)} read)')
  if result['drift']:
    lines.append(f'drift: {result["drift"]} object(s) changed outside '
                 'Terraform since the last apply')
  if result['destructive']:
    lines.append('')
    lines.append(f'DESTRUCTIVE ({len(result["destructive"])})')
    for d in result['destructive']:
      lines.append('  ' + _line(d) + f' ({d["type"]})')
      if d.get('critical'):
        lines.append(f'      CRITICAL: {d["critical"]}')
      if d.get('reason'):
        lines.append(f'      why: {d["reason"]}' +
                     (f': {d["hint"]}' if d.get('hint') else ''))
      if d.get('replace_paths'):
        paths = ', '.join(
            '.'.join(str(p) for p in path) for path in d['replace_paths'][:5])
        lines.append(f'      replace paths: {paths}')
  if result['unknown']:
    lines.append('')
    lines.append(f'UNRECOGNIZED ACTIONS ({len(result["unknown"])})')
    for d in result['unknown']:
      lines.append('  ' + _line(d))
  if result['sensitive']:
    lines.append('')
    lines.append(f'SENSITIVE UPDATES ({len(result["sensitive"])})')
    for d in result['sensitive']:
      lines.append(f'  {_line(d)}: {d["sensitive"]}')
  if result['moved']:
    lines.append('')
    lines.append(f'MOVED ({len(result["moved"])})')
    for m in result['moved']:
      lines.append(f'  {m["from"]} -> {m["to"]}')
  if result['forget']:
    lines.append('')
    lines.append(f'REMOVED FROM STATE, NOT DESTROYED ({len(result["forget"])})')
    for d in result['forget']:
      lines.append('  ' + _line(d))
  lines.append('')
  if result['verdict'] == 'destructive':
    total = len(result['destructive']) + len(result['unknown'])
    lines.append(f'VERDICT: {total} destructive or unrecognized change(s). '
                 'Do not apply until a human has reviewed each one: add '
                 '`moved` blocks or `terraform state mv` where the object '
                 'only changed address, or accept it explicitly.')
  elif not sum(v for k, v in counts.items() if k not in ('no-op', 'read')):
    lines.append('VERDICT: no changes. Expected after an upgrade that only '
                 'touched code, docs or defaults; if changes were expected, '
                 'check that the right stage folder and variables were '
                 'planned.')
  else:
    lines.append('VERDICT: no deletes or replacements. Review the updates '
                 'above (sensitive ones first) before applying.')
  return '\n'.join(lines)


def main(argv=None):
  parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
  parser.add_argument('plan', nargs='?',
                      help='Plan JSON file (default: stdin).')
  parser.add_argument('--json', action='store_true', help='Print JSON.')
  args = parser.parse_args(argv)
  if args.plan:
    try:
      with open(args.plan, 'rb') as f:
        raw = f.read()
    except OSError as e:
      print(f'ERROR: cannot read {args.plan}: {e.strerror}', file=sys.stderr)
      return 1
    origin = os.path.abspath(args.plan)
  else:
    stream = getattr(sys.stdin, 'buffer', sys.stdin)
    raw = stream.read()
    if isinstance(raw, str):
      raw = raw.encode('utf-8')
    origin = '<stdin>'
  plan, error = load_plan(raw)
  if error:
    print(f'ERROR: {error}', file=sys.stderr)
    return 1
  digest = hashlib.sha256(raw).hexdigest()[:16]
  result = review(plan)
  result['tool'] = {
      'name': 'plan_review.py',
      'digest': provenance.tool_digest()
  }
  result['input'] = {'plan': origin, 'sha256': digest}
  if args.json:
    print(json.dumps(result, indent=2, sort_keys=True))
  else:
    print(render(result, origin, digest))
  return 2 if result['verdict'] == 'destructive' else 0


if __name__ == '__main__':
  sys.exit(main())
