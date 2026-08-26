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
"""Unit tests for the frozen tools (coverage, verify_plan, inventory,
integrity, manifest_init, manifest_from_state).

Run with: uv run --with pyyaml --with pytest -m pytest \
            skills/fabric-importer/tests -q
      or: uv run --with pyyaml skills/fabric-importer/tests/test_scripts.py

The scripts under test declare their dependencies inline (PEP 723), but
this file is imported rather than executed as a script, so the `--with`
flags supply them here. `python3` with PyYAML installed works too.
"""

import contextlib
import io
import json
import os
import sys
import tempfile
import unittest

_BASE = os.path.join(os.path.dirname(__file__), '..')
sys.path.insert(0, os.path.join(_BASE, 'scripts'))

import yaml  # noqa: E402

import coverage  # noqa: E402
import integrity  # noqa: E402
import inventory  # noqa: E402
import manifest_from_state  # noqa: E402
import manifest_init  # noqa: E402
import verify_plan  # noqa: E402

_BENIGN_RULES = [
    {
        'resource': 'google_folder',
        'attributes': ['timeouts'],
        'when_before': {
            'timeouts': {}
        },
        'when_after': {
            'timeouts': None
        },
        'reason': 'import preview artifact',
    },
    # Hardening round 19: the wildcard `all-changes-computed` rule kind
    # was removed (it laundered "cannot verify" into "no change"); one
    # is kept here to prove verify_plan ignores the rule kind entirely.
    {
        'resource': '*',
        'match': 'all-changes-computed',
        'reason': 'computed only',
    },
]


def _rc(rtype, actions, before=None, after=None, unknown=None, importing=False):
  change = {'actions': actions, 'before': before or {}, 'after': after or {}}
  if unknown is not None:
    change['after_unknown'] = unknown
  if importing:
    change['importing'] = {'id': 'x'}
  return {'type': rtype, 'address': f'{rtype}.x', 'change': change}


class TestVerifyPlanClassify(unittest.TestCase):

  def test_clean_import(self):
    v, _ = verify_plan.classify(_rc('google_folder', ['no-op'], importing=True),
                                _BENIGN_RULES)
    self.assertEqual(v, 'ok-import')

  def test_noop_and_read(self):
    self.assertEqual(
        verify_plan.classify(_rc('t', ['no-op']), _BENIGN_RULES)[0], 'ok')
    self.assertEqual(
        verify_plan.classify(_rc('t', ['read']), _BENIGN_RULES)[0], 'ok')

  def test_benign_attribute_rule(self):
    rc = _rc('google_folder', ['update'], before={
        'timeouts': {},
        'name': 'a'
    }, after={
        'timeouts': None,
        'name': 'a'
    })
    v, detail = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'benign')
    self.assertEqual(detail['paths'], ['timeouts'])

  def test_partially_benign_is_residual(self):
    rc = _rc('google_folder', ['update'], before={
        'timeouts': {},
        'display_name': 'a'
    }, after={
        'timeouts': None,
        'display_name': 'b'
    })
    v, detail = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')
    self.assertIn('display_name', detail['paths'])

  def test_benign_rule_is_type_scoped(self):
    rc = _rc('google_project', ['update'], before={'timeouts': {}},
             after={'timeouts': None})
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')

  def test_all_changes_computed_is_now_residual(self):
    """Hardening round 19: fully-unknown changes are unverifiable, so
    they are residuals — even with an all-changes-computed rule present
    (the rule kind is ignored)."""
    rc = _rc('google_anything', ['update'], before={'etag': 'a'}, after={},
             unknown={'etag': True})
    v, detail = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')
    self.assertIn('unknown at plan time', detail.get('note', ''))

  def test_fully_unknown_block_masking_real_drift_is_residual(self):
    """The reviewer repro: `after_unknown: {x: [true]}` strips both
    sides to equal, which used to pass the wildcard rule while hiding a
    genuine before/after difference. Must be residual now."""
    rc = _rc('google_anything', ['update'], before={'x': [{
        'a': 1
    }]}, after={'x': [{
        'a': 2
    }]}, unknown={'x': [True]})
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')

  def test_computed_plus_real_change_is_residual(self):
    rc = _rc('google_anything', ['update'], before={
        'etag': 'a',
        'name': 'x'
    }, after={'name': 'y'}, unknown={'etag': True})
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')

  def test_partially_computed_block_hiding_real_drift_is_residual(self):
    """A block with one computed member must not launder in-block drift.

    Regression: `after_unknown: {block: [{sub: True}]}` is truthy, and the
    old changed_paths() skipped the before/after comparison for any truthy
    entry, so genuine drift inside the block rode the wildcard
    all-changes-computed rule into a benign verdict.
    """
    rc = _rc('google_privateca_ca_pool', ['update'],
             before={'publishing_options': [{
                 'publish_ca_cert': True
             }]}, after={'publishing_options': [{
                 'publish_ca_cert': False
             }]}, unknown={'publishing_options': [{
                 'issuance_policy': True
             }]})
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')

  def test_empty_unknown_block_marker_does_not_mask_drift(self):
    """`[{}]` (nothing actually computed) is truthy but must not pass."""
    rc = _rc('google_anything', ['update'],
             before={'settings': [{
                 'tier': 'a'
             }]}, after={'settings': [{
                 'tier': 'b'
             }]}, unknown={'settings': [{}]})
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')

  def test_partially_computed_block_without_drift_needs_scoped_rule(self):
    """Hardening round 19: with the wildcard rule gone, the legitimate
    computed-refresh case needs a rule naming the type and attribute —
    the same standard as every other benign class."""
    rc = _rc('google_anything', ['update'],
             before={'settings': [{
                 'tier': 'a',
                 'sha': 'old'
             }]}, after={'settings': [{
                 'tier': 'a'
             }]}, unknown={'settings': [{
                 'sha': True
             }]})
    # No scoped rule -> residual (was benign via the wildcard rule).
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')
    # A partially-computed block is NOT a computed destination: only a
    # fully-unknown leaf counts, and the known remainder must agree.
    partial = _BENIGN_RULES + [{
        'resource': 'google_anything',
        'attributes': ['settings'],
        'when_after_computed': ['settings'],
        'reason': 'computed refresh'
    }]
    v, _ = verify_plan.classify(rc, partial)
    self.assertEqual(v, 'residual')
    fully_computed = _rc('google_anything', ['update'],
                         before={'settings': [{
                             'tier': 'a'
                         }]}, after={}, unknown={'settings': True})
    v, _ = verify_plan.classify(fully_computed, partial)
    self.assertEqual(v, 'benign')

  def test_strip_unknown_masks_only_computed_subtrees(self):
    self.assertIsNone(verify_plan.strip_unknown('x', True))
    self.assertEqual(verify_plan.strip_unknown({
        'a': 1,
        'b': 2
    }, {'b': True}), {'a': 1})
    self.assertEqual(
        verify_plan.strip_unknown([{
            'a': 1,
            'b': 2
        }], [{
            'b': True
        }]), [{
            'a': 1
        }])
    self.assertEqual(verify_plan.strip_unknown({'a': 1}, False), {'a': 1})

  def test_capability_gap_block_removal_is_residual(self):
    """Upstream #4106: modules/certificate-authority-service cannot express
    publishing_options, so adopting a live pool plans a block REMOVAL.

    That is a module capability gap (raw-resource fallback), never a
    benign drift: an apply would reset live CA-cert/CRL publication.
    """
    rc = _rc(
        'google_privateca_ca_pool', ['update'], before={
            'publishing_options': [{
                'encoding_format': 'PEM',
                'publish_ca_cert': True,
                'publish_crl': False
            }]
        }, after={'publishing_options': []})
    v, detail = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')
    self.assertEqual(detail['paths'], ['publishing_options'])

  def test_destroy_never_benign(self):
    rc = _rc('google_folder', ['delete', 'create'], before={'timeouts': {}},
             after={'timeouts': None})
    v, _ = verify_plan.classify(rc, _BENIGN_RULES)
    self.assertEqual(v, 'residual')

  def test_no_rules_means_strict(self):
    rc = _rc('google_folder', ['update'], before={'timeouts': {}},
             after={'timeouts': None})
    v, _ = verify_plan.classify(rc, [])
    self.assertEqual(v, 'residual')

  def test_shipped_ruleset_parses(self):
    rules = verify_plan.load_rules(verify_plan.DEFAULT_RULES)
    self.assertTrue(any(r.get('resource') == 'google_folder' for r in rules))

  def test_every_shipped_rule_bounds_its_destination(self):
    """A rule guarding only `when_before` accepts an ARBITRARY new value:
    the sink rule matched a live empty description and then allowed any
    replacement, so the gate reported CONVERGED for a plan that really
    writes to the live sink on apply. Every shipped rule must bound the
    destination too."""
    rules = verify_plan.load_rules(verify_plan.DEFAULT_RULES)
    self.assertTrue(rules)
    unguarded = [(r.get('resource'), verify_plan.rule_guard_problem(r))
                 for r in rules
                 if verify_plan.rule_guard_problem(r)]
    self.assertEqual(unguarded, [])

  def test_unguarded_rule_is_refused_not_applied(self):
    rc = _rc('google_folder', ['update'], before={'timeouts': {}},
             after={'timeouts': None})
    unguarded = [{
        'resource': 'google_folder',
        'attributes': ['timeouts'],
        'reason': 'no destination guard',
    }]
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
      v, _ = verify_plan.classify(rc, unguarded)
    self.assertEqual(v, 'residual')
    self.assertIn('no destination guard', err.getvalue())

  def test_when_after_blocks_a_real_write_to_live(self):
    """The hole, stated as a test: same live value, different
    destination. `when_before` alone said benign; the destination guard
    must make it residual."""
    rules = [{
        'resource': 'google_logging_organization_sink',
        'attributes': ['description'],
        'when_before': {
            'description': ''
        },
        'when_after_matches': {
            'description': r'.+ \(Terraform-managed\)\.'
        },
        'reason': 'module default applied to an empty live description',
    }]
    benign = _rc('google_logging_organization_sink', ['update'],
                 before={'description': ''},
                 after={'description': 'audit (Terraform-managed).'})
    self.assertEqual(verify_plan.classify(benign, rules)[0], 'benign')
    writes_real_text = _rc('google_logging_organization_sink', ['update'],
                           before={'description': ''},
                           after={'description': 'PROD SINK - do not touch'})
    self.assertEqual(
        verify_plan.classify(writes_real_text, rules)[0], 'residual')

  def test_secondary_ip_range_flag_alone_is_benign_with_ranges_residual(self):
    """send_secondary_ip_range_if_empty makes the provider transmit an
    empty secondary-range list, so it is the one rule whose misfire is
    destructive. The flag flip alone is a preview artifact; the flag
    flip PLUS a secondary_ip_range change is a deletion and must stay
    residual."""
    rules = verify_plan.load_rules(verify_plan.DEFAULT_RULES)
    flag_only = _rc('google_compute_subnetwork', ['update'],
                    before={'send_secondary_ip_range_if_empty': None},
                    after={'send_secondary_ip_range_if_empty': True})
    self.assertEqual(verify_plan.classify(flag_only, rules)[0], 'benign')
    with_range_removal = _rc(
        'google_compute_subnetwork', ['update'], before={
            'send_secondary_ip_range_if_empty':
                None,
            'secondary_ip_range': [{
                'range_name': 'pods',
                'ip_cidr_range': '10.0.0.0/16'
            }]
        }, after={
            'send_secondary_ip_range_if_empty': True,
            'secondary_ip_range': []
        })
    v, detail = verify_plan.classify(with_range_removal, rules)
    self.assertEqual(v, 'residual')
    self.assertIn('secondary_ip_range', detail['paths'])

  def test_terraform_labels_rule_is_bounded_by_its_live_siblings(self):
    """terraform_labels is provider bookkeeping; the attributes that
    really carry labels to the API are `labels` and `effective_labels`.
    The rule must fire for bookkeeping alone and must NOT fire when a
    real label write rides along.

    Guarding this rule on `when_after_computed` instead would have
    contradicted its own recorded observation (`{} -> {...}`, a concrete
    map) and killed all ten label rules, turning every labelled import
    into a false residual."""
    rules = verify_plan.load_rules(verify_plan.DEFAULT_RULES)
    bookkeeping = _rc('google_project', ['update'],
                      before={'terraform_labels': {}},
                      after={'terraform_labels': {
                          'goog-managed': 'true'
                      }})
    self.assertEqual(verify_plan.classify(bookkeeping, rules)[0], 'benign')
    real_write = _rc(
        'google_project', ['update'], before={
            'terraform_labels': {},
            'labels': {}
        }, after={
            'terraform_labels': {
                'owner': 'someone-else'
            },
            'labels': {
                'owner': 'someone-else'
            }
        })
    self.assertEqual(verify_plan.classify(real_write, rules)[0], 'residual')

  def test_partially_computed_map_cannot_launder_a_concrete_write(self):
    """after_unknown for a map is a PER-KEY structure, so a non-empty
    dict is truthy while nothing inside it is computed. A guard testing
    truthiness accepted an arbitrary concrete write."""
    rules = [{
        'resource': 'google_project',
        'attributes': ['terraform_labels'],
        'when_before': {
            'terraform_labels': {}
        },
        'when_after_computed': ['terraform_labels'],
        'reason': 'computed bookkeeping',
    }]
    laundered = _rc('google_project', ['update'],
                    before={'terraform_labels': {}},
                    after={'terraform_labels': {
                        'owner': 'attacker'
                    }},
                    unknown={'terraform_labels': {
                        'goog-provisioned': True
                    }})
    self.assertEqual(verify_plan.classify(laundered, rules)[0], 'residual')

  def test_when_after_null_does_not_accept_an_unknown_destination(self):
    """`after` holds null for a computed value exactly as it does for an
    absent key, so an exact null guard would launder \'the provider will
    decide later\' into \'no change\'."""
    rules = [{
        'resource': 'google_folder',
        'attributes': ['timeouts'],
        'when_before': {
            'timeouts': {}
        },
        'when_after': {
            'timeouts': None
        },
        'reason': 'import preview artifact',
    }]
    known_null = _rc('google_folder', ['update'], before={'timeouts': {}},
                     after={'timeouts': None})
    self.assertEqual(verify_plan.classify(known_null, rules)[0], 'benign')
    unknown_dest = _rc('google_folder', ['update'], before={'timeouts': {}},
                       after={}, unknown={'timeouts': True})
    self.assertEqual(verify_plan.classify(unknown_dest, rules)[0], 'residual')

  def test_regex_guard_is_single_line(self):
    """re.DOTALL would let a suffix pattern be satisfied by a multi-line
    value carrying arbitrary text above the expected tail."""
    rules = verify_plan.load_rules(verify_plan.DEFAULT_RULES)
    smuggled = _rc(
        'google_logging_organization_sink', ['update'],
        before={'description': ''},
        after={'description': 'PROD - do not touch\nx (Terraform-managed).'})
    self.assertEqual(verify_plan.classify(smuggled, rules)[0], 'residual')

  def test_rule_may_not_waive_an_attribute_it_does_not_guard(self):
    """Guards were rule-level while credit was attribute-level: one
    guarded attribute waived every other attribute the rule named."""
    rule = {
        'resource': 'google_project',
        'attributes': ['terraform_labels', 'description'],
        'when_after_computed': ['terraform_labels'],
        'reason': 'partial guard',
    }
    self.assertIn('no destination guard',
                  verify_plan.rule_guard_problem(rule) or '')

  def test_malformed_guard_shapes_are_refused_not_crashes(self):
    for bad in ({
        'resource': 'r',
        'attributes': ['a'],
        'when_after': 'x'
    }, {
        'resource': 'r',
        'attributes': ['a'],
        'when_after_computed': 'a'
    }, {
        'resource': 'r',
        'attributes': ['a'],
        'when_unchanged': 'a'
    }, {
        'resource': 'r',
        'attributes': [],
        'when_after': {
            'a': 1
        }
    }, {
        'resource': 'r',
        'attributes': ['a'],
        'when_unchanged': ['a']
    }):
      self.assertIsNotNone(verify_plan.rule_guard_problem(bad), bad)

  def test_when_before_guard(self):
    # D-03 rule: only empty-string live descriptions are benign.
    rules = [{
        'resource': 'google_logging_organization_sink',
        'attributes': ['description'],
        'when_before': {
            'description': ''
        },
        'when_after_matches': {
            'description': r'.+ \(Terraform-managed\)\.'
        },
        'reason': 'coalesce empty-string',
    }]
    base = {
        'type': 'google_logging_organization_sink',
        'address': 's',
        'change': {
            'actions': ['update'],
            'before': {
                'description': ''
            },
            'after': {
                'description': 'x (Terraform-managed).'
            }
        }
    }
    self.assertEqual(verify_plan.classify(base, rules)[0], 'benign')
    drifted = {
        'type': 'google_logging_organization_sink',
        'address': 's',
        'change': {
            'actions': ['update'],
            'before': {
                'description': 'real live text'
            },
            'after': {
                'description': 'other'
            }
        }
    }
    self.assertEqual(verify_plan.classify(drifted, rules)[0], 'residual')

  def test_terraform_data_exemption_is_narrow(self):
    """Hardening round 19: the exemption requires the EXACT builtin
    provider AND create-only. A terraform_data delete, or a same-named
    type from another provider, is classified normally — the blanket
    exemption was a residual-laundering primitive."""
    ok = {
        'type': 'terraform_data',
        'provider_name': 'terraform.io/builtin/terraform',
        'address': 'terraform_data.checks',
        'change': {
            'actions': ['create'],
            'before': None,
            'after': {}
        }
    }
    self.assertEqual(verify_plan.classify(ok, [])[0], 'ok')
    no_provider = {
        'type': 'terraform_data',
        'address': 'terraform_data.checks',
        'change': {
            'actions': ['create'],
            'before': None,
            'after': {}
        }
    }
    self.assertEqual(verify_plan.classify(no_provider, [])[0], 'residual')
    delete = {
        'type': 'terraform_data',
        'provider_name': 'terraform.io/builtin/terraform',
        'address': 'terraform_data.x',
        'change': {
            'actions': ['delete']
        }
    }
    self.assertEqual(verify_plan.classify(delete, [])[0], 'residual')
    endswith_spoof = {
        'type': 'terraform_data',
        'provider_name': 'registry.evil/terraform.io/builtin/terraform',
        'address': 'terraform_data.x',
        'change': {
            'actions': ['create'],
            'after': {}
        }
    }
    self.assertEqual(verify_plan.classify(endswith_spoof, [])[0], 'residual')


