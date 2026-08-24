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
"""Unit tests for the frozen v2 tools (coverage, verify_plan, inventory,
manifest_init).

Run with: python3 -m pytest skills/fabric-importer/tests -q
      or: python3 skills/fabric-importer/tests/test_scripts.py
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
    scoped = _BENIGN_RULES + [{
        'resource': 'google_anything',
        'attributes': ['settings'],
        'reason': 'computed refresh'
    }]
    v, _ = verify_plan.classify(rc, scoped)
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

  def test_when_before_guard(self):
    # D-03 rule: only empty-string live descriptions are benign.
    rules = [{
        'resource': 'google_logging_organization_sink',
        'attributes': ['description'],
        'when_before': {
            'description': ''
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
    # Container assets list themselves first (DISCOVERY.md issue 1):
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
    # DISCOVERY.md issue 1: TagValue IAM must not pollute org-level IAM.
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

  def test_sweep_failures_fail_closed(self):
    # Tolerated enumeration failures must hard-fail collect() at the
    # end - a silently shrunken denominator is never acceptable.
    inventory.SWEEP_FAILURES.append('simulated: gcloud org-policies list')
    try:
      with self.assertRaises(SystemExit) as ctx:
        inventory.collect({'scope': {'root': 'organizations/1'}, 'types': []})
      self.assertEqual(ctx.exception.code, 3)
    finally:
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
    # Round 3 / W-14: dry-run-only policies exist only in the service
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
    # DISCOVERY.md issue 2: Policy resource assets merge into the same
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
      self.assertEqual(code, 0)
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
    """Regression (round 20 slip 8): an absolute path embeds home
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
      # And specifically none of the shapes that leaked before:
      for danger in ('/usr/local/google/home/', '/Users/', '/home/'):
        self.assertNotIn(danger, line,
                         f'input_stamp leaked absolute-path prefix {danger!r}')
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

  def test_check_mode_detects_edit(self):
    with tempfile.TemporaryDirectory() as t:
      c = {n: f'# {n}\n' for n in integrity.FROZEN_FILES}
      for name, body in c.items():
        with open(os.path.join(t, name), 'w') as f:
          f.write(body)
      with open(os.path.join(t, integrity.DIGEST_FILE), 'w') as f:
        f.write(integrity.frozen_digest(t) + '\n')
      ok, _ = integrity.check(t)
      self.assertTrue(ok)
      with open(os.path.join(t, 'benign-drift.yaml'), 'a') as f:
        f.write('  - resource: sneaky\n')
      ok, msg = integrity.check(t)
      self.assertFalse(ok)
      self.assertIn('FROZEN TOOLS MODIFIED', msg)

  def test_check_mode_fails_closed_on_missing_digest_file(self):
    with tempfile.TemporaryDirectory() as t:
      ok, msg = integrity.check(t)
      self.assertFalse(ok)
      self.assertIn('missing', msg)


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

      manifest_text = manifest_from_state.generate_manifest(
          org_ids, projects, pnums, folders, types_found, [sp])
      parsed = yaml.safe_load(manifest_text)
      self.assertEqual(len(parsed['scopes']), 2)
      self.assertEqual(parsed['scopes'][0]['name'], 'org-foundation')
      self.assertEqual(parsed['scopes'][0]['root'],
                       'organizations/123456789012')
      self.assertEqual(parsed['scopes'][1]['name'], 'stage-projects')
      self.assertEqual(parsed['scopes'][1]['include'], ['my-net-prj'])
      self.assertIn('# project number: 987654321', manifest_text)
    finally:
      os.remove(sp)

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


if __name__ == '__main__':
  unittest.main()