class TestIntegrity(unittest.TestCase):
  """Tamper-evidence over the frozen tools."""

  def _fake_tools(self, tmp, contents):
    for name, body in contents.items():
      with open(os.path.join(tmp, name), 'w', encoding='utf-8') as f:
        f.write(body)
    return tmp

  def test_digest_is_stable_for_identical_content(self):
    with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
      c = {n: f'# {n}\n' for n in integrity.FROZEN_FILES}
      self.assertEqual(integrity.frozen_digest(self._fake_tools(a, c)),
                       integrity.frozen_digest(self._fake_tools(b, dict(c))))

  def test_editing_the_ruleset_changes_the_digest(self):
    """The round-14 scenario: an entry appended to benign-drift.yaml."""
    with tempfile.TemporaryDirectory() as t:
      c = {n: f'# {n}\n' for n in integrity.FROZEN_FILES}
      before = integrity.frozen_digest(self._fake_tools(t, c))
      c['benign-drift.yaml'] += '  - resource: google_privateca_ca_pool\n'
      after = integrity.frozen_digest(self._fake_tools(t, c))
      self.assertNotEqual(before, after)

  def test_editing_a_gate_changes_the_digest(self):
    with tempfile.TemporaryDirectory() as t:
      c = {n: f'# {n}\n' for n in integrity.FROZEN_FILES}
      before = integrity.frozen_digest(self._fake_tools(t, c))
      c['verify_plan.py'] += 'def classify(*a): return "ok", None\n'
      self.assertNotEqual(before,
                          integrity.frozen_digest(self._fake_tools(t, c)))

  def test_missing_file_is_distinct_from_empty_file(self):
    """Deleting a ruleset must not hash the same as emptying it."""
    with tempfile.TemporaryDirectory() as t:
      c = {n: '' for n in integrity.FROZEN_FILES}
      empty = integrity.frozen_digest(self._fake_tools(t, c))
      os.remove(os.path.join(t, 'benign-drift.yaml'))
      self.assertNotEqual(empty, integrity.frozen_digest(t))

  def test_stamp_is_one_line_and_carries_the_digest(self):
    s = integrity.stamp()
    self.assertNotIn('\n', s)
    self.assertIn(integrity.frozen_digest(), s)


class TestCoverage(unittest.TestCase):

  _INVENTORY = [
      {
          'key': '//x/folders/1',
          'asset_type': 'f',
          'level': 'organization',
          'container': 'organizations/1'
      },
      {
          'key': '//x/folders/2',
          'asset_type': 'f',
          'level': 'folder',
          'container': 'folders/1'
      },
      {
          'key': '//x/folders/1#iam',
          'asset_type': 'iam',
          'level': 'folder',
          'container': 'organizations/1'
      },
  ]

  def test_fully_reconciled(self):
    cmap = {
        '//x/folders/1': ['module.ff.google_folder.f["a"]'],
        '//x/folders/2': ['module.ff.google_folder.f["b"]'],
    }
    waivers = [{'key': '//x/folders/1#iam', 'reason': 'not managed'}]
    addrs = set(v[0] for v in cmap.values())
    missing, problems = coverage.reconcile(self._INVENTORY, cmap, waivers,
                                           addrs)
    self.assertEqual(missing, [])
    self.assertEqual(problems, [])

  def test_missing_key_reported(self):
    missing, _ = coverage.reconcile(self._INVENTORY, {}, [], set())
    self.assertEqual(len(missing), 3)

  def test_dangling_address_reported(self):
    cmap = {'//x/folders/1': ['module.nope.addr']}
    _, problems = coverage.reconcile(self._INVENTORY, cmap, [], set())
    self.assertTrue(any('no import block' in p for p in problems))

  def test_stale_map_entry_reported(self):
    cmap = {'//x/gone': ['a']}
    _, problems = coverage.reconcile(self._INVENTORY, cmap, [], {'a'})
    self.assertTrue(any('not in inventory' in p for p in problems))

  def test_unsigned_waivers_are_reported_not_fatal(self):
    """Attribution is visible by default but must not fail the gate.

    Requiring signed_by where no human is present would only produce
    invented signatures, which defeats the audit it exists to support.
    """
    waivers = [{'key': '//k/a', 'reason': 'google-managed'}]
    self.assertEqual(coverage.unsigned_waivers(waivers), ['//k/a'])
    missing, problems = coverage.reconcile([{
        'key': '//k/a'
    }], {}, waivers, set())
    self.assertEqual(missing, [])
    self.assertEqual(problems, [])

  def test_unsigned_waivers_fail_when_required(self):
    waivers = [{'key': '//k/a', 'reason': 'google-managed'}]
    _, problems = coverage.reconcile([{
        'key': '//k/a'
    }], {}, waivers, set(), require_signed=True)
    self.assertTrue(any('signed_by' in p for p in problems), problems)

  def test_signed_waiver_passes_when_required(self):
    waivers = [{
        'key': '//k/a',
        'reason': 'google-managed',
        'signed_by': 'a.person@example.com 2026-08-23'
    }]
    self.assertEqual(coverage.unsigned_waivers(waivers), [])
    _, problems = coverage.reconcile([{
        'key': '//k/a'
    }], {}, waivers, set(), require_signed=True)
    self.assertEqual(problems, [])

  def test_blank_signed_by_counts_as_unsigned(self):
    self.assertEqual(
        coverage.unsigned_waivers([{
            'key': '//k/a',
            'signed_by': '   '
        }]), ['//k/a'])

  def test_waiver_without_reason_fails(self):
    waivers = [{'key': '//x/folders/1'}]
    _, problems = coverage.reconcile(self._INVENTORY, {}, waivers, set())
    self.assertTrue(any('without reason' in p for p in problems))

  def test_waived_and_mapped_contradiction(self):
    cmap = {'//x/folders/1': ['a']}
    waivers = [{'key': '//x/folders/1', 'reason': 'r'}]
    _, problems = coverage.reconcile(self._INVENTORY, cmap, waivers, {'a'})
    self.assertTrue(any('both waived and mapped' in p for p in problems))

  def test_parse_import_addresses(self):
    with tempfile.TemporaryDirectory() as td:
      with open(os.path.join(td, 'x-import.tf'), 'w') as f:
        f.write('import {\n'
                '  to = module.organization.google_org_policy_policy'
                '.default["iam.foo"]\n'
                '  id = "organizations/1/policies/iam.foo"\n'
                '}\n\n'
                'import {\n'
                '  to = google_compute_network.net\n'
                '  id = "projects/p/global/networks/n"\n'
                '}\n')
      addrs = coverage.parse_import_addresses(td)
    self.assertEqual(
        addrs, {
            'module.organization.google_org_policy_policy'
            '.default["iam.foo"]', 'google_compute_network.net'
        })


class TestInventoryHelpers(unittest.TestCase):

  _FOLDER_TYPE = 'cloudresourcemanager.googleapis.com/Folder'

  def test_asset_level_leaf_assets(self):
    # Leaf assets: ancestors[0] is the container.
    self.assertEqual(
        inventory.asset_level({'ancestors': ['folders/2', 'organizations/1']}),
        'folder')
    self.assertEqual(
        inventory.asset_level(
            {'ancestors': ['projects/9', 'folders/2', 'organizations/1']}),
        'project')

  def test_asset_level_container_assets_use_parent(self):
    # Container assets list themselves first in `ancestors`:
    # a top-level folder's CONTAINER level is organization.
    self.assertEqual(
        inventory.asset_level({
            'assetType': self._FOLDER_TYPE,
            'ancestors': ['folders/2', 'organizations/1'],
        }), 'organization')
    self.assertEqual(
        inventory.asset_level({
            'assetType': self._FOLDER_TYPE,
            'ancestors': ['folders/3', 'folders/2', 'organizations/1'],
        }), 'folder')

  def test_normalize_iam_skips_leaf_assets(self):
    # TagValue IAM must not pollute org-level IAM.
    entries = inventory._normalize_iam([
        {
            'name': '//cloudresourcemanager.googleapis.com/tagValues/9',
            'assetType': 'cloudresourcemanager.googleapis.com/TagValue',
            'ancestors': ['organizations/1'],
            'iamPolicy': {
                'bindings': []
            }
        },
        {
            'name': '//cloudresourcemanager.googleapis.com/folders/2',
            'assetType': self._FOLDER_TYPE,
            'ancestors': ['folders/2', 'organizations/1'],
            'iamPolicy': {
                'bindings': []
            }
        },
    ])
    self.assertEqual(len(entries), 1)
    # Folder IAM is folder-level regardless of where the folder sits.
    self.assertEqual(entries[0]['level'], 'folder')
    self.assertTrue(entries[0]['key'].endswith('folders/2#iam'))

  def _pam_grant_asset(self, state='ACTIVE', target='folders/2',
                       role='roles/owner', requester='alice@example.com'):
    name = (f'{target}/locations/global/entitlements/e/grants/g')
    return {
        'name': f'//privilegedaccessmanager.googleapis.com/{name}',
        'assetType': inventory.PAM_GRANT_TYPE,
        'ancestors': ['folders/2', 'organizations/1'],
        'resource': {
            'data': {
                'name': name,
                'state': state,
                'requester': requester,
                'privilegedAccess': {
                    'gcpIamAccess': {
                        'resource':
                            f'//cloudresourcemanager.googleapis.com/{target}',
                        'roleBindings': [{
                            'role': role
                        }],
                    }
                },
            }
        },
    }

  def _folder_iam_asset(self, bindings):
    return {
        'name': '//cloudresourcemanager.googleapis.com/folders/2',
        'assetType': self._FOLDER_TYPE,
        'ancestors': ['folders/2', 'organizations/1'],
        'iamPolicy': {
            'bindings': bindings
        },
    }

  _PAM_CONDITION = {
      'title': 'pam-managed',
      'expression': 'request.time < timestamp("2026-01-01T00:00:00Z")'
  }

  def test_pam_grant_bindings_are_stripped_before_denominator(self):
    del inventory.PAM_EXCLUSIONS[:]
    records = inventory._pam_grant_records([self._pam_grant_asset()],
                                           inventory.ProjectRegistry())
    assets = [
        self._folder_iam_asset([
            {
                'role': 'roles/owner',
                'members': ['user:alice@example.com'],
                'condition': dict(self._PAM_CONDITION),
            },
            {
                'role': 'roles/viewer',
                'members': ['user:bob@example.com']
            },
        ])
    ]
    inventory._strip_pam_grant_bindings(assets, records)
    # The grant binding is gone, the permanent one stays, and the
    # container still mints a #iam entry for its real configuration.
    policy = assets[0]['iamPolicy']
    self.assertEqual([b['role'] for b in policy['bindings']], ['roles/viewer'])
    self.assertEqual(len(inventory._normalize_iam(assets)), 1)
    self.assertEqual(len(inventory.PAM_EXCLUSIONS), 1)
    excl = inventory.PAM_EXCLUSIONS[0]
    self.assertEqual(excl['container'], 'folders/2')
    self.assertEqual(excl['role'], 'roles/owner')
    self.assertEqual(excl['member'], 'user:alice@example.com')
    del inventory.PAM_EXCLUSIONS[:]

  def test_pam_only_policy_never_enters_denominator(self):
    # A container whose entire policy is machine-managed grant bindings
    # must not mint a #iam entry: exclusion is structural, not a waiver.
    del inventory.PAM_EXCLUSIONS[:]
    records = inventory._pam_grant_records([self._pam_grant_asset()],
                                           inventory.ProjectRegistry())
    assets = [
        self._folder_iam_asset([{
            'role': 'roles/owner',
            'members': ['user:alice@example.com'],
            'condition': dict(self._PAM_CONDITION),
        }])
    ]
    inventory._strip_pam_grant_bindings(assets, records)
    self.assertEqual(inventory._normalize_iam(assets), [])
    self.assertEqual(len(inventory.PAM_EXCLUSIONS), 1)
    del inventory.PAM_EXCLUSIONS[:]

  def test_pam_matching_is_narrow(self):
    # All three legs must hold: an unconditional binding for the same
    # (role, member) is permanent configuration and stays; a conditional
    # binding for a different member stays; an inactive grant matches
    # nothing at all.
    del inventory.PAM_EXCLUSIONS[:]
    registry = inventory.ProjectRegistry()
    records = inventory._pam_grant_records([
        self._pam_grant_asset(),
        self._pam_grant_asset(state='EXPIRED', role='roles/editor')
    ], registry)
    self.assertEqual(len(records), 1)
    bindings = [
        {
            # same role+member as the grant, but no condition: permanent.
            'role': 'roles/owner',
            'members': ['user:alice@example.com'],
        },
        {
            # conditional, same role, different member: kept.
            'role': 'roles/owner',
            'members': ['user:carol@example.com'],
            'condition': dict(self._PAM_CONDITION),
        },
    ]
    assets = [self._folder_iam_asset(bindings)]
    inventory._strip_pam_grant_bindings(assets, records)
    self.assertEqual(len(assets[0]['iamPolicy']['bindings']), 2)
    self.assertEqual(inventory.PAM_EXCLUSIONS, [])

  def test_pam_grant_type_cannot_be_declared_in_manifest(self):
    with self.assertRaises(SystemExit) as ctx:
      inventory.validate_manifest_types([{'type': inventory.PAM_GRANT_TYPE}])
    self.assertIn('never imported', str(ctx.exception))

  def test_search_shaped_asset_fallbacks(self):
    # Round-11: search-all-resources results lack `ancestors`; level,
    # container, and subtree filtering fall back to search-shape fields.
    a = {
        'name':
            '//dns.googleapis.com/projects/p/managedZones/z',
        'assetType':
            'dns.googleapis.com/ManagedZone',
        'project':
            'projects/123456',
        'parentFullResourceName':
            '//cloudresourcemanager.googleapis.com/projects/123456',
        'organization':
            'organizations/1',
        'folders': ['folders/22']
    }
    self.assertEqual(inventory.asset_level(a), 'project')
    entries = inventory._normalize_resources([a])
    self.assertEqual(entries[0]['container'], 'projects/123456')
    # in_subtree synthesizes ancestors from search-shape fields.
    self.assertTrue(inventory.in_subtree(a, ['folders/22'], []))
    self.assertFalse(inventory.in_subtree(a, [], ['projects/123456']))

  def _collect_with_failing_sweep(self, manifest):
    """Runs collect() with every gcloud sweep recording a failure."""
    real = inventory.run_json

    def fake(cmd, **kwargs):
      del cmd, kwargs
      inventory.SWEEP_FAILURES.append('simulated: gcloud asset list')
      return []

    inventory.run_json = fake
    try:
      return inventory.collect(manifest)
    finally:
      inventory.run_json = real

  def test_sweep_failures_fail_closed(self):
    # Tolerated enumeration failures must hard-fail collect() at the
    # end - a silently shrunken denominator is never acceptable.
    with self.assertRaises(SystemExit) as ctx:
      self._collect_with_failing_sweep({
          'scope': {
              'root': 'organizations/1'
          },
          'types': [{
              'type': 'storage.googleapis.com/Bucket',
              'levels': ['project']
          }]
      })
    self.assertEqual(ctx.exception.code, 3)

  def test_sweep_failures_do_not_leak_into_the_next_collect(self):
    """SWEEP_FAILURES is module-global and was never reset, so a second
    collect() in the same process inherited the first run's failures and
    exited 3 with stale messages — and a caller retrying after a
    transient error could never get a clean result."""
    inventory.SWEEP_FAILURES.append('stale failure from an earlier run')
    entries, _, _ = inventory.collect({
        'scope': {
            'root': 'organizations/1'
        },
        'types': []
    })
    self.assertEqual(entries, [])
    self.assertEqual(inventory.SWEEP_FAILURES, [])

  def test_bare_numeric_include_is_refused_as_ambiguous(self):
    """`exclude: [12345]` meaning folder 12345 was coerced to
    projects/12345, matched nothing, and the exclusion silently
    no-oped. The same typo in `include` emptied the denominator."""
    for field in ('include', 'exclude'):
      with self.assertRaises(SystemExit) as ctx:
        inventory.parse_and_validate_scopes(
            {'scope': {
                'root': 'organizations/1',
                field: ['12345']
            }})
      self.assertIn('ambiguous', str(ctx.exception))

  def test_misspelled_include_prefix_is_refused(self):
    with self.assertRaises(SystemExit) as ctx:
      inventory.parse_and_validate_scopes(
          {'scope': {
              'root': 'organizations/1',
              'include': ['folder/22']
          }})
    self.assertIn('unsupported prefix', str(ctx.exception))

  def test_bare_project_id_include_is_still_accepted(self):
    scopes = inventory.parse_and_validate_scopes(
        {'scope': {
            'root': 'organizations/1',
            'include': ['my-app-prod']
        }})
    self.assertEqual(scopes[0]['include'], ['my-app-prod'])

  def test_unresolvable_project_id_is_recorded_not_swallowed(self):
    """resolve() swallowed every failure of `gcloud projects describe`,
    so an include written as a project ID matched nothing (CAI ancestors
    are numbers) and every asset under it left the denominator with exit
    0."""
    real = inventory.run_json
    calls = []

    def fake(cmd, **kwargs):
      del kwargs
      calls.append(cmd)
      inventory.SWEEP_FAILURES.append(f'{" ".join(cmd)}: permission denied')
      return []

    inventory.run_json = fake
    inventory.SWEEP_FAILURES.clear()
    try:
      reg = inventory.ProjectRegistry()
      num, _ = reg.resolve('my-app-prod')
      self.assertIsNone(num)
      self.assertTrue(inventory.SWEEP_FAILURES)
      # ... and the negative result is cached: an uncached miss re-spawned
      # the subprocess once per ASSET.
      reg.resolve('my-app-prod')
      reg.resolve('my-app-prod')
      self.assertEqual(len(calls), 1)
    finally:
      inventory.run_json = real
      inventory.SWEEP_FAILURES.clear()

  def _lvl_entry(self, atype, level, key):
    return {'asset_type': atype, 'level': level, 'key': key}

  def test_unknown_level_survives_explicit_manifest_levels(self):
    """Regression (round 15): an asset the classifier cannot place must
    never be filtered out by an explicit `levels` list.

    ACM AccessLevel/ServicePerimeter parents carry no /organizations/ or
    /projects/ marker, so they classify as `unknown`. Declared with the
    natural `levels: [organization]` they used to vanish from the
    denominator silently while the gates still reported green.
    """
    acm = 'identity.accesscontextmanager.googleapis.com/AccessLevel'
    entries = [self._lvl_entry(acm, 'unknown', '//acm/lvl1')]
    out = inventory.apply_level_filter(entries, {acm: {'organization'}},
                                       report=False)
    self.assertEqual([e['key'] for e in out], ['//acm/lvl1'])

  def test_explicit_levels_still_exclude_real_container_levels(self):
    """The deliberate case must keep working: 'org IAM yes, project no'."""
    t = 'cloudresourcemanager.googleapis.com/Project'
    entries = [
        self._lvl_entry(t, 'organization', '//k/org'),
        self._lvl_entry(t, 'project', '//k/proj'),
        self._lvl_entry(t, 'folder', '//k/folder'),
    ]
    out = inventory.apply_level_filter(entries, {t: {'organization'}},
                                       report=False)
    self.assertEqual([e['key'] for e in out], ['//k/org'])

  def test_unknown_level_reported_not_hidden(self):
    """Retention must be visible, not silent in the other direction."""
    acm = 'identity.accesscontextmanager.googleapis.com/ServicePerimeter'
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
      inventory.apply_level_filter(
          [self._lvl_entry(acm, 'unknown', '//acm/p1')],
          {acm: {'organization'}})
    out = buf.getvalue()
    self.assertIn('could not be classified', out)
    self.assertIn(acm, out)

  def test_types_without_explicit_levels_are_unaffected(self):
    t = 'storage.googleapis.com/Bucket'
    entries = [self._lvl_entry(t, 'project', '//k/b')]
    out = inventory.apply_level_filter(entries, {}, report=False)
    self.assertEqual(len(out), 1)

  def test_leaf_iam_opt_in(self):
    # Leaf-asset IAM (e.g. SA impersonation grants) enters the
    # denominator only via explicit `iam: true` on the type entry.
    sa_type = 'iam.googleapis.com/ServiceAccount'
    assets = [
        {
            'name': '//iam.googleapis.com/projects/p/serviceAccounts/x@p.iam',
            'assetType': sa_type,
            'ancestors': ['projects/123', 'organizations/1'],
            'iamPolicy': {
                'bindings': [{
                    'role': 'roles/iam.serviceAccountUser',
                    'members': ['user:a@example.com']
                }]
            }
        },
        {
            'name': '//iam.googleapis.com/projects/p/serviceAccounts/y@p.iam',
            'assetType': sa_type,
            'ancestors': ['projects/123', 'organizations/1']
        },  # no policy
        {
            'name': '//cloudresourcemanager.googleapis.com/tagValues/9',
            'assetType': 'cloudresourcemanager.googleapis.com/TagValue',
            'ancestors': ['organizations/1'],
            'iamPolicy': {
                'bindings': []
            }
        },  # type not opted in
    ]
    entries = inventory._normalize_leaf_iam(assets, {sa_type})
    self.assertEqual(len(entries), 1)
    self.assertEqual(
        entries[0]['key'], '//iam.googleapis.com/projects/p/serviceAccounts/'
        'x@p.iam#iam')
    # asset_type is the leaf type so its own `levels` restriction
    # applies; level is the containing project.
    self.assertEqual(entries[0]['asset_type'], sa_type)
    self.assertEqual(entries[0]['level'], 'project')

  def test_org_policy_service_stream_live_shape(self):
    # Round 4 live finding: `gcloud org-policies list --format=json`
    # emits `constraint` (no `name`); caller passes the container.
    entries = inventory._normalize_org_policies_from_service([{
        'constraint': 'constraints/custom.testDryRunOnlyConstraint',
        'etag': 'x',
        'listPolicy': {}
    }, {
        'constraint': 'compute.skipDefaultNetworkCreation',
        'booleanPolicy': {}
    }], container='organizations/1')
    self.assertEqual([e['key'] for e in entries], [
        '//cloudresourcemanager.googleapis.com/organizations/1'
        '#org-policy/custom.testDryRunOnlyConstraint',
        '//cloudresourcemanager.googleapis.com/organizations/1'
        '#org-policy/compute.skipDefaultNetworkCreation',
    ])
    self.assertTrue(all(e['level'] == 'organization' for e in entries))
    # No container and no name -> entry dropped, not mis-keyed.
    self.assertEqual(
        inventory._normalize_org_policies_from_service([{
            'constraint': 'constraints/x.y'
        }]), [])

  def test_org_policy_service_stream_normalization(self):
    # Round 3: dry-run-only policies exist only in the service
    # API; its names lack the //orgpolicy prefix but must merge into
    # the same key namespace.
    entries = inventory._normalize_org_policies_from_service([
        {
            'name': 'organizations/1/policies/custom.testDryRunOnly',
            'dryRunSpec': {
                'rules': []
            }
        },
        {
            'name': 'folders/22/policies/compute.vmExternalIpAccess',
            'spec': {
                'rules': []
            }
        },
        {
            'name': 'garbage-no-match'
        },
    ])
    self.assertEqual(len(entries), 2)
    self.assertEqual(entries[0]['key'],
                     ('//cloudresourcemanager.googleapis.com/organizations/1'
                      '#org-policy/custom.testDryRunOnly'))
    self.assertEqual(entries[1]['level'], 'folder')
    # Same policy seen via the CAI resource stream dedupes by key.
    cai = inventory._normalize_org_policies_from_resources([{
        'name': ('//orgpolicy.googleapis.com/organizations/1/policies/'
                 'custom.testDryRunOnly'),
        'assetType': 'orgpolicy.googleapis.com/Policy',
    }])
    self.assertEqual(cai[0]['key'], entries[0]['key'])

  def test_org_policy_resource_stream_normalization(self):
    # Policy resource assets merge into the same
    # key format as the legacy content-type stream.
    entries = inventory._normalize_org_policies_from_resources([{
        'name': ('//orgpolicy.googleapis.com/organizations/1/policies/'
                 'essentialcontacts.allowedContactDomains'),
        'assetType': 'orgpolicy.googleapis.com/Policy',
        'ancestors': ['organizations/1'],
    }])
    self.assertEqual(entries[0]['key'],
                     ('//cloudresourcemanager.googleapis.com/organizations/1'
                      '#org-policy/essentialcontacts.allowedContactDomains'))
    self.assertEqual(entries[0]['level'], 'organization')

  def test_asset_level_from_type(self):
    self.assertEqual(
        inventory.asset_level(
            {'assetType': 'cloudresourcemanager.googleapis.com/Folder'}),
        'folder')

  def test_in_subtree_include_exclude(self):
    asset = {'ancestors': ['projects/9', 'folders/2', 'organizations/1']}
    self.assertTrue(inventory.in_subtree(asset, ['folders/2'], []))
    self.assertFalse(inventory.in_subtree(asset, ['folders/3'], []))
    self.assertFalse(inventory.in_subtree(asset, ['folders/2'], ['projects/9']))
    self.assertTrue(inventory.in_subtree(asset, [], []))

  def test_org_policy_normalization(self):
    entries = inventory._normalize_org_policies([{
        'name':
            '//cloudresourcemanager.googleapis.com/organizations/1',
        'assetType':
            'cloudresourcemanager.googleapis.com/Organization',
        'ancestors': ['organizations/1'],
        'orgPolicy': [{
            'constraint': 'constraints/compute.foo'
        }, {
            'constraint': 'iam.bar'
        }],
    }])
    self.assertEqual([e['key'] for e in entries], [
        '//cloudresourcemanager.googleapis.com/organizations/1'
        '#org-policy/compute.foo',
        '//cloudresourcemanager.googleapis.com/organizations/1'
        '#org-policy/iam.bar',
    ])


def _run_main(module, argv, stdin_text=None):
  """Runs a gate's main() with patched argv/stdin, capturing output.

  Returns (exit_code, stdout, stderr).
  """
  out, err = io.StringIO(), io.StringIO()
  old_argv, old_stdin = sys.argv, sys.stdin
  sys.argv = [module.__name__ + '.py'] + argv
  if stdin_text is not None:
    sys.stdin = io.StringIO(stdin_text)
  try:
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
      code = module.main()
  finally:
    sys.argv, sys.stdin = old_argv, old_stdin
  return code, out.getvalue(), err.getvalue()


def _plan_json(resource_changes):
  return json.dumps({
      'format_version': '1.2',
      'resource_changes': resource_changes
  })


_CLEAN_IMPORT_RC = {
    'type': 'google_folder',
    'address': 'google_folder.f',
    'change': {
        'actions': ['no-op'],
        'importing': {
            'id': 'folders/1'
        },
        'before': {},
        'after': {}
    },
}


class TestVerifyPlanMain(unittest.TestCase):
  """Fail-closed input validation and input binding (hardening r19)."""

  def test_empty_object_refused(self):
    # Reviewer repro: `echo '{}' | verify_plan.py` used to print
    # CONVERGED and exit 0.
    code, _, err = _run_main(verify_plan, [], stdin_text='{}')
    self.assertEqual(code, 1)
    self.assertIn('not a terraform plan', err)

  def test_state_json_refused(self):
    # `terraform show -json` without a plan file dumps STATE, which has
    # format_version but no resource_changes.
    state = json.dumps({'format_version': '1.0', 'values': {}})
    code, _, err = _run_main(verify_plan, [], stdin_text=state)
    self.assertEqual(code, 1)
    self.assertIn('not a terraform plan', err)

  def test_invalid_json_refused(self):
    code, _, err = _run_main(verify_plan, [], stdin_text='not json')
    self.assertEqual(code, 1)
    self.assertIn('not valid JSON', err)

  def test_empty_plan_refused_by_default(self):
    code, out, _ = _run_main(verify_plan, [], stdin_text=_plan_json([]))
    self.assertEqual(code, 2)
    self.assertIn('zero resource changes', out)

  def test_empty_plan_allowed_with_flag(self):
    code, out, _ = _run_main(verify_plan, ['--allow-empty-plan'],
                             stdin_text=_plan_json([]))
    self.assertEqual(code, 0)
    self.assertIn('WARNING: plan contains zero resource changes', out)

  def test_converged_output_carries_input_stamps(self):
    code, out, _ = _run_main(verify_plan, [],
                             stdin_text=_plan_json([_CLEAN_IMPORT_RC]))
    self.assertEqual(code, 0)
    self.assertIn('frozen tools:', out)
    self.assertIn('input plan: <stdin> sha256:', out)
    self.assertIn('input rules:', out)
    self.assertNotIn('WARNING: non-default rules file', out)

  def test_residual_plan_exits_2_and_proposes_a_guarded_rule(self):
    """The gate's primary failure mode had no end-to-end test: nothing
    drove main() with a real residual, so the RESIDUAL block, the exit
    code and the proposal template were never executed."""
    residual = {
        'type': 'google_project',
        'address': 'google_project.p',
        'change': {
            'actions': ['update'],
            'before': {
                'name': 'old'
            },
            'after': {
                'name': 'new'
            }
        }
    }
    code, out, _ = _run_main(verify_plan, [], stdin_text=_plan_json([residual]))
    self.assertEqual(code, 2)
    self.assertIn('RESIDUAL CHANGES', out)
    self.assertIn('google_project.p', out)
    self.assertNotIn('CONVERGED', out)
    # The template must arrive already narrowed to what was observed:
    # an attributes-only rule waives the whole subtree forever.
    block = out.split('add reviewed entries to benign-drift.yaml, e.g.:')[1]
    block = block.split('The workspace has NOT converged')[0]
    proposal = yaml.safe_load(block)
    rule = proposal['rules'][0]
    self.assertEqual(rule['resource'], 'google_project')
    self.assertEqual(rule['when_before'], {'name': 'old'})
    self.assertEqual(rule['when_after'], {'name': 'new'})
    # The template must be committable as-is: a proposal the guard
    # checker would refuse hands the reviewer a dead rule.
    self.assertIsNone(verify_plan.rule_guard_problem(rule))

  def test_proposed_rule_for_computed_attribute_uses_computed_guard(self):
    rc = _rc('google_project', ['update'], before={'terraform_labels': {}},
             after={}, unknown={'terraform_labels': True})
    proposal = verify_plan.propose_rule(rc, {'paths': ['terraform_labels']})
    self.assertEqual(proposal['when_after_computed'], ['terraform_labels'])
    self.assertNotIn('when_after', proposal)

  def test_non_default_rules_prints_loud_warning(self):
    # Reviewer repro: --rules /tmp/permissive.yaml used to produce a
    # verdict stamped with a clean frozen-tools digest and no trace of
    # the substituted ruleset.
    with tempfile.NamedTemporaryFile('w', suffix='.yaml', delete=False) as f:
      f.write('rules: []\n')
      rules_path = f.name
    try:
      code, out, _ = _run_main(verify_plan, ['--rules', rules_path],
                               stdin_text=_plan_json([_CLEAN_IMPORT_RC]))
      # A substituted ruleset can never produce a passing exit code:
      # otherwise `--rules permissive.yaml` is a cheaper way to green
      # than editing the frozen file the contract forbids editing.
      self.assertEqual(code, 3)
      self.assertIn('ADVISORY ONLY', out)
      self.assertIn('WARNING: non-default rules file', out)
      # Path shape safe for transcripts — basename, not absolute.
      self.assertIn(os.path.basename(rules_path), out)
      self.assertNotIn(os.path.abspath(rules_path), out)
    finally:
      os.unlink(rules_path)

  def test_plan_file_argument_is_hashed(self):
    with tempfile.NamedTemporaryFile('w', suffix='.json', delete=False) as f:
      f.write(_plan_json([_CLEAN_IMPORT_RC]))
      plan_path = f.name
    try:
      code, out, _ = _run_main(verify_plan, [plan_path])
      self.assertEqual(code, 0)
      # Path shape: display_path form, not the absolute path.
      self.assertIn(f'input plan: {os.path.basename(plan_path)} sha256:', out)
      self.assertNotIn(os.path.abspath(plan_path), out)
    finally:
      os.unlink(plan_path)


class TestCoverageHardening(unittest.TestCase):
  """Key↔resource join, waiver robustness, fail-closed denominator."""

  _INVENTORY = TestCoverage._INVENTORY

  def test_many_keys_one_address_is_a_problem(self):
    # Reviewer repro (denominator collapse): every key pointing at the
    # same single address used to reconcile green.
    cmap = {
        '//x/folders/1': ['module.ff.google_folder.f["a"]'],
        '//x/folders/2': ['module.ff.google_folder.f["a"]'],
    }
    _, problems = coverage.reconcile(self._INVENTORY[:2], cmap, [],
                                     {'module.ff.google_folder.f["a"]'})
    self.assertTrue(any('must be unique' in p for p in problems), problems)

  def test_orphan_import_block_is_a_problem(self):
    cmap = {'//x/folders/1': ['module.ff.google_folder.f["a"]']}
    _, problems = coverage.reconcile(
        self._INVENTORY[:1], cmap, [],
        {'module.ff.google_folder.f["a"]', 'google_folder.unclaimed'})
    self.assertTrue(any('orphan import block' in p for p in problems), problems)

  def test_stale_waiver_is_a_problem(self):
    waivers = [{'key': '//not/in/scope', 'reason': 'pre-emptive'}]
    _, problems = coverage.reconcile(self._INVENTORY[:1], {}, waivers, set())
    self.assertTrue(any('waived key not in inventory' in p for p in problems),
                    problems)

  def test_malformed_waiver_is_reported_not_a_traceback(self):
    waivers = ['just-a-string', {'reason': 'no key'}]
    missing, problems = coverage.reconcile(self._INVENTORY[:1], {}, waivers,
                                           set())
    self.assertEqual(len([p for p in problems if 'malformed waiver' in p]), 2)
    self.assertEqual(len(missing), 1)  # the key is still missing

  def test_coverage_map_string_value_is_reported(self):
    # A bare string would otherwise iterate character-by-character.
    cmap = {'//x/folders/1': 'module.ff.google_folder.f["a"]'}
    _, problems = coverage.reconcile(self._INVENTORY[:1], cmap, [], set())
    self.assertTrue(any('must be a list' in p for p in problems), problems)

  def test_parse_import_blocks_ids_and_trailing_comments(self):
    with tempfile.TemporaryDirectory() as td:
      with open(os.path.join(td, 'x.tf'), 'w') as f:
        f.write('import {\n'
                '  to = google_folder.f  # trailing comment\n'
                '  id = "folders/111" # another comment\n'
                '}\n')
      blocks = coverage.parse_import_blocks(td)
      self.assertEqual(blocks, {'google_folder.f': 'folders/111'})
      self.assertEqual(coverage.parse_import_addresses(td), {'google_folder.f'})

  def test_single_line_import_block_is_parsed(self):
    """`import { to = X\\n id = "Y" }` opened and closed on the same line
    was swallowed whole: the address never landed in the map, so the
    gate reported the mapping as having no import block — a false
    failure the operator cannot explain."""
    with tempfile.TemporaryDirectory() as td:
      with open(os.path.join(td, 'x.tf'), 'w') as f:
        f.write('import { to = google_folder.f  id = "folders/111" }\n')
      self.assertEqual(coverage.parse_import_blocks(td),
                       {'google_folder.f': 'folders/111'})

  def test_same_line_closing_brace_does_not_pollute_the_id(self):
    with tempfile.TemporaryDirectory() as td:
      with open(os.path.join(td, 'x.tf'), 'w') as f:
        f.write('import {\n'
                '  to = google_folder.f\n'
                '  id = "folders/111" }\n')
      self.assertEqual(coverage.parse_import_blocks(td),
                       {'google_folder.f': 'folders/111'})

  def test_duplicate_import_ids_are_a_problem(self):
    """Two addresses importing the SAME id is the copy-paste error that
    scaffolding near-identical folders invites. Uniqueness was enforced
    on addresses only, so this passed the completeness gate while one
    live resource ended up owned twice and another stayed unmanaged."""
    dupes = coverage.duplicate_import_ids({
        'google_folder.a': 'folders/111',
        'google_folder.b': 'folders/111',
        'google_folder.c': 'folders/222',
    })
    self.assertEqual(dupes,
                     {'folders/111': ['google_folder.a', 'google_folder.b']})

  def test_missing_workspace_is_malformed_input_not_a_gap(self):
    with tempfile.TemporaryDirectory() as td:
      inv = os.path.join(td, 'inventory.json')
      with open(inv, 'w') as f:
        json.dump({'_meta': {}, 'assets': [{'key': 'k', 'asset_type': 't'}]}, f)
      code, _, err = _run_main(coverage, [
          '--inventory', inv, '--workspace',
          os.path.join(td, 'does-not-exist')
      ])
      self.assertEqual(code, 1)
      self.assertIn('workspace directory not found', err)

  def _write_ws(self, td, inv, cmap=None, tf=''):
    inv_path = os.path.join(td, 'inventory.json')
    with open(inv_path, 'w') as f:
      json.dump(inv, f)
    ws = os.path.join(td, 'tf')
    os.makedirs(ws, exist_ok=True)
    if cmap is not None:
      with open(os.path.join(ws, 'coverage-map.yaml'), 'w') as f:
        yaml.safe_dump(cmap, f)
    if tf:
      with open(os.path.join(ws, 'main.tf'), 'w') as f:
        f.write(tf)
    return inv_path, ws

  def test_empty_inventory_refused_by_default(self):
    # Reviewer repro: `[]` used to print RECONCILED and exit 0.
    with tempfile.TemporaryDirectory() as td:
      inv, ws = self._write_ws(td, [])
      code, _, err = _run_main(coverage,
                               ['--inventory', inv, '--workspace', ws])
      self.assertEqual(code, 1)
      self.assertIn('empty denominator', err)

  def test_empty_inventory_allowed_with_flag(self):
    with tempfile.TemporaryDirectory() as td:
      inv, ws = self._write_ws(td, [])
      code, out, _ = _run_main(
          coverage,
          ['--inventory', inv, '--workspace', ws, '--allow-empty-inventory'])
      self.assertEqual(code, 0)
      self.assertIn('RECONCILED', out)

  def test_new_inventory_format_and_input_stamps(self):
    entry = {
        'key': '//x/folders/1',
        'asset_type': 'f',
        'level': 'organization',
        'container': 'organizations/1'
    }
    wrapped = {'_meta': {'manifest_sha256': 'abc'}, 'assets': [entry]}
    tf = ('import {\n  to = google_folder.f\n  id = "folders/1"\n}\n')
    with tempfile.TemporaryDirectory() as td:
      inv, ws = self._write_ws(td, wrapped,
                               cmap={'//x/folders/1': ['google_folder.f']},
                               tf=tf)
      code, out, _ = _run_main(coverage,
                               ['--inventory', inv, '--workspace', ws])
      self.assertEqual(code, 0)
      self.assertIn('RECONCILED', out)
      self.assertIn('input inventory:', out)
      self.assertIn('input coverage-map:', out)
      self.assertIn('input workspace:', out)
      self.assertNotIn('legacy bare-list', out)

  def test_legacy_inventory_format_warns(self):
    entry = {
        'key': '//x/folders/1',
        'asset_type': 'f',
        'level': 'organization',
        'container': 'organizations/1'
    }
    tf = ('import {\n  to = google_folder.f\n  id = "folders/1"\n}\n')
    with tempfile.TemporaryDirectory() as td:
      inv, ws = self._write_ws(td, [entry],
                               cmap={'//x/folders/1': ['google_folder.f']},
                               tf=tf)
      code, out, _ = _run_main(coverage,
                               ['--inventory', inv, '--workspace', ws])
      self.assertEqual(code, 0)
      self.assertIn('no provenance metadata', out)


class TestInventoryManifestValidation(unittest.TestCase):
  """Manifest mistakes fail closed instead of shrinking the denominator."""

  def test_invalid_level_rejected(self):
    # `levels: [org]` used to silently drop every entry of the type.
    with self.assertRaises(SystemExit) as ctx:
      inventory.validate_manifest_types([{'type': 'iam', 'levels': ['org']}])
    self.assertIn('invalid level', str(ctx.exception))

  def test_duplicate_type_rejected(self):
    with self.assertRaises(SystemExit) as ctx:
      inventory.validate_manifest_types([
          {
              'type': 'iam',
              'levels': ['organization', 'folder']
          },
          {
              'type': 'iam',
              'levels': ['organization']
          },
      ])
    self.assertIn('more than once', str(ctx.exception))

  def test_valid_types_pass(self):
    inventory.validate_manifest_types([
        {
            'type': 'iam',
            'levels': ['organization', 'unknown']
        },
        {
            'type': 'org-policy'
        },
        {
            'type': 'storage.googleapis.com/Bucket',
            'levels': ['project']
        },
    ])

  def test_collect_validates_before_any_enumeration(self):
    with self.assertRaises(SystemExit) as ctx:
      inventory.collect({
          'scope': {
              'root': 'organizations/1'
          },
          'types': [{
              'type': 'iam',
              'levels': ['orgs']
          }]
      })
    self.assertIn('invalid level', str(ctx.exception))


class TestApiCallLoggingAndPaging(unittest.TestCase):
  """Every call is announced and counted, and pages are as large as the
  API allows.

  These run real subprocesses on purpose: the rest of the suite replaces
  run_json wholesale, so the logging, timing and failure bookkeeping
  inside it would otherwise never execute.
  """

  def setUp(self):
    inventory.API_CALLS.clear()
    inventory.SWEEP_FAILURES.clear()
    self._verbose = inventory.VERBOSE

  def tearDown(self):
    inventory.API_CALLS.clear()
    inventory.SWEEP_FAILURES.clear()
    inventory.VERBOSE = self._verbose

  def test_asset_list_asks_for_the_largest_page_the_api_allows(self):
    """assets.list defaults to 100 per page, so a 50k-asset org cost 500
    round trips. 1000 is the documented maximum."""
    seen = []
    real = inventory.run_json
    inventory.run_json = lambda cmd, **kw: seen.append(cmd) or []
    try:
      inventory.run_gcloud_json(['--organization=1'])
    finally:
      inventory.run_json = real
    self.assertIn('--page-size=1000', seen[0])
    self.assertEqual(inventory.CAI_LIST_PAGE_SIZE, 1000)
    # searchAllResources clamps at 500 even if a larger value is given.
    self.assertEqual(inventory.CAI_SEARCH_PAGE_SIZE, 500)

  def test_search_fallback_uses_the_search_page_cap(self):
    calls = []

    def handler(cmd, **kwargs):
      calls.append(' '.join(cmd))
      if not kwargs.get('ignore_errors'):
        raise SystemExit('command failed\nERROR: PERMISSION_DENIED')
      return []

    real = inventory.run_json
    inventory.run_json = handler
    try:
      with contextlib.redirect_stderr(io.StringIO()):
        inventory.collect({
            'scope': {
                'root': 'organizations/1'
            },
            'types': [{
                'type': 'storage.googleapis.com/Bucket',
                'levels': ['project']
            }]
        })
    finally:
      inventory.run_json = real
    search = [c for c in calls if 'search-all-resources' in c]
    self.assertTrue(search)
    self.assertIn('--page-size=500', search[0])

  def test_quiet_by_default_but_still_recorded(self):
    """On a large estate the per-call log is one pair of lines per
    container, which buries the warnings that decide whether the
    denominator can be trusted. So the screen stays quiet unless asked,
    while the record — which nothing else can reconstruct afterwards —
    is kept either way."""
    inventory.VERBOSE = False
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      inventory.run_json([sys.executable, '-c', 'print("[1,2]")'])
    self.assertEqual(buf.getvalue(), '')
    self.assertEqual(inventory.API_CALLS[0]['item_count'], 2)
    self.assertEqual(inventory.API_CALLS[0]['outcome'], 'ok')

  def test_verbose_flag_reaches_the_logger(self):
    """The flag is per-subcommand on purpose: declared on the top-level
    parser as well, argparse's subparser default would overwrite it."""
    argv = sys.argv
    verbose = inventory.VERBOSE
    real_collect = inventory.collect
    seen = {}

    def fake_collect(manifest):
      del manifest
      seen['verbose'] = inventory.VERBOSE
      return [], inventory.ProjectRegistry(), []

    with tempfile.NamedTemporaryFile('w', suffix='.yaml', delete=False) as f:
      yaml.safe_dump({'scope': {'root': 'organizations/1'}, 'types': []}, f)
      mpath = f.name
    try:
      inventory.collect = fake_collect
      for flags, expected in ((['--verbose'], True), ([], False)):
        inventory.VERBOSE = False
        sys.argv = ([
            'inventory.py', 'collect', '--manifest', mpath, '--out', os.devnull
        ] + flags)
        with contextlib.redirect_stdout(io.StringIO()):
          with contextlib.redirect_stderr(io.StringIO()):
            inventory.main()
        self.assertEqual(seen['verbose'], expected)
    finally:
      inventory.collect = real_collect
      inventory.VERBOSE = verbose
      sys.argv = argv
      os.remove(mpath)

  def test_a_successful_call_is_logged_before_and_after(self):
    inventory.VERBOSE = True
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      out = inventory.run_json([sys.executable, '-c', 'print("[1,2,3]")'])
    self.assertEqual(out, [1, 2, 3])
    err = buf.getvalue()
    # Announced before it runs, so a long sweep shows progress rather
    # than silence.
    self.assertIn('[api   1]', err)
    self.assertIn('ok in', err)
    self.assertIn('3 item(s)', err)
    record = inventory.API_CALLS[0]
    self.assertEqual(record['outcome'], 'ok')
    self.assertEqual(record['item_count'], 3)
    self.assertIn('seconds', record)

  def test_a_failed_call_is_recorded_as_failed_not_as_ok(self):
    inventory.VERBOSE = True
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      out = inventory.run_json([sys.executable, '-c', 'raise SystemExit(1)'],
                               ignore_errors=True)
    self.assertEqual(out, [])
    self.assertEqual(inventory.API_CALLS[0]['outcome'], 'FAILED')
    self.assertIn('FAILED in', buf.getvalue())
    # ... and it still lands in the fail-closed accumulator.
    self.assertTrue(inventory.SWEEP_FAILURES)

  def test_calls_are_numbered_in_order_and_summarized(self):
    with contextlib.redirect_stderr(io.StringIO()):
      inventory.run_json([sys.executable, '-c', 'print("[]")'])
      inventory.run_json([sys.executable, '-c', 'print("[]")'])
    self.assertEqual([c['n'] for c in inventory.API_CALLS], [1, 2])
    summary = inventory.api_call_summary()
    self.assertIn('2 gcloud call(s)', summary)

  def test_the_summary_counts_failures_separately(self):
    with contextlib.redirect_stderr(io.StringIO()):
      inventory.run_json([sys.executable, '-c', 'print("[]")'])
      inventory.run_json([sys.executable, '-c', 'raise SystemExit(1)'],
                         ignore_errors=True)
    self.assertIn('1 not ok', inventory.api_call_summary())

  def test_the_call_log_does_not_leak_into_the_next_collect(self):
    inventory.API_CALLS.append({'n': 99, 'command': 'stale', 'outcome': 'ok'})
    real = inventory.run_json
    inventory.run_json = lambda cmd, **kw: []
    try:
      with contextlib.redirect_stderr(io.StringIO()):
        inventory.collect({'scope': {'root': 'organizations/1'}, 'types': []})
    finally:
      inventory.run_json = real
    self.assertEqual(inventory.API_CALLS, [])


class TestNonCaiEnumeration(unittest.TestCase):
  """CAI is the default source of the denominator, not its boundary.

  A type CAI does not model must be enumerated by other means (gcloud
  first) and merged into the SAME denominator. The failure this class
  pins down is the one seen live: a manifest declared
  `logging.googleapis.com/OrganizationSettings`, which is not in the CAI
  catalogue at all, and the run died with a generic "enumeration
  failure" that told the operator nothing about what to do instead.
  """

  _UNSUPPORTED_ERR = (
      'command failed: gcloud --quiet asset list\n'
      'ERROR: (gcloud.asset.list) INVALID_ARGUMENT: No supported asset '
      'type matches: logging.googleapis.com/OrganizationSettings. See '
      'https://cloud.google.com/asset-inventory/docs/supported-asset-types')

  def _collect(self, manifest, handler):
    real = inventory.run_json
    inventory.run_json = handler
    try:
      return inventory.collect(manifest)
    finally:
      inventory.run_json = real

  def test_unsupported_type_is_diagnosed_not_just_reported(self):

    def handler(cmd, **kwargs):
      joined = ' '.join(cmd)
      if 'OrganizationSettings' in joined and not kwargs.get('ignore_errors'):
        raise SystemExit(self._UNSUPPORTED_ERR)
      if 'asset' in cmd and 'list' in cmd and not kwargs.get('ignore_errors'):
        raise SystemExit(self._UNSUPPORTED_ERR)
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      with self.assertRaises(SystemExit) as ctx:
        self._collect(
            {
                'scope': {
                    'root': 'organizations/1'
                },
                'types': [{
                    'type': 'logging.googleapis.com/OrganizationSettings',
                    'levels': ['organization']
                }]
            }, handler)
    self.assertEqual(ctx.exception.code, 3)
    err = buf.getvalue()
    self.assertIn('not modelled by Cloud Asset Inventory', err)
    self.assertIn('logging.googleapis.com/OrganizationSettings', err)
    # The message has to name the remedy, not just the symptom.
    self.assertIn('enumerate:', err)
    self.assertIn('gcloud', err)
    self.assertIn('logging.googleapis.com/Settings', err)

  def test_unsupported_type_skips_the_pointless_search_fallback(self):
    """`search-all-resources` rejects an unknown type exactly like
    `asset list` does, so retrying it only buried the real diagnosis
    under a second identical error."""
    calls = []

    def handler(cmd, **kwargs):
      calls.append(' '.join(cmd))
      if not kwargs.get('ignore_errors'):
        raise SystemExit(self._UNSUPPORTED_ERR)
      return []

    with contextlib.redirect_stderr(io.StringIO()):
      with self.assertRaises(SystemExit):
        self._collect(
            {
                'scope': {
                    'root': 'organizations/1'
                },
                'types': [{
                    'type': 'logging.googleapis.com/OrganizationSettings',
                    'levels': ['organization']
                }]
            }, handler)
    self.assertFalse([c for c in calls if 'search-all-resources' in c])

  def test_permission_failure_is_still_a_sweep_failure(self):
    """Only the type-catalogue error is re-diagnosed; a 403 must keep
    its old path (search fallback, then the tolerated-failure exit)."""
    calls = []

    def handler(cmd, **kwargs):
      calls.append(' '.join(cmd))
      if not kwargs.get('ignore_errors'):
        raise SystemExit('command failed\nERROR: PERMISSION_DENIED')
      inventory.SWEEP_FAILURES.append('simulated 403')
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      with self.assertRaises(SystemExit) as ctx:
        self._collect(
            {
                'scope': {
                    'root': 'organizations/1'
                },
                'types': [{
                    'type': 'storage.googleapis.com/Bucket',
                    'levels': ['project']
                }]
            }, handler)
    self.assertEqual(ctx.exception.code, 3)
    self.assertIn('enumeration failure', buf.getvalue())
    self.assertNotIn('not modelled by Cloud Asset Inventory', buf.getvalue())
    self.assertTrue([c for c in calls if 'search-all-resources' in c])

  _EXCLUSION_MANIFEST = {
      'scope': {
          'root': 'organizations/1'
      },
      'types': [{
          'type': 'logging.googleapis.com/LogExclusion',
          'levels': ['organization'],
          'enumerate': {
              'command': ['logging', 'exclusions', 'list'],
              'key': '//logging.googleapis.com/{container}/exclusions/'
                     '{item.name}',
          },
      }]
  }

  def test_native_enumeration_enters_the_same_denominator(self):
    calls = []

    def handler(cmd, **kwargs):
      del kwargs
      calls.append(' '.join(cmd))
      if 'exclusions' in cmd:
        return [{'name': 'noisy-audit'}, {'name': 'debug'}]
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      entries, _, _ = self._collect(self._EXCLUSION_MANIFEST, handler)
    self.assertEqual([e['key'] for e in entries], [
        '//logging.googleapis.com/organizations/1/exclusions/debug',
        '//logging.googleapis.com/organizations/1/exclusions/noisy-audit',
    ])
    self.assertTrue(
        all(e['asset_type'] == 'logging.googleapis.com/LogExclusion' and
            e['level'] == 'organization' for e in entries))
    # The type is never sent to CAI - that is the point of declaring it.
    self.assertFalse([c for c in calls if 'LogExclusion' in c])
    self.assertIn(
        'gcloud --quiet logging exclusions list --organization=1 '
        '--format=json', calls)
    # Enumerating outside CAI is announced, never quietly assumed.
    self.assertIn('enumerated natively', buf.getvalue())

  def test_every_shipped_enumerator_passes_its_own_validation(self):
    """The built-in table is held to the guard rails it enforces on
    operators: read-only verb, no output-narrowing flags, resolvable key
    template."""
    self.assertTrue(inventory.NATIVE_ENUMERATORS)
    for atype, spec in inventory.NATIVE_ENUMERATORS.items():
      inventory.validate_native_spec(atype, spec)
      self.assertNotIn(atype, inventory.PSEUDO_TYPES)

  def test_a_known_non_cai_type_is_enumerated_without_being_asked(self):
    """The point of the table: declaring the type is enough. An operator
    should not have to re-derive the gcloud incantation per engagement,
    and CAI should never be consulted for a type known to be absent from
    it."""
    calls = []

    def handler(cmd, **kwargs):
      del kwargs
      calls.append(' '.join(cmd))
      if 'policies' in cmd:
        return [{
            'name': 'policies/cloudresourcemanager.googleapis.com%2F'
                    'organizations%2F1/denypolicies/deny-external'
        }]
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      entries, _, _ = self._collect(
          {
              'scope': {
                  'root': 'organizations/1'
              },
              'types': [{
                  'type': 'iam.googleapis.com/DenyPolicy',
                  'levels': ['organization']
              }]
          }, handler)
    self.assertEqual(len(entries), 1)
    self.assertTrue(entries[0]['key'].startswith('//iam.googleapis.com/'))
    self.assertFalse([c for c in calls if 'asset' in c and 'DenyPolicy' in c])
    self.assertIn('built-in gcloud', buf.getvalue())
    self.assertEqual(inventory.NATIVE_SWEEPS[0]['source'], 'builtin')

  def test_a_manifest_block_overrides_the_built_in(self):
    """An operator who knows better than the shipped table wins, without
    editing a frozen file."""
    calls = []

    def handler(cmd, **kwargs):
      del kwargs
      calls.append(' '.join(cmd))
      return [{'name': 'x'}] if 'policies' in cmd else []

    with contextlib.redirect_stderr(io.StringIO()):
      self._collect(
          {
              'scope': {
                  'root': 'organizations/1'
              },
              'types': [{
                  'type': 'iam.googleapis.com/DenyPolicy',
                  'levels': ['organization'],
                  'enumerate': {
                      'command':
                          ['iam', 'policies', 'list', '--kind=denypolicies'],
                      'key': '//custom/{container}/{item.name}',
                  },
              }]
          }, handler)
    self.assertEqual(inventory.NATIVE_SWEEPS[0]['source'], 'manifest')
    # The override's own container flag shape is used, not the table's.
    self.assertIn(
        'gcloud --quiet iam policies list --kind=denypolicies '
        '--organization=1 --format=json', calls)

  def test_a_type_nobody_can_enumerate_still_stops_the_run(self):
    """Automatic fallback must not become automatic optimism: with no
    built-in and no manifest block, the run stops rather than shipping a
    denominator that is quietly missing a type."""

    def handler(cmd, **kwargs):
      if not kwargs.get('ignore_errors'):
        raise SystemExit(self._UNSUPPORTED_ERR)
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      with self.assertRaises(SystemExit) as ctx:
        self._collect(
            {
                'scope': {
                    'root': 'organizations/1'
                },
                'types': [{
                    'type': 'storage.googleapis.com/ManagedFolder',
                    'levels': ['project']
                }]
            }, handler)
    self.assertEqual(ctx.exception.code, 3)
    self.assertIn('No built-in enumerator covers', buf.getvalue())

  def test_native_sweeps_are_recorded_for_the_run_report(self):

    def handler(cmd, **kwargs):
      del kwargs
      return [{'name': 'noisy-audit'}] if 'exclusions' in cmd else []

    with contextlib.redirect_stderr(io.StringIO()):
      self._collect(self._EXCLUSION_MANIFEST, handler)
    self.assertEqual(len(inventory.NATIVE_SWEEPS), 1)
    sweep = inventory.NATIVE_SWEEPS[0]
    self.assertEqual(sweep['asset_type'], 'logging.googleapis.com/LogExclusion')
    self.assertEqual(sweep['container'], 'organizations/1')
    self.assertEqual(sweep['yield_count'], 1)
    # The verbatim command: a reviewer has to be able to re-run it.
    self.assertIn('--organization=1', sweep['command'])

  def test_native_sweeps_do_not_leak_into_the_next_collect(self):
    inventory.NATIVE_SWEEPS.append({'asset_type': 'stale'})
    inventory.UNSUPPORTED_CAI_TYPES.append('stale')
    with contextlib.redirect_stderr(io.StringIO()):
      inventory.collect({'scope': {'root': 'organizations/1'}, 'types': []})
    self.assertEqual(inventory.NATIVE_SWEEPS, [])
    self.assertEqual(inventory.UNSUPPORTED_CAI_TYPES, [])

  def test_a_key_template_that_is_not_unique_is_fatal(self):
    """Two assets collapsing onto one key is a shrunken denominator with
    a green gate - the exact failure mode this tool exists to prevent -
    so it fails rather than deduplicating."""
    manifest = json.loads(json.dumps(self._EXCLUSION_MANIFEST))
    manifest['types'][0]['enumerate']['key'] = (
        '//logging.googleapis.com/{container}/exclusions/fixed')

    def handler(cmd, **kwargs):
      del kwargs
      return [{'name': 'a'}, {'name': 'b'}] if 'exclusions' in cmd else []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      with self.assertRaises(SystemExit) as ctx:
        self._collect(manifest, handler)
    self.assertEqual(ctx.exception.code, 3)
    self.assertIn('non-unique key', buf.getvalue())

  def test_a_key_field_absent_from_the_payload_is_fatal(self):

    def handler(cmd, **kwargs):
      del kwargs
      return [{'displayName': 'x'}] if 'exclusions' in cmd else []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      with self.assertRaises(SystemExit) as ctx:
        self._collect(self._EXCLUSION_MANIFEST, handler)
    self.assertEqual(ctx.exception.code, 3)
    self.assertIn('absent from the returned item', buf.getvalue())

  def test_describe_shaped_output_is_accepted(self):
    """Singletons (`gcloud ... describe`) emit an object, not an array."""
    entries = inventory._normalize_native(
        {'name': 'organizations/1/settings'}, 'logging.googleapis.com/Settings',
        'organizations/1', '//logging.googleapis.com/{item.name}')
    self.assertEqual(entries[0]['key'],
                     '//logging.googleapis.com/organizations/1/settings')

  def test_key_template_fields(self):
    rendered = inventory._render_native_key(
        '{container}|{container_id}|{item.a.b}', 'folders/22',
        {'a': {
            'b': 'deep'
        }})
    self.assertEqual(rendered, 'folders/22|22|deep')
    with self.assertRaises(KeyError):
      inventory._render_native_key('{item.missing}', 'folders/22', {})

  def test_enumerator_must_be_read_only(self):
    for verb in ('update', 'create', 'delete', 'set-iam-policy'):
      with self.assertRaises(SystemExit) as ctx:
        inventory.validate_native_spec('x/Y', {
            'command': ['logging', 'settings', verb],
            'key': '{item.name}'
        })
      self.assertIn('read-only verb', str(ctx.exception))

  def test_enumerator_may_not_narrow_its_own_output(self):
    """`--filter`/`--limit` shrink the denominator with no trace; scope
    belongs in the manifest scope block where it is reviewable."""
    for flag in ('--filter=name~prod', '--limit', '--format=value(name)'):
      with self.assertRaises(SystemExit) as ctx:
        inventory.validate_native_spec('x/Y', {
            'command': ['logging', 'sinks', flag, 'list'],
            'key': '{item.name}'
        })
      self.assertIn('may not', str(ctx.exception))

  def test_container_arg_template_shapes_the_scope_flag(self):
    """Not every read-only command takes --organization: IAM deny
    policies want --attachment-point=<service>/<container>. A mechanism
    that only spoke resource-manager flags would send half the
    non-CAI types back to being unenumerable."""
    calls = []

    def handler(cmd, **kwargs):
      del kwargs
      calls.append(' '.join(cmd))
      return [{'name': 'deny-external'}] if 'policies' in cmd else []

    with contextlib.redirect_stderr(io.StringIO()):
      entries, _, _ = self._collect(
          {
              'scope': {
                  'root': 'organizations/1'
              },
              'types': [{
                  'type': 'iam.googleapis.com/DenyPolicy',
                  'levels': ['organization'],
                  'enumerate': {
                      'command':
                          ['iam', 'policies', 'list', '--kind=denypolicies'],
                      'container_arg':
                          '--attachment-point=cloudresourcemanager.'
                          'googleapis.com/{container}',
                      'key': '//iam.googleapis.com/{container}/'
                             'denypolicies/{item.name}',
                  },
              }]
          }, handler)
    self.assertIn(
        'gcloud --quiet iam policies list --kind=denypolicies '
        '--attachment-point=cloudresourcemanager.googleapis.com/'
        'organizations/1 --format=json', calls)
    self.assertEqual(
        entries[0]['key'], '//iam.googleapis.com/organizations/1/denypolicies/'
        'deny-external')

  def test_container_arg_must_vary_per_container(self):
    for carg in ('--attachment-point=organizations/1', 'attachment=x',
                 '--attachment-point={item.name}'):
      with self.assertRaises(SystemExit) as ctx:
        inventory.validate_native_spec(
            'x/Y', {
                'command': ['iam', 'policies', 'list'],
                'container_arg': carg,
                'key': '{item.name}'
            })
      self.assertIn('container_arg', str(ctx.exception))

  def test_enumerator_may_not_choose_an_identity(self):
    with self.assertRaises(SystemExit) as ctx:
      inventory.validate_native_spec(
          'x/Y', {
              'command': [
                  'logging', 'sinks', 'list',
                  '--impersonate-service-account=admin@x.iam'
              ],
              'key': '{item.name}'
          })
    self.assertIn('may not', str(ctx.exception))

  def test_enumerator_shape_errors_are_named(self):
    bad = [
        ({
            'command': ['gcloud', 'logging', 'sinks', 'list'],
            'key': '{item.name}'
        }, 'drop the leading'),
        ({
            'command': 'logging sinks list',
            'key': '{item.name}'
        }, 'non-empty list'),
        ({
            'command': ['logging', 'sinks', 'list'],
            'key': 'a-literal-key'
        }, 'must be a template'),
        ({
            'command': ['logging', 'sinks', 'list'],
            'key': '{whatever}'
        }, 'unknown key field'),
        ('gcloud logging sinks list', 'must be a mapping'),
    ]
    for spec, expected in bad:
      with self.assertRaises(SystemExit) as ctx:
        inventory.validate_native_spec('x/Y', spec)
      self.assertIn(expected, str(ctx.exception))

  def test_pseudo_types_may_not_declare_an_enumerator(self):
    with self.assertRaises(SystemExit) as ctx:
      inventory.validate_manifest_types([{
          'type': 'org-policy',
          'enumerate': {
              'command': ['org-policies', 'list'],
              'key': '{item.name}'
          }
      }])
    self.assertIn('pseudo-type', str(ctx.exception))

  def test_manifest_is_validated_before_anything_is_executed(self):
    calls = []

    def handler(cmd, **kwargs):
      del kwargs
      calls.append(cmd)
      return []

    with self.assertRaises(SystemExit):
      self._collect(
          {
              'scope': {
                  'root': 'organizations/1'
              },
              'types': [{
                  'type': 'logging.googleapis.com/LogExclusion',
                  'enumerate': {
                      'command': ['logging', 'settings', 'update'],
                      'key': '{item.name}'
                  }
              }]
          }, handler)
    self.assertEqual(calls, [])


class TestIntegrityInputBinding(unittest.TestCase):

  def test_input_stamp_hashes_content(self):
    with tempfile.NamedTemporaryFile('w', delete=False) as f:
      f.write('hello\n')
      path = f.name
    try:
      line = integrity.input_stamp('rules', path)
      # Path shape: display_path() output only, no absolute path leak.
      self.assertNotIn(os.path.abspath(path), line)
      self.assertIn(os.path.basename(path), line)
      import hashlib
      self.assertIn(hashlib.sha256(b'hello\n').hexdigest(), line)
    finally:
      os.unlink(path)

  def test_input_stamp_does_not_leak_absolute_path(self):
    """Regression: an absolute path embeds home
    directory names, private worktree names and internal directory
    conventions. input_stamp must never print one.
    """
    with tempfile.NamedTemporaryFile('w', delete=False, suffix='.yaml') as f:
      f.write('rules: []\n')
      path = f.name
    try:
      abs_path = os.path.abspath(path)
      line = integrity.input_stamp('rules', path)
      self.assertNotIn(abs_path, line)
      # Stronger and environment-neutral: no component of the containing
      # directory may appear at all. Hardcoding known home-directory
      # prefixes both missed other layouts and baked one organisation's
      # workstation convention into a public test.
      self.assertNotIn(os.path.dirname(abs_path), line)
    finally:
      os.unlink(path)

  def test_display_path_is_relative_when_under_cwd(self):
    with tempfile.TemporaryDirectory() as td:
      sub = os.path.join(td, 'inner')
      os.makedirs(sub)
      target = os.path.join(sub, 'x.yaml')
      open(target, 'w').close()
      cwd = os.getcwd()
      try:
        os.chdir(td)
        self.assertEqual(integrity.display_path(target),
                         os.path.join('inner', 'x.yaml'))
      finally:
        os.chdir(cwd)

  def test_display_path_falls_back_to_basename_outside_cwd(self):
    with tempfile.TemporaryDirectory() as td:
      target = os.path.join(td, 'x.yaml')
      open(target, 'w').close()
      # cwd is elsewhere by default; display_path must return basename
      # (not the absolute path).
      out = integrity.display_path(target)
      self.assertEqual(out, 'x.yaml')
      self.assertNotIn(td, out)

  def test_tree_stamp_changes_when_a_file_changes(self):
    with tempfile.TemporaryDirectory() as td:
      p = os.path.join(td, 'a.tf')
      with open(p, 'w') as f:
        f.write('x')
      before = integrity.tree_stamp('workspace', [p], td)
      with open(p, 'w') as f:
        f.write('y')
      self.assertNotEqual(before, integrity.tree_stamp('workspace', [p], td))

  def test_frozen_digest_changes_when_any_frozen_file_is_edited(self):
    """There is no checked-in expected digest (a digest committed beside
    the files it covers is edited in the same commit and proves nothing).
    What must hold is that the computed digest moves on any edit, so a
    captured gate transcript can be compared against a clean checkout."""
    with tempfile.TemporaryDirectory() as t:
      for name in integrity.FROZEN_FILES:
        with open(os.path.join(t, name), 'w') as f:
          f.write(f'# {name}\n')
      before = integrity.frozen_digest(t)
      with open(os.path.join(t, 'benign-drift.yaml'), 'a') as f:
        f.write('  - resource: sneaky\n')
      self.assertNotEqual(before, integrity.frozen_digest(t))

  def test_every_script_is_inside_the_trust_boundary(self):
    """A script that is not in FROZEN_FILES can be edited without moving
    the stamp any gate output carries. manifest_from_state.py was
    outside it on import, while deciding the whole denominator."""
    scripts_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                               'scripts')
    on_disk = {
        f for f in os.listdir(scripts_dir)
        if (f.endswith('.py') or f.endswith('.yaml')) and not f.startswith('__')
    }
    self.assertEqual(on_disk, set(integrity.FROZEN_FILES))

  def test_missing_frozen_file_is_distinct_from_empty(self):
    with tempfile.TemporaryDirectory() as t:
      for name in integrity.FROZEN_FILES:
        with open(os.path.join(t, name), 'w') as f:
          f.write('')
      all_empty = integrity.frozen_digest(t)
      os.unlink(os.path.join(t, 'inventory.py'))
      self.assertNotEqual(all_empty, integrity.frozen_digest(t))


class TestManifestInit(unittest.TestCase):

  def test_draft_is_valid_yaml_with_foundation_enabled(self):
    survey = [
        {
            'key': '//x/folders/1',
            'asset_type': 'cloudresourcemanager.googleapis.com/Folder',
            'level': 'organization',
            'container': 'organizations/1'
        },
        {
            'key': '//x/instances/i',
            'asset_type': 'compute.googleapis.com/Instance',
            'level': 'project',
            'container': 'projects/9'
        },
    ]
    draft = manifest_init.draft_manifest(survey, 'organizations/1')
    parsed = yaml.safe_load(draft)
    self.assertEqual(parsed['scope']['root'], 'organizations/1')
    types = {t['type'] for t in parsed['types']}
    # Foundation pseudo-types and discovered foundation types enabled.
    self.assertIn('iam', types)
    self.assertIn('org-policy', types)
    self.assertIn('cloudresourcemanager.googleapis.com/Folder', types)
    # Non-foundation discovered types present only as comments.
    self.assertNotIn('compute.googleapis.com/Instance', types)
    self.assertIn('compute.googleapis.com/Instance', draft)

  def test_manifest_init_main_cli(self):
    with tempfile.TemporaryDirectory() as t:
      survey_path = os.path.join(t, "survey.json")
      out_path = os.path.join(t, "manifest.yaml")
      survey_data = [
          {
              "key": "//x/folders/1",
              "asset_type": "cloudresourcemanager.googleapis.com/Folder",
              "level": "organization",
              "container": "organizations/1"
          },
      ]
      with open(survey_path, "w") as f:
        json.dump(survey_data, f)
      sys_argv = sys.argv
      try:
        sys.argv = [
            "manifest_init.py", "--survey", survey_path, "--scope",
            "organizations/1", "--out", out_path
        ]
        rc = manifest_init.main()
        self.assertEqual(rc, 0)
        self.assertTrue(os.path.exists(out_path))
        with open(out_path, "r") as f:
          parsed = yaml.safe_load(f)
        self.assertEqual(parsed["scope"]["root"], "organizations/1")
      finally:
        sys.argv = sys_argv


class TestMultiScopeAndProjectRegistry(unittest.TestCase):

  def test_parse_single_scope(self):
    manifest = {'scope': {'root': 'organizations/123'}}
    scopes = inventory.parse_and_validate_scopes(manifest)
    self.assertEqual(len(scopes), 1)
    self.assertEqual(scopes[0]['root'], 'organizations/123')
    self.assertEqual(scopes[0]['levels'], inventory.VALID_LEVELS)

  def test_parse_multiple_scopes_with_levels(self):
    manifest = {
        'scopes': [
            {
                'name': 'org',
                'root': 'organizations/123',
                'levels': ['organization', 'folder']
            },
            {
                'name': 'workload',
                'root': 'projects/456',
                'levels': ['project'],
                'include': ['projects/456']
            },
        ]
    }
    scopes = inventory.parse_and_validate_scopes(manifest)
    self.assertEqual(len(scopes), 2)
    self.assertEqual(scopes[0]['name'], 'org')
    self.assertEqual(scopes[0]['levels'], {'organization', 'folder'})
    self.assertEqual(scopes[1]['name'], 'workload')
    self.assertEqual(scopes[1]['levels'], {'project'})

  def test_invalid_scope_root_rejected(self):
    with self.assertRaises(SystemExit):
      inventory.parse_and_validate_scopes({'scope': {'root': ''}})

  def test_invalid_scope_levels_rejected(self):
    with self.assertRaises(SystemExit):
      inventory.parse_and_validate_scopes(
          {'scopes': [{
              'root': 'organizations/1',
              'levels': ['bogus']
          }]})

  def test_project_registry_manual_and_ingest(self):
    reg = inventory.ProjectRegistry()
    reg.register('111111111111', 'prj-prod-audit-logs-0')
    num, pid = reg.resolve('prj-prod-audit-logs-0')
    self.assertEqual(num, '111111111111')
    self.assertEqual(pid, 'prj-prod-audit-logs-0')

    num2, pid2 = reg.resolve('111111111111')
    self.assertEqual(num2, '111111111111')
    self.assertEqual(pid2, 'prj-prod-audit-logs-0')

    expanded = reg.expand_target('prj-prod-audit-logs-0')
    self.assertIn('projects/prj-prod-audit-logs-0', expanded)
    self.assertIn('projects/111111111111', expanded)

  def test_in_subtree_with_registry(self):
    reg = inventory.ProjectRegistry()
    reg.register('99999', 'my-app')

    # Asset uses numeric project in ancestors
    asset = {'ancestors': ['projects/99999', 'folders/1', 'organizations/1']}

    # Matching with alphanumeric ID in include
    self.assertTrue(inventory.in_subtree(asset, ['my-app'], [], reg))
    self.assertTrue(inventory.in_subtree(asset, ['projects/my-app'], [], reg))
    self.assertTrue(inventory.in_subtree(asset, ['projects/99999'], [], reg))
    self.assertFalse(inventory.in_subtree(asset, ['other-app'], [], reg))

    # Exclusion with alphanumeric ID
    self.assertFalse(inventory.in_subtree(asset, [], ['my-app'], reg))


class TestDeletedContainersFilter(unittest.TestCase):

  def test_is_deleted_container_folder(self):
    active_folder = {
        'assetType': 'cloudresourcemanager.googleapis.com/Folder',
        'name': '//cloudresourcemanager.googleapis.com/folders/123',
        'resource': {
            'data': {
                'lifecycleState': 'ACTIVE'
            }
        }
    }
    deleted_folder = {
        'assetType': 'cloudresourcemanager.googleapis.com/Folder',
        'name': '//cloudresourcemanager.googleapis.com/folders/456',
        'resource': {
            'data': {
                'lifecycleState': 'DELETE_REQUESTED'
            }
        }
    }
    deleted_folder_state = {
        'assetType': 'cloudresourcemanager.googleapis.com/Folder',
        'name': '//cloudresourcemanager.googleapis.com/folders/789',
        'resource': {
            'data': {
                'state': 'DELETE_REQUESTED'
            }
        }
    }
    self.assertFalse(inventory._is_deleted_container(active_folder))
    self.assertTrue(inventory._is_deleted_container(deleted_folder))
    self.assertTrue(inventory._is_deleted_container(deleted_folder_state))

  def test_is_deleted_container_project(self):
    active_project = {
        'assetType': 'cloudresourcemanager.googleapis.com/Project',
        'name': '//cloudresourcemanager.googleapis.com/projects/111',
        'resource': {
            'data': {
                'lifecycleState': 'ACTIVE'
            }
        }
    }
    deleted_project = {
        'assetType': 'cloudresourcemanager.googleapis.com/Project',
        'name': '//cloudresourcemanager.googleapis.com/projects/222',
        'resource': {
            'data': {
                'lifecycleState': 'DELETE_REQUESTED'
            }
        }
    }
    self.assertFalse(inventory._is_deleted_container(active_project))
    self.assertTrue(inventory._is_deleted_container(deleted_project))

  def test_is_deleted_container_non_container(self):
    bucket = {
        'assetType': 'storage.googleapis.com/Bucket',
        'name': '//storage.googleapis.com/projects/_/buckets/my-bkt',
        'resource': {
            'data': {
                'lifecycleState': 'DELETE_REQUESTED'
            }
        }
    }
    self.assertFalse(inventory._is_deleted_container(bucket))

  def test_has_deleted_ancestor(self):
    deleted = {'folders/999', 'projects/888'}
    child_of_deleted_folder = {
        'name': '//storage.googleapis.com/projects/_/buckets/b',
        'ancestors': ['projects/111', 'folders/999', 'organizations/1']
    }
    child_of_active_folder = {
        'name': '//storage.googleapis.com/projects/_/buckets/b2',
        'ancestors': ['projects/111', 'folders/100', 'organizations/1']
    }
    self.assertTrue(
        inventory._has_deleted_ancestor(child_of_deleted_folder, deleted))
    self.assertFalse(
        inventory._has_deleted_ancestor(child_of_active_folder, deleted))

  def test_project_registry_tracks_deleted_containers(self):
    reg = inventory.ProjectRegistry()
    assets = [
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Project',
            'name': '//cloudresourcemanager.googleapis.com/projects/111',
            'resource': {
                'data': {
                    'projectId': 'prj-active',
                    'projectNumber': '111',
                    'lifecycleState': 'ACTIVE'
                }
            }
        },
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Project',
            'name': '//cloudresourcemanager.googleapis.com/projects/222',
            'resource': {
                'data': {
                    'projectId': 'prj-deleted',
                    'projectNumber': '222',
                    'lifecycleState': 'DELETE_REQUESTED'
                }
            }
        },
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Folder',
            'name': '//cloudresourcemanager.googleapis.com/folders/333',
            'resource': {
                'data': {
                    'name': 'folders/333',
                    'lifecycleState': 'DELETE_REQUESTED'
                }
            }
        },
    ]
    reg.ingest_assets(assets)
    self.assertIn('projects/222', reg.deleted_containers)
    self.assertIn('projects/prj-deleted', reg.deleted_containers)
    self.assertIn('folders/333', reg.deleted_containers)
    self.assertNotIn('projects/111', reg.deleted_containers)

  def test_collect_active_filtering(self):
    real = inventory.run_json
    fake_assets = [
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Folder',
            'name': '//cloudresourcemanager.googleapis.com/folders/111',
            'ancestors': ['folders/111', 'organizations/1'],
            'resource': {
                'data': {
                    'name': 'folders/111',
                    'displayName': 'ActiveFolder',
                    'lifecycleState': 'ACTIVE'
                }
            }
        },
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Folder',
            'name': '//cloudresourcemanager.googleapis.com/folders/222',
            'ancestors': ['folders/222', 'organizations/1'],
            'resource': {
                'data': {
                    'name': 'folders/222',
                    'displayName': 'DeletedFolder',
                    'lifecycleState': 'DELETE_REQUESTED'
                }
            }
        },
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Project',
            'name': '//cloudresourcemanager.googleapis.com/projects/333',
            'ancestors': ['projects/333', 'folders/222', 'organizations/1'],
            'resource': {
                'data': {
                    'projectId': 'child-of-deleted',
                    'projectNumber': '333',
                    'lifecycleState': 'ACTIVE'
                }
            }
        },
    ]

    def fake(cmd, **kwargs):
      del cmd, kwargs
      return list(fake_assets)

    inventory.run_json = fake
    try:
      manifest = {
          'scope': {
              'root': 'organizations/1'
          },
          'types': [
              {
                  'type': 'cloudresourcemanager.googleapis.com/Folder'
              },
              {
                  'type': 'cloudresourcemanager.googleapis.com/Project'
              },
          ]
      }
      # Default: excludes deleted folder 222 and its child project 333
      entries_default, reg_default, _ = inventory.collect(
          manifest, include_deleted=False)
      keys_default = [e['key'] for e in entries_default]
      self.assertIn('//cloudresourcemanager.googleapis.com/folders/111',
                    keys_default)
      self.assertNotIn('//cloudresourcemanager.googleapis.com/folders/222',
                       keys_default)
      self.assertNotIn('//cloudresourcemanager.googleapis.com/projects/333',
                       keys_default)

      # Opt-in: include_deleted=True retains both
      entries_all, reg_all, _ = inventory.collect(manifest,
                                                  include_deleted=True)
      keys_all = [e['key'] for e in entries_all]
      self.assertIn('//cloudresourcemanager.googleapis.com/folders/111',
                    keys_all)
      self.assertIn('//cloudresourcemanager.googleapis.com/folders/222',
                    keys_all)
      self.assertIn('//cloudresourcemanager.googleapis.com/projects/333',
                    keys_all)
    finally:
      inventory.run_json = real

  def test_survey_active_filtering(self):
    real = inventory.run_json
    fake_assets = [
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Folder',
            'name': '//cloudresourcemanager.googleapis.com/folders/111',
            'ancestors': ['folders/111', 'organizations/1'],
            'resource': {
                'data': {
                    'lifecycleState': 'ACTIVE'
                }
            }
        },
        {
            'assetType': 'cloudresourcemanager.googleapis.com/Folder',
            'name': '//cloudresourcemanager.googleapis.com/folders/222',
            'ancestors': ['folders/222', 'organizations/1'],
            'resource': {
                'data': {
                    'lifecycleState': 'DELETE_REQUESTED'
                }
            }
        },
    ]

    def fake(cmd, **kwargs):
      del cmd, kwargs
      return list(fake_assets)

    inventory.run_json = fake
    try:
      entries_default = inventory.survey('organizations/1',
                                         include_deleted=False)
      self.assertEqual(len(entries_default), 1)
      self.assertEqual(entries_default[0]['key'],
                       '//cloudresourcemanager.googleapis.com/folders/111')

      entries_all = inventory.survey('organizations/1', include_deleted=True)
      self.assertEqual(len(entries_all), 2)
    finally:
      inventory.run_json = real

  def test_inventory_google_managed_logging_defaults_filtering(self):
    real = inventory.run_json
    fake_assets = [
        {
            'assetType':
                'logging.googleapis.com/LogSink',
            'name':
                '//logging.googleapis.com/organizations/1/sinks/custom-sink',
            'ancestors': ['organizations/1'],
        },
        {
            'assetType': 'logging.googleapis.com/LogSink',
            'name': '//logging.googleapis.com/organizations/1/sinks/_Default',
            'ancestors': ['organizations/1'],
        },
        {
            'assetType': 'logging.googleapis.com/LogSink',
            'name': '//logging.googleapis.com/organizations/1/sinks/_Required',
            'ancestors': ['organizations/1'],
        },
        {
            'assetType':
                'logging.googleapis.com/LogBucket',
            'name':
                '//logging.googleapis.com/projects/12345/locations/global/buckets/custom-bucket',
            'ancestors': ['projects/12345', 'organizations/1'],
        },
        {
            'assetType':
                'logging.googleapis.com/LogBucket',
            'name':
                '//logging.googleapis.com/projects/12345/locations/global/buckets/_Default',
            'ancestors': ['projects/12345', 'organizations/1'],
        },
        {
            'assetType':
                'logging.googleapis.com/LogBucket',
            'name':
                '//logging.googleapis.com/projects/12345/locations/global/buckets/_Required',
            'ancestors': ['projects/12345', 'organizations/1'],
        },
    ]

    def fake(cmd, **kwargs):
      del cmd, kwargs
      return list(fake_assets)

    inventory.run_json = fake
    try:
      manifest = {
          'scope': {
              'root': 'organizations/1'
          },
          'types': [
              {
                  'type': 'logging.googleapis.com/LogSink'
              },
              {
                  'type': 'logging.googleapis.com/LogBucket'
              },
          ]
      }
      # Default: excludes _Default and _Required sinks and buckets
      entries_default, _, _ = inventory.collect(manifest,
                                                include_logging_defaults=False)
      keys_default = [e['key'] for e in entries_default]
      self.assertIn(
          '//logging.googleapis.com/organizations/1/sinks/custom-sink',
          keys_default)
      self.assertIn(
          '//logging.googleapis.com/projects/12345/locations/global/buckets/custom-bucket',
          keys_default)
      self.assertNotIn(
          '//logging.googleapis.com/organizations/1/sinks/_Default',
          keys_default)
      self.assertNotIn(
          '//logging.googleapis.com/organizations/1/sinks/_Required',
          keys_default)
      self.assertNotIn(
          '//logging.googleapis.com/projects/12345/locations/global/buckets/_Default',
          keys_default)
      self.assertNotIn(
          '//logging.googleapis.com/projects/12345/locations/global/buckets/_Required',
          keys_default)

      # Opt-in: include_logging_defaults=True retains all
      entries_all, _, _ = inventory.collect(manifest,
                                            include_logging_defaults=True)
      keys_all = [e['key'] for e in entries_all]
      self.assertEqual(len(keys_all), 6)
      self.assertIn('//logging.googleapis.com/organizations/1/sinks/_Default',
                    keys_all)
      self.assertIn(
          '//logging.googleapis.com/projects/12345/locations/global/buckets/_Required',
          keys_all)
    finally:
      inventory.run_json = real

  def test_survey_google_managed_logging_defaults_filtering(self):
    real = inventory.run_json
    fake_assets = [
        {
            'assetType':
                'logging.googleapis.com/LogSink',
            'name':
                '//logging.googleapis.com/organizations/1/sinks/custom-sink',
            'ancestors': ['organizations/1'],
        },
        {
            'assetType': 'logging.googleapis.com/LogSink',
            'name': '//logging.googleapis.com/organizations/1/sinks/_Default',
            'ancestors': ['organizations/1'],
        },
    ]

    def fake(cmd, **kwargs):
      del cmd, kwargs
      return list(fake_assets)

    inventory.run_json = fake
    try:
      entries_default = inventory.survey('organizations/1',
                                         include_logging_defaults=False)
      self.assertEqual(len(entries_default), 1)
      self.assertEqual(
          entries_default[0]['key'],
          '//logging.googleapis.com/organizations/1/sinks/custom-sink')

      entries_all = inventory.survey('organizations/1',
                                     include_logging_defaults=True)
      self.assertEqual(len(entries_all), 2)
    finally:
      inventory.run_json = real

  def test_survey_pam_grants_filtering(self):
    real = inventory.run_json
    fake_assets = [
        {
            'assetType':
                'privilegedaccessmanager.googleapis.com/Entitlement',
            'name':
                '//privilegedaccessmanager.googleapis.com/organizations/1/locations/global/entitlements/org-admin',
            'ancestors': ['organizations/1'],
        },
        {
            'assetType':
                'privilegedaccessmanager.googleapis.com/Grant',
            'name':
                '//privilegedaccessmanager.googleapis.com/organizations/1/locations/global/entitlements/org-admin/grants/grant-123',
            'ancestors': ['organizations/1'],
        },
    ]

    def fake(cmd, **kwargs):
      del cmd, kwargs
      return list(fake_assets)

    inventory.run_json = fake
    try:
      entries_default = inventory.survey('organizations/1',
                                         include_pam_grants=False)
      self.assertEqual(len(entries_default), 1)
      self.assertEqual(
          entries_default[0]['key'],
          '//privilegedaccessmanager.googleapis.com/organizations/1/locations/global/entitlements/org-admin'
      )

      entries_all = inventory.survey('organizations/1', include_pam_grants=True)
      self.assertEqual(len(entries_all), 2)
    finally:
      inventory.run_json = real


def _parse_state(state_content):
  """Runs parse_state_files over one in-memory state document."""
  with tempfile.NamedTemporaryFile('w', suffix='.tfstate', delete=False) as f:
    json.dump(state_content, f)
    sp = f.name
  try:
    return manifest_from_state.parse_state_files([sp])
  finally:
    os.remove(sp)


class TestManifestFromState(unittest.TestCase):

  def test_manifest_from_state_synthesis(self):
    state_content = {
        'format_version':
            '1.0',
        'resources': [{
            'mode':
                'managed',
            'type':
                'google_folder',
            'instances': [{
                'attributes': {
                    'name': 'folders/111222',
                    'org_id': '123456789012',
                    'display_name': 'Networking'
                }
            }]
        }, {
            'mode':
                'managed',
            'type':
                'google_project',
            'instances': [{
                'attributes': {
                    'project_id': 'my-net-prj',
                    'number': '987654321',
                    'folder_id': '111222'
                }
            }]
        }, {
            'mode':
                'managed',
            'type':
                'google_compute_network',
            'instances': [{
                'attributes': {
                    'name': 'prod-vpc',
                    'project': 'my-net-prj'
                }
            }]
        }, {
            'mode':
                'managed',
            'type':
                'google_iam_workload_identity_pool_provider',
            'instances': [{
                'attributes': {
                    'workload_identity_pool_id': 'my-pool',
                    'workload_identity_pool_provider_id': 'my-provider',
                    'project': 'my-net-prj'
                }
            }]
        }]
    }
    with tempfile.NamedTemporaryFile('w', suffix='.tfstate', delete=False) as f:
      json.dump(state_content, f)
      sp = f.name

    try:
      org_ids, projects, pnums, folders, types_found = manifest_from_state.parse_state_files(
          [sp])
      self.assertIn('123456789012', org_ids)
      self.assertIn('my-net-prj', projects)
      self.assertEqual(pnums.get('my-net-prj'), '987654321')
      self.assertIn('111222', folders)
      self.assertIn('compute.googleapis.com/Network', types_found)
      self.assertIn('iam.googleapis.com/WorkloadIdentityPoolProvider',
                    types_found)
      # THE REGRESSION. google_project stores folder_id as a bare number
      # ('111222'), not 'folders/111222'. The prefix-only check classified
      # this project as organization-level, apply_level_filter then kept
      # only organization-level containers, and every folder-nested
      # project silently left the denominator with a green gate.
      self.assertEqual(
          types_found['cloudresourcemanager.googleapis.com/Project']['levels'],
          {'organization', 'folder'})

      manifest_text = manifest_from_state.generate_manifest(
          org_ids, projects, pnums, folders, types_found, [sp])
      parsed = yaml.safe_load(manifest_text)
      self.assertEqual(len(parsed['scopes']), 2)
      self.assertEqual(parsed['scopes'][0]['name'], 'org-foundation')
      self.assertEqual(parsed['scopes'][0]['root'],
                       'organizations/123456789012')
      self.assertEqual(parsed['scopes'][1]['name'], 'stage-projects')
      # CAI ancestors are project NUMBERS: bind to the number we already
      # know rather than to an id that needs a live lookup to match.
      self.assertEqual(parsed['scopes'][1]['include'], ['projects/987654321'])
      # Source paths are basenames, never the operator's home directory.
      self.assertIn(os.path.basename(sp), manifest_text)
      self.assertNotIn(os.path.dirname(sp), manifest_text)
    finally:
      os.remove(sp)

  def test_leaf_iam_bindings_map_to_their_parent_type(self):
    """`google_storage_bucket_iam_binding` is not an asset type; it is
    the iam-policy content type on a bucket. Mapping it to the PARENT
    with `iam: true` is what puts it in the denominator — left unmapped,
    it read as "CAI does not support this", which is false and sends the
    operator to a waiver for coverage CAI has had all along."""
    _, _, _, _, types_found = _parse_state({
        'resources': [{
            'mode': 'managed',
            'type': 'google_storage_bucket_iam_binding',
            'instances': [{
                'attributes': {
                    'bucket': 'b-1'
                }
            }]
        }, {
            'mode': 'managed',
            'type': 'google_tags_tag_value_iam_binding',
            'instances': [{
                'attributes': {
                    'tag_value': 'tagValues/1'
                }
            }]
        }]
    })
    self.assertEqual(types_found['storage.googleapis.com/Bucket']['flags'],
                     {'iam': True})
    self.assertEqual(
        types_found['cloudresourcemanager.googleapis.com/TagValue']['flags'],
        {'iam': True})

  def test_essential_contacts_level_is_read_from_the_parent(self):
    _, _, _, _, types_found = _parse_state({
        'resources': [{
            'mode':
                'managed',
            'type':
                'google_essential_contacts_contact',
            'instances': [{
                'attributes': {
                    'parent': 'organizations/1'
                }
            }, {
                'attributes': {
                    'parent': 'folders/22'
                }
            }]
        }]
    })
    self.assertEqual(
        types_found['essentialcontacts.googleapis.com/Contact']['levels'],
        {'organization', 'folder'})

  def test_unmapped_warning_does_not_read_as_cai_unsupported(self):
    """The warning listed types 'not in TF_TYPE_MAP' and was read as
    'CAI does not support these'. Two different statements, and the
    wrong one sends an operator to waivers for types CAI models."""
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      _parse_state({
          'resources': [{
              'mode': 'managed',
              'type': 'google_storage_bucket_object',
              'instances': [{
                  'attributes': {
                      'name': 'cfg.yaml'
                  }
              }]
          }]
      })
    err = buf.getvalue()
    self.assertIn('google_storage_bucket_object', err)
    self.assertIn('THIS TOOL has no static', err)
    self.assertIn('says nothing about whether Cloud Asset', err)
    # ... and it names all four exits, not just the waiver.
    for remedy in ('supported-asset-types', 'iam: true', 'enumerate:',
                   'signed waiver'):
      self.assertIn(remedy, err)

  def test_project_level_from_prefixed_parent(self):
    """The other shape: `parent: folders/111222` must classify too."""
    _, _, _, _, types_found = _parse_state({
        'resources': [{
            'mode':
                'managed',
            'type':
                'google_project',
            'instances': [{
                'attributes': {
                    'project_id': 'p',
                    'parent': 'folders/111222'
                }
            }]
        }]
    })
    self.assertIn(
        'folder',
        types_found['cloudresourcemanager.googleapis.com/Project']['levels'])

  def test_tag_binding_parent_is_not_defaulted_to_organization(self):
    """google_tags_tag_binding stores a full CAI resource name. The
    service prefix matched none of the hierarchy prefixes, so project
    and folder tag bindings were declared organization-level and
    vanished from the sweep."""
    _, _, _, _, types_found = _parse_state({
        'resources': [{
            'mode':
                'managed',
            'type':
                'google_tags_tag_binding',
            'instances': [{
                'attributes': {
                    'parent':
                        '//cloudresourcemanager.googleapis.com/projects/123456'
                }
            }]
        }]
    })
    self.assertEqual(
        types_found['cloudresourcemanager.googleapis.com/TagBinding']['levels'],
        {'project'})

  def test_unclassifiable_parent_becomes_unknown_not_organization(self):
    _, _, _, _, types_found = _parse_state({
        'resources': [{
            'mode': 'managed',
            'type': 'google_tags_tag_binding',
            'instances': [{
                'attributes': {
                    'parent': 'something/else'
                }
            }]
        }]
    })
    self.assertEqual(
        types_found['cloudresourcemanager.googleapis.com/TagBinding']['levels'],
        {'unknown'})

  def test_multi_org_state_is_refused(self):
    """Picking sorted(org_ids)[0] dropped every asset under the others."""
    with self.assertRaises(SystemExit) as cm:
      manifest_from_state.generate_manifest(
          {'1', '2'}, set(), {}, set(),
          {'x': {
              'levels': {'organization'},
              'flags': {}
          }}, ['s.tfstate'])
    self.assertIn('more than one organization', str(cm.exception))

  def test_empty_state_is_refused_not_given_a_placeholder_root(self):
    """organizations/000000000000 is a manifest that looks valid and
    enumerates nothing."""
    with self.assertRaises(SystemExit) as cm:
      manifest_from_state.generate_manifest(set(), set(), {}, set(), {},
                                            ['s.tfstate'])
    msg = str(cm.exception)
    self.assertIn('scope root', msg)
    self.assertNotIn('000000000000', msg)

  def test_project_only_state_gets_project_roots(self):
    """A per-project state is the most common Mode A input, and
    inventory.py supports project roots. Refusing it would be a
    regression dressed as strictness."""
    text = manifest_from_state.generate_manifest(
        set(), {'my-prj'}, {'my-prj': '987654321'}, set(),
        {'storage.googleapis.com/Bucket': {
            'levels': {'project'},
            'flags': {}
        }}, ['s.tfstate'])
    parsed = yaml.safe_load(text)
    self.assertEqual(parsed['scopes'][0]['root'], 'projects/987654321')
    inventory.parse_and_validate_scopes(parsed)

  def test_multi_folder_state_without_org_is_refused(self):
    with self.assertRaises(SystemExit) as cm:
      manifest_from_state.generate_manifest(
          set(), set(), {}, {'111222', '333444'},
          {'x': {
              'levels': {'folder'},
              'flags': {}
          }}, ['s.tfstate'])
    self.assertIn('more than one folder', str(cm.exception))

  def test_foreign_provider_org_attribute_is_ignored(self):
    """`organization` is a REQUIRED attribute on tfe_workspace, and
    github_*/azuread_* carry one too. Harvesting every provider let a
    Terraform Cloud org name into org_ids and tripped the multi-org
    refusal on a state with exactly one Google organization."""
    org_ids, _, _, _, _ = _parse_state({
        'resources': [{
            'mode':
                'managed',
            'type':
                'tfe_workspace',
            'instances': [{
                'attributes': {
                    'name': 'prod',
                    'organization': 'acme-tfc'
                }
            }]
        }, {
            'mode':
                'managed',
            'type':
                'google_folder',
            'instances': [{
                'attributes': {
                    'name': 'folders/111222',
                    'parent': 'organizations/123456789012'
                }
            }]
        }]
    })
    self.assertEqual(org_ids, {'123456789012'})

  def test_generated_manifest_round_trips_through_inventory(self):
    """The artefact, not just the units: a bare-number include or a
    type declared only at `unknown` is invisible to unit assertions and
    blows up (or silently empties the denominator) in inventory.py."""
    org_ids, projects, pnums, folders, types_found = _parse_state({
        'resources': [{
            'mode':
                'managed',
            'type':
                'google_folder',
            'instances': [{
                'attributes': {
                    'name': 'folders/111222',
                    'parent': 'organizations/123456789012'
                }
            }]
        }, {
            'mode': 'managed',
            'type': 'google_storage_bucket',
            'instances': [{
                'attributes': {
                    'name': 'b',
                    'project': '987654321'
                }
            }]
        }, {
            'mode': 'managed',
            'type': 'google_tags_tag_binding',
            'instances': [{
                'attributes': {
                    'parent': 'something/else'
                }
            }]
        }]
    })
    text = manifest_from_state.generate_manifest(org_ids, projects, pnums,
                                                 folders, types_found,
                                                 ['s.tfstate'])
    parsed = yaml.safe_load(text)
    # Must be accepted by the tool that consumes it...
    scopes = inventory.parse_and_validate_scopes(parsed)
    inventory.validate_manifest_types(parsed['types'])
    # ... the project seen only as a number must be prefixed, not bare...
    self.assertIn('projects/987654321', parsed['scopes'][-1]['include'])
    # ... and a type declared at `unknown` needs `unknown` in some scope,
    # or it intersects to the empty set and is swept then discarded.
    unknown_types = [
        t['type'] for t in parsed['types'] if 'unknown' in t['levels']
    ]
    self.assertTrue(unknown_types)
    self.assertTrue(any('unknown' in s['levels'] for s in scopes))

  def test_force_is_required_to_overwrite_an_existing_manifest(self):
    with tempfile.TemporaryDirectory() as td:
      state = os.path.join(td, 's.tfstate')
      with open(state, 'w') as f:
        json.dump(
            {
                'resources': [{
                    'mode':
                        'managed',
                    'type':
                        'google_folder',
                    'instances': [{
                        'attributes': {
                            'name': 'folders/111222',
                            'parent': 'organizations/123456789012'
                        }
                    }]
                }]
            }, f)
      out = os.path.join(td, 'import-manifest.yaml')

      def run(extra=()):
        argv = ['manifest_from_state.py', '--state', state, '--out', out]
        old = sys.argv
        sys.argv = argv + list(extra)
        try:
          with contextlib.redirect_stdout(io.StringIO()), \
               contextlib.redirect_stderr(io.StringIO()):
            manifest_from_state.main()
        finally:
          sys.argv = old

      run()
      with self.assertRaises(SystemExit) as cm:
        run()
      msg = str(cm.exception)
      self.assertIn('already exists', msg)
      # ... and the refusal must not print the operator's home directory.
      self.assertNotIn(td, msg)
      run(['--force'])

  def test_acm_types_carry_the_identity_prefix(self):
    """CAI names these three `identity.accesscontextmanager...`. The bare
    spelling matches nothing, and a mistyped asset type does not error:
    the sweep returns zero and the gate goes vacuously green."""
    for tf_type in ('google_access_context_manager_access_policy',
                    'google_access_context_manager_access_level',
                    'google_access_context_manager_service_perimeter'):
      cai_type = manifest_from_state.TF_TYPE_MAP[tf_type][0]
      self.assertTrue(
          cai_type.startswith('identity.accesscontextmanager.googleapis.com/'),
          f'{tf_type} maps to {cai_type}')

  def test_unmapped_google_types_are_reported(self):
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
      _parse_state({
          'resources': [{
              'mode': 'managed',
              'type': 'google_billing_budget',
              'instances': [{
                  'attributes': {
                      'project': 'p'
                  }
              }]
          }]
      })
    self.assertIn('google_billing_budget', err.getvalue())
    self.assertIn('not in TF_TYPE_MAP', err.getvalue())

  def test_manifest_from_state_folder_root_fallback(self):
    state_content = {
        'resources': [{
            'mode':
                'managed',
            'type':
                'google_folder',
            'instances': [{
                'attributes': {
                    'name': 'folders/555666',
                    'parent': 'folders/111222'
                }
            }]
        }]
    }
    with tempfile.NamedTemporaryFile('w', suffix='.tfstate', delete=False) as f:
      json.dump(state_content, f)
      sp = f.name

    try:
      org_ids, projects, pnums, folders, types_found = manifest_from_state.parse_state_files(
          [sp])
      self.assertEqual(len(org_ids), 0)
      self.assertIn('555666', folders)
      manifest_text = manifest_from_state.generate_manifest(
          org_ids, projects, pnums, folders, types_found, [sp])
      parsed = yaml.safe_load(manifest_text)
      self.assertEqual(parsed['scopes'][0]['root'], 'folders/555666')
    finally:
      os.remove(sp)

  def test_manifest_from_state_fail_closed_on_bad_file(self):
    with self.assertRaises(SystemExit):
      manifest_from_state.parse_state_files(
          ['/nonexistent/path/to/state.tfstate'])


class TestCoverageEdgeCases(unittest.TestCase):

  def test_hcl_cleaning_with_escaped_quotes_and_braces(self):
    line = '  name = "foo\\"#bar" # real comment'
    cleaned = coverage._clean_hcl_line(line)
    self.assertEqual(cleaned, 'name = "foo\\"#bar"')

    line2 = '  to = module.folder["escaped\\\"name"].google_folder.folder[0]'
    cleaned2 = coverage._clean_hcl_line(line2)
    self.assertIn('module.folder', cleaned2)

  def test_unsigned_waivers_strict_type_checking(self):
    waivers = [
        {
            'key': 'k1',
            'reason': 'r1',
            'signed_by': 'alice@example.com'
        },
        {
            'key': 'k2',
            'reason': 'r2',
            'signed_by': ''
        },
        {
            'key': 'k3',
            'reason': 'r3',
            'signed_by': []
        },  # non-string truthy
        {
            'key': 'k4',
            'reason': 'r4'
        },
    ]
    unsigned = coverage.unsigned_waivers(waivers)
    self.assertEqual(unsigned, ['k2', 'k3', 'k4'])


class TestCaiSplitTypes(unittest.TestCase):
  """CAI's list and search surfaces use DIFFERENT asset-type taxonomies.

  Live-run finding: a global Private Service Connect address was absent
  from the denominator. `gcloud asset list --asset-types=
  compute.googleapis.com/Address` returned 33 regional addresses;
  `search-all-resources` for the same type returned 34, including the
  global one. The cause is not a disagreement between the surfaces but a
  documented taxonomy split: the list surface types global addresses as
  `compute.googleapis.com/GlobalAddress`, which the manifest never
  declared and the tool therefore never asked for.

  Every existing guard missed it — the declared type is supported (no
  unsupported-type fallback), the sweep succeeded (no SWEEP_FAILURES),
  and it yielded 33 (no zero-yield warning) — which is why this needs
  its own mechanism rather than a sharper error message.
  """

  _MANIFEST = {
      'scope': {
          'root': 'projects/my-prj'
      },
      'types': [{
          'type': 'compute.googleapis.com/Address',
          'levels': ['project']
      }],
  }

  @staticmethod
  def _addr(name, atype):
    return {
        'name': f'//compute.googleapis.com/projects/my-prj/{name}',
        'assetType': atype,
        'ancestors': ['projects/111', 'organizations/1'],
    }

  _REGIONAL = 'regions/europe-west1/addresses/regional-one'
  _GLOBAL = 'global/addresses/psc-endpoint'

  def _collect(self, handler, manifest=None, **kwargs):
    real = inventory.run_json
    inventory.run_json = handler
    try:
      return inventory.collect(manifest or self._MANIFEST, **kwargs)
    finally:
      inventory.run_json = real

  @staticmethod
  def _resolve_project(joined):
    """CAI ancestors are project NUMBERS, so collect() resolves the scope
    id first; unresolved, in_subtree() matches nothing."""
    if 'projects describe' in joined:
      return {
          'projectNumber': '111',
          'projectId': 'my-prj',
          'lifecycleState': 'ACTIVE'
      }
    return None

  def _list_handler(self, calls):

    def handler(cmd, **kwargs):
      joined = ' '.join(cmd)
      calls.append(joined)
      resolved = self._resolve_project(joined)
      if resolved is not None:
        return resolved
      if 'search-all-resources' in joined:
        return [
            {
                'name': self._addr(self._REGIONAL, '')['name']
            },
            {
                'name': self._addr(self._GLOBAL, '')['name']
            },
        ]
      if '--content-type=resource' in joined and 'Address' in joined:
        out = [self._addr(self._REGIONAL, 'compute.googleapis.com/Address')]
        if 'GlobalAddress' in joined:
          out.append(
              self._addr(self._GLOBAL, 'compute.googleapis.com/GlobalAddress'))
        return out
      return []

    return handler

  def test_split_sibling_map_only_covers_declared_unified_types(self):
    self.assertEqual(
        inventory.split_sibling_map(['compute.googleapis.com/Address']), {
            'compute.googleapis.com/GlobalAddress':
                'compute.googleapis.com/Address'
        })
    # Nothing declared, nothing swept: the table never widens a sweep on
    # its own.
    self.assertEqual(
        inventory.split_sibling_map(['storage.googleapis.com/Bucket']), {})

  def test_explicitly_declared_sibling_is_not_remapped(self):
    """An operator who names the list-surface type wants it accounted as
    itself; remapping would make their per-declared-type yield read 0."""
    self.assertEqual(
        inventory.split_sibling_map([
            'compute.googleapis.com/Address',
            'compute.googleapis.com/GlobalAddress',
        ]), {})

  def test_global_address_enters_the_denominator(self):
    calls = []
    with contextlib.redirect_stderr(io.StringIO()):
      entries, _, _ = self._collect(self._list_handler(calls))
    keys = {e['key'] for e in entries}
    self.assertIn(self._addr(self._GLOBAL, '')['name'], keys)
    self.assertIn(self._addr(self._REGIONAL, '')['name'], keys)

  def test_sibling_rides_along_in_the_existing_call(self):
    """The fix must cost zero extra API calls: `asset list` takes a
    comma-separated --asset-types."""
    calls = []
    with contextlib.redirect_stderr(io.StringIO()):
      self._collect(self._list_handler(calls))
    sweeps = [c for c in calls if '--content-type=resource' in c]
    self.assertEqual(len(sweeps), 1, calls)
    self.assertIn('compute.googleapis.com/Address', sweeps[0])
    self.assertIn('compute.googleapis.com/GlobalAddress', sweeps[0])

  def test_sibling_is_accounted_under_the_declared_type(self):
    calls = []
    with contextlib.redirect_stderr(io.StringIO()):
      entries, _, _ = self._collect(self._list_handler(calls))
    glob = [
        e for e in entries if e['key'].endswith('global/addresses/psc-endpoint')
    ][0]
    self.assertEqual(glob['asset_type'], 'compute.googleapis.com/Address')
    # ...but the list-surface type is preserved, not laundered.
    self.assertEqual(glob['cai_list_type'],
                     'compute.googleapis.com/GlobalAddress')

  def test_sibling_survives_the_level_filter(self):
    """apply_level_filter() keys off asset_type. A sibling left under its
    own type would match no manifest entry and be filtered by the
    permissive default instead of by the operator's `levels`."""
    manifest = {
        'scope': {
            'root': 'projects/my-prj'
        },
        'types': [{
            'type': 'compute.googleapis.com/Address',
            'levels': ['project']
        }],
    }
    calls = []
    with contextlib.redirect_stderr(io.StringIO()):
      entries, _, _ = self._collect(self._list_handler(calls), manifest)
    self.assertEqual(len(entries), 2)
    self.assertTrue(all(e['level'] == 'project' for e in entries))

  def test_split_sweep_is_announced_and_stamped(self):
    calls = []
    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      self._collect(self._list_handler(calls))
    err = buf.getvalue()
    self.assertIn('split by scope', err)
    self.assertIn('compute.googleapis.com/GlobalAddress', err)
    self.assertIn('--verify-search-parity', err)
    self.assertEqual(len(inventory.SPLIT_TYPE_SWEEPS), 1)
    self.assertEqual(
        inventory.SPLIT_TYPE_SWEEPS[0], {
            'declared_type': 'compute.googleapis.com/Address',
            'cai_list_type': 'compute.googleapis.com/GlobalAddress',
            'scope': 'projects/my-prj',
            'yield_count': 1,
        })

  def test_no_parity_call_unless_asked(self):
    calls = []
    with contextlib.redirect_stderr(io.StringIO()):
      self._collect(self._list_handler(calls))
    self.assertFalse([c for c in calls if 'search-all-resources' in c])
    self.assertEqual(inventory.SPLIT_PARITY_FINDINGS, [])

  def test_parity_probe_is_clean_when_the_table_is_current(self):
    calls = []
    with contextlib.redirect_stderr(io.StringIO()):
      self._collect(self._list_handler(calls), verify_search_parity=True)
    probes = [c for c in calls if 'search-all-resources' in c]
    self.assertEqual(len(probes), 1, calls)
    # Bounded cost: the probe asks only for declared SPLIT types.
    self.assertIn('--asset-types=compute.googleapis.com/Address', probes[0])
    self.assertEqual(len(inventory.SPLIT_PARITY_FINDINGS), 1)
    self.assertEqual(inventory.SPLIT_PARITY_FINDINGS[0]['only_in_search'], [])

  def test_parity_probe_fails_loud_on_a_stale_table(self):
    """The regression the whole table is exposed to: CAI adds a split
    this frozen snapshot does not know about."""
    unknown = ('//compute.googleapis.com/projects/my-prj/'
               'global/addresses/some-future-split')

    def handler(cmd, **kwargs):
      joined = ' '.join(cmd)
      resolved = self._resolve_project(joined)
      if resolved is not None:
        return resolved
      if 'search-all-resources' in joined:
        return [{
            'name': self._addr(self._REGIONAL, '')['name']
        }, {
            'name': unknown
        }]
      if '--content-type=resource' in joined and 'Address' in joined:
        return [self._addr(self._REGIONAL, 'compute.googleapis.com/Address')]
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      with self.assertRaises(SystemExit) as ctx:
        self._collect(handler, verify_search_parity=True)
    self.assertEqual(ctx.exception.code, 3)
    err = buf.getvalue()
    self.assertIn('search', err)
    self.assertIn(unknown, err)
    self.assertIn('CAI_SPLIT_TYPES', err)

  def test_retired_sibling_type_is_reported_not_fatal(self):
    """A sibling is tool-supplied, not operator-declared. CAI retiring a
    split type is the convergence the table is waiting for, so it must
    not fail the operator's run — but a stale frozen table is still a
    fact about the denominator."""
    err_text = ('command failed: gcloud --quiet asset list\n'
                'ERROR: (gcloud.asset.list) INVALID_ARGUMENT: No '
                'supported asset type matches: '
                'compute.googleapis.com/GlobalAddress.')

    def handler(cmd, **kwargs):
      joined = ' '.join(cmd)
      resolved = self._resolve_project(joined)
      if resolved is not None:
        return resolved
      if kwargs.get('ignore_errors'):
        return []
      if 'GlobalAddress' in joined:
        raise SystemExit(err_text)
      if '--content-type=resource' in joined and 'Address' in joined:
        return [self._addr(self._REGIONAL, 'compute.googleapis.com/Address')]
      return []

    buf = io.StringIO()
    with contextlib.redirect_stderr(buf):
      entries, _, _ = self._collect(handler)
    self.assertEqual(len(entries), 1)
    self.assertEqual(inventory.UNSUPPORTED_CAI_TYPES, [])
    self.assertTrue(
        any('CAI_SPLIT_TYPES may be stale' in m
            for m in inventory.SUPPRESSED_SWEEPS), inventory.SUPPRESSED_SWEEPS)

  def test_table_pairs_are_distinct_and_well_formed(self):
    for unified, siblings in inventory.CAI_SPLIT_TYPES.items():
      self.assertIsInstance(siblings, tuple, unified)
      self.assertTrue(siblings, unified)
      for s in siblings:
        self.assertNotEqual(s, unified)
        self.assertNotIn(s, inventory.CAI_SPLIT_TYPES,
                         f'{s} is both a unified type and a sibling')


if __name__ == '__main__':
  unittest.main()
