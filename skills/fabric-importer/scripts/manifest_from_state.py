#!/usr/bin/env python3
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Infers an import-manifest.yaml from existing Terraform .tfstate files.

Extracts managed resource types, hierarchy levels, and project scopes directly
from terraform state resources, mapping google_* provider types to Cloud Asset
Inventory types and multi-scope rules.
"""

import argparse
from collections import defaultdict
import json
import os
import re
import sys
from typing import Dict, List, Set, Tuple

import integrity

LEVEL_ORDER = {
    'organization': 0,
    'folder': 1,
    'project': 2,
    'unknown': 3,
}

# CAI resource names arrive as `//<service>/<collection>/<id>`; the
# service prefix has to come off before a hierarchy prefix can be read.
_CAI_PREFIX_RE = re.compile(r'^//[^/]+/')


def _hierarchy_level(value):
  """Level implied by a parent/name string, or None if it implies none.

  Accepts the two prefixed shapes that occur in Terraform state:
  `folders/123` and `//cloudresourcemanager.googleapis.com/projects/123`.

  A BARE NUMERIC id carries no level on its own and returns None here;
  only the caller knows what an unprefixed number means for a given
  resource (`google_project.folder_id` is a parent folder, while
  `google_folder.folder_id` is the folder's own id). Missing the bare
  form entirely was the headline bug: it silently classified every
  folder-nested project as organization-level, dropping it from the
  denominator with a green gate.
  """
  if value is None:
    return None
  text = str(value).strip()
  if not text:
    return None
  text = _CAI_PREFIX_RE.sub('', text)
  for prefix, level in (('organizations/', 'organization'),
                        ('folders/', 'folder'), ('projects/', 'project')):
    if text.startswith(prefix):
      return level
  return None

# Mapping from Terraform google_* resource types to (CAI type, level_rule, flags)
# level_rule can be:
# - 'organization', 'folder', 'project': static single level
# - 'dynamic': level inferred from resource attributes (e.g. parent/org_id/folder)
TF_TYPE_MAP = {
    # IAM
    'google_organization_iam_binding': ('iam', 'organization', {}),
    'google_organization_iam_member': ('iam', 'organization', {}),
    'google_folder_iam_binding': ('iam', 'folder', {}),
    'google_folder_iam_member': ('iam', 'folder', {}),
    'google_project_iam_binding': ('iam', 'project', {}),
    'google_project_iam_member': ('iam', 'project', {}),
    'google_service_account_iam_binding':
        ('iam.googleapis.com/ServiceAccount', 'project', {
            'iam': True
        }),
    'google_service_account_iam_member':
        ('iam.googleapis.com/ServiceAccount', 'project', {
            'iam': True
        }),
    # Leaf-asset IAM is never an asset type of its own: it is the
    # `iam-policy` content type on an asset CAI already models, and it
    # enters the denominator through the parent type's `iam: true`
    # opt-in. Mapping the binding to the PARENT type is what sets that
    # flag — the alternative is 4 bindings the manifest cannot see.
    'google_storage_bucket_iam_binding':
        ('storage.googleapis.com/Bucket', 'project', {
            'iam': True
        }),
    'google_storage_bucket_iam_member':
        ('storage.googleapis.com/Bucket', 'project', {
            'iam': True
        }),
    'google_tags_tag_value_iam_binding':
        ('cloudresourcemanager.googleapis.com/TagValue', 'organization', {
            'iam': True
        }),
    'google_tags_tag_value_iam_member':
        ('cloudresourcemanager.googleapis.com/TagValue', 'organization', {
            'iam': True
        }),

    # Essential contacts. CAI models these; the parent may be an org, a
    # folder or a project, so the level is read rather than assumed.
    'google_essential_contacts_contact':
        ('essentialcontacts.googleapis.com/Contact', 'dynamic', {}),

    # Custom roles
    'google_organization_iam_custom_role':
        ('iam.googleapis.com/Role', 'organization', {}),
    'google_project_iam_custom_role':
        ('iam.googleapis.com/Role', 'project', {}),

    # Org policies
    'google_org_policy_policy': ('org-policy', 'dynamic', {}),
    'google_org_policy_custom_constraint': ('org-policy', 'organization', {}),
    'google_organization_policy': ('org-policy', 'organization', {}),
    'google_folder_organization_policy': ('org-policy', 'folder', {}),
    'google_project_organization_policy': ('org-policy', 'project', {}),

    # Logging
    'google_logging_organization_sink':
        ('logging.googleapis.com/LogSink', 'organization', {}),
    'google_logging_folder_sink':
        ('logging.googleapis.com/LogSink', 'folder', {}),
    'google_logging_project_sink':
        ('logging.googleapis.com/LogSink', 'project', {}),
    'google_logging_project_bucket_config':
        ('logging.googleapis.com/LogBucket', 'project', {}),
    # Logs Router settings. CAI models the settings singleton as
    # `logging.googleapis.com/Settings` for every container level; the
    # `.../OrganizationSettings` spelling this map used to emit exists
    # nowhere in the CAI catalogue, so enumeration failed the whole run
    # (the same class of bug as the ACM `identity.` prefix above, one
    # step worse: it fails loudly instead of matching nothing).
    'google_logging_organization_settings':
        ('logging.googleapis.com/Settings', 'organization', {}),
    'google_logging_folder_settings':
        ('logging.googleapis.com/Settings', 'folder', {}),
    # Log exclusions are NOT a CAI asset type at all. They stay out of
    # this map deliberately: a manifest entry for them needs an
    # `enumerate:` block (see references/cai-blind-spots.md), which is a
    # human decision, not something inferred from state.

    # Resource Manager
    'google_folder':
        ('cloudresourcemanager.googleapis.com/Folder', 'organization', {}),
    'google_project':
        ('cloudresourcemanager.googleapis.com/Project', 'organization', {}),
    # Tag keys are GA at project scope too and carry a `parent`, so the
    # level has to be read rather than assumed.
    'google_tags_tag_key':
        ('cloudresourcemanager.googleapis.com/TagKey', 'dynamic', {}),
    'google_tags_tag_value':
        ('cloudresourcemanager.googleapis.com/TagValue', 'organization', {}),
    'google_tags_tag_binding':
        ('cloudresourcemanager.googleapis.com/TagBinding', 'dynamic', {}),

    # Core Infrastructure
    'google_storage_bucket': ('storage.googleapis.com/Bucket', 'project', {}),
    'google_service_account':
        ('iam.googleapis.com/ServiceAccount', 'project', {}),
    'google_project_service':
        ('serviceusage.googleapis.com/Service', 'project', {}),

    # VPC-SC. The CAI type carries an `identity.` prefix for these three
    # (see cloud.google.com/asset-inventory/docs/supported-asset-types);
    # the bare `accesscontextmanager.googleapis.com/...` spelling matches
    # NOTHING, which yields an empty sweep and a vacuously green gate.
    'google_access_context_manager_access_policy':
        ('identity.accesscontextmanager.googleapis.com/AccessPolicy',
         'organization', {}),
    'google_access_context_manager_service_perimeter':
        ('identity.accesscontextmanager.googleapis.com/ServicePerimeter',
         'organization', {}),
    'google_access_context_manager_access_level':
        ('identity.accesscontextmanager.googleapis.com/AccessLevel',
         'organization', {}),

    # Networking
    'google_compute_network': ('compute.googleapis.com/Network', 'project', {}),
    'google_compute_subnetwork':
        ('compute.googleapis.com/Subnetwork', 'project', {}),
    'google_compute_router': ('compute.googleapis.com/Router', 'project', {}),
    'google_compute_router_nat':
        ('compute.googleapis.com/Router', 'project', {}),
    'google_compute_firewall':
        ('compute.googleapis.com/Firewall', 'project', {}),
    'google_compute_network_firewall_policy':
        ('compute.googleapis.com/NetworkFirewallPolicy', 'project', {}),
    'google_compute_ha_vpn_gateway':
        ('compute.googleapis.com/HaVpnGateway', 'project', {}),
    'google_dns_managed_zone':
        ('dns.googleapis.com/ManagedZone', 'project', {}),

    # KMS & Security
    'google_kms_key_ring': ('cloudkms.googleapis.com/KeyRing', 'project', {}),
    'google_kms_crypto_key':
        ('cloudkms.googleapis.com/CryptoKey', 'project', {}),
    'google_secret_manager_secret':
        ('secretmanager.googleapis.com/Secret', 'project', {}),

    # WIF
    'google_iam_workload_identity_pool':
        ('iam.googleapis.com/WorkloadIdentityPool', 'project', {}),
    'google_iam_workload_identity_pool_provider':
        ('iam.googleapis.com/WorkloadIdentityPoolProvider', 'project', {}),

    # Analytics & Pub/Sub
    'google_bigquery_dataset':
        ('bigquery.googleapis.com/Dataset', 'project', {}),
    'google_pubsub_topic': ('pubsub.googleapis.com/Topic', 'project', {}),
    'google_pubsub_subscription':
        ('pubsub.googleapis.com/Subscription', 'project', {}),
}


def parse_state_files(state_paths: List[str]):
  """Parses resource blocks from state files and extracts scopes and types."""
  org_ids = set()
  projects = set()
  project_numbers = {}
  folders = set()
  types_found = defaultdict(lambda: {'levels': set(), 'flags': {}})
  errors = []
  unclassified = set()
  unmapped = defaultdict(int)

  for sp in state_paths:
    try:
      with open(sp, 'r', encoding='utf-8') as f:
        data = json.load(f)
    except Exception as e:
      msg = f'failed to read {sp}: {e}'
      print(f'ERROR: {msg}', file=sys.stderr)
      errors.append(msg)
      continue

    resources = data.get('resources', [])
    for r in resources:
      if r.get('mode') != 'managed':
        continue
      rtype = r.get('type')
      # Only Google resources describe the Google hierarchy. `organization`
      # is a required attribute on tfe_workspace, and github_*/azuread_*
      # carry one too, so harvesting every provider let a Terraform Cloud
      # org name land in org_ids -- which now trips the multi-org refusal
      # on a state that has exactly one Google organization.
      if not str(rtype).startswith('google_'):
        continue
      instances = r.get('instances', [])

      for inst in instances:
        attrs = inst.get('attributes', {})

        # Check for organization ID. `parent` counts too: a folder at
        # the top of the hierarchy records its org there and nowhere
        # else, and missing it dropped the manifest to a folder root.
        org_id = attrs.get('org_id') or attrs.get('organization')
        if not org_id:
          parent = str(attrs.get('parent') or '')
          parent = _CAI_PREFIX_RE.sub('', parent)
          if parent.startswith('organizations/'):
            org_id = parent
        if org_id:
          org_id = str(org_id).removeprefix('organizations/').strip()
          # Organization ids are numeric. Anything else is a name from
          # some other namespace and must not become a scope root.
          if org_id.isdigit():
            org_ids.add(org_id)
          else:
            unclassified.add(f'{rtype} (non-numeric organization {org_id!r})')

        # Check for project
        pid = attrs.get('project') or attrs.get('project_id')
        if pid:
          pid_str = str(pid).removeprefix('projects/')
          projects.add(pid_str)
        # The number BINDS the include entry, so take it only from the
        # resource that authoritatively owns it. `number` on any other
        # resource is a different object's id, and a wrong number matches
        # no CAI ancestor -- emptying that project from the denominator
        # with exit 0.
        if rtype == 'google_project':
          pnum = attrs.get('number') or attrs.get('project_number')
          if pid and pnum:
            pid_str = str(pid).removeprefix('projects/')
            existing = project_numbers.get(pid_str)
            if existing and existing != str(pnum):
              raise SystemExit(
                  f'ERROR: conflicting project numbers for {pid_str}: '
                  f'{existing} and {pnum}. Refusing to guess which one '
                  'binds the scope.')
            project_numbers[pid_str] = str(pnum)

        # Check for folder
        fid = attrs.get('folder') or attrs.get('folder_id')
        if fid:
          folders.add(str(fid).removeprefix('folders/'))
        if rtype == 'google_folder':
          fname = attrs.get('name')
          if fname:
            folders.add(str(fname).removeprefix('folders/'))

        # Map to CAI types
        if rtype not in TF_TYPE_MAP and str(rtype).startswith('google_'):
          unmapped[rtype] += 1
        if rtype in TF_TYPE_MAP:
          cai_type, level_rule, flags = TF_TYPE_MAP[rtype]

          if level_rule == 'dynamic':
            lvl = (_hierarchy_level(attrs.get('parent')) or
                   _hierarchy_level(attrs.get('name')))
            if not lvl:
              if attrs.get('org_id'):
                lvl = 'organization'
              elif attrs.get('folder_id'):
                lvl = 'folder'
              elif attrs.get('project_id') or attrs.get('project'):
                lvl = 'project'
            # Fail visible, not convenient: defaulting an unclassifiable
            # parent to `organization` invented a level and dropped the
            # asset from every other sweep. `unknown` is a first-class
            # level in inventory.py and is always retained.
            if not lvl:
              lvl = 'unknown'
              unclassified.add(f'{rtype} (parent={attrs.get("parent")!r})')
            types_found[cai_type]['levels'].add(lvl)
          else:
            types_found[cai_type]['levels'].add(level_rule)

          # Containers carry their own parent, so a folder or project may
          # sit at either level regardless of the static rule above.
          if rtype in ('google_folder', 'google_project'):
            lvl = _hierarchy_level(attrs.get('parent'))
            # `folder_id` is the PARENT on google_project and the folder's
            # OWN id on google_folder, so it may only be read here for a
            # project.
            if not lvl and rtype == 'google_project':
              fid = str(attrs.get('folder_id') or '').strip()
              lvl = _hierarchy_level(fid) or ('folder' if fid.isdigit() else
                                              None)
            if not lvl and attrs.get('org_id'):
              lvl = 'organization'
            if lvl:
              types_found[cai_type]['levels'].add(lvl)

          for k, v in flags.items():
            types_found[cai_type]['flags'][k] = v

  if errors:
    raise SystemExit(
        f"ERROR: {len(errors)} state file(s) failed to parse: {', '.join(errors)}"
    )

  if unclassified:
    print(
        f'WARNING: {len(unclassified)} resource instance kind(s) had a '
        'parent this tool could not classify; they are declared at level '
        '`unknown` and retained. Confirm the level by hand:',
        file=sys.stderr)
    for u in sorted(unclassified):
      print(f'  - {u}', file=sys.stderr)

  if unmapped:
    # A google_* type absent from TF_TYPE_MAP is managed Terraform that
    # this manifest will NOT enumerate: the denominator ends up smaller
    # than the footprint the state already proves exists, and gate 1
    # still goes green. Say so loudly rather than skipping in silence.
    total = sum(unmapped.values())
    print(
        f'WARNING: {len(unmapped)} google_* resource type(s) ({total} '
        'instance(s)) are not in TF_TYPE_MAP and are ABSENT from the '
        'generated manifest. The denominator will not cover them:',
        file=sys.stderr)
    for t in sorted(unmapped):
      print(f'  - {t} ({unmapped[t]} instance(s))', file=sys.stderr)
    # The distinction this paragraph draws is not pedantry: read as "CAI
    # does not support these", the list sends an operator straight to
    # waivers for types CAI has covered all along.
    print(
        '  This means only that THIS TOOL has no static Terraform-to-CAI\n'
        '  row for them. It says nothing about whether Cloud Asset\n'
        '  Inventory supports them. Triage each one:\n'
        '    (a) CAI has an asset type for it -> add `- type: <cai-type>`\n'
        '        to the manifest by hand (check the supported-types list:\n'
        '        https://cloud.google.com/asset-inventory/docs/'
        'supported-asset-types);\n'
        '    (b) it is IAM on an asset CAI models (google_*_iam_binding /\n'
        '        _member / _policy) -> add `iam: true` to THAT asset\'s\n'
        '        type entry; leaf IAM is never a type of its own;\n'
        '    (c) CAI genuinely does not model it -> declare an\n'
        '        `enumerate:` block, or enumerate out of band and record\n'
        '        it in the run report (references/cai-blind-spots.md);\n'
        '    (d) deliberately out of scope -> signed waiver.\n'
        '  Anything mapped here should also be sent back as a TF_TYPE_MAP\n'
        '  entry, so the next engagement starts one step ahead.',
        file=sys.stderr)

  return org_ids, projects, project_numbers, folders, types_found


def _project_include_lines(projects, project_numbers):
  """`include:` entries, always prefixed and never duplicated.

  CAI `ancestors` are project NUMBERS. Emitting the id and leaving the
  number in a comment made every match depend on a live `gcloud projects
  describe` call whose failure is silent; when the number is known from
  state, bind to it directly. Everything is emitted `projects/`-prefixed
  because a bare number is ambiguous and inventory.py now refuses it.
  """
  known_numbers = set(project_numbers.values())
  lines = []
  for p in sorted(projects):
    if p in project_numbers:
      lines.append(f'      - projects/{project_numbers[p]}   # {p}')
    elif p in known_numbers:
      continue  # already emitted above via its project id
    else:
      lines.append(f'      - projects/{p}')
  return lines


def _project_rooted_manifest(projects, project_numbers, types_found,
                             state_files):
  """Manifest for a state that manages resources inside projects only."""
  lines = [
      '# Import manifest inferred from Terraform state file(s)',
      '# Generated by manifest_from_state.py',
      '# No organization or folder appears in this state, so the scope is',
      '# rooted at the projects it manages.',
      f'# Source state(s): '
      f'{", ".join(integrity.display_path(p) for p in state_files)}',
      '',
      'scopes:',
  ]
  has_unknown = any('unknown' in v['levels'] for v in types_found.values())
  levels = ['project'] + (['unknown'] if has_unknown else [])
  for i, entry in enumerate(_project_include_lines(projects,
                                                   project_numbers)):
    root = entry.strip().lstrip('- ').split()[0]
    lines += [
        f'  - name: project-{i + 1}',
        f'    root: {root}',
        f'    levels: [{", ".join(levels)}]',
        '',
    ]
  return '\n'.join(lines + _type_lines(types_found)) + '\n'


def _type_lines(types_found):
  """The `types:` block, shared by every manifest shape."""
  lines = ['types:']
  pseudo_order = ['iam', 'org-policy']
  ordered_types = [pt for pt in pseudo_order if pt in types_found]
  ordered_types += [t for t in sorted(types_found) if t not in pseudo_order]
  for t in ordered_types:
    levels = sorted(types_found[t]['levels'],
                    key=lambda lvl: LEVEL_ORDER.get(lvl, 99))
    lines.append(f'  - type: {t}')
    lines.append(f'    levels: [{", ".join(levels)}]')
    for fk, fv in sorted(types_found[t]['flags'].items()):
      lines.append(f'    {fk}: {str(fv).lower()}')
  return lines


def generate_manifest(org_ids, projects, project_numbers, folders, types_found,
                      state_files):
  """Generates YAML string for the import manifest."""
  # Guessing the root is the one error this tool must not make: every
  # scope, and therefore the whole denominator, hangs off it.
  if len(org_ids) > 1:
    raise SystemExit(
        'ERROR: state spans more than one organization '
        f'({", ".join(sorted(org_ids))}). Picking one silently would '
        'drop every asset under the others from the denominator. Split '
        'the state files per organization and generate one manifest each.')
  if org_ids:
    scope_root = f'organizations/{sorted(org_ids)[0]}'
    root_is_org = True
  elif len(folders) == 1:
    scope_root = f'folders/{sorted(folders)[0]}'
    root_is_org = False
  elif folders:
    # Same argument as the multi-org refusal: picking a lexicographic
    # minimum from sibling folders drops everything under the others,
    # with exit 0 and a green gate.
    raise SystemExit(
        'ERROR: state spans more than one folder '
        f'({", ".join("folders/" + f for f in sorted(folders))}) and no '
        'organization was discovered, so there is no unambiguous scope '
        'root. Declare the intended root by hand, or pass a state file '
        'that includes the common ancestor.')
  elif projects:
    # A per-project state is the most common Mode A input and is exactly
    # what inventory.py project roots exist for; refusing it would be a
    # regression dressed as strictness.
    return _project_rooted_manifest(projects, project_numbers, types_found,
                                    state_files)
  else:
    raise SystemExit(
        'ERROR: no organization, folder or project could be discovered '
        'in the given state file(s), so there is no scope root to anchor '
        'the manifest. Emitting a placeholder root would produce a '
        'manifest that looks valid and enumerates nothing. Pass a state '
        'file that contains the hierarchy, or write the manifest by hand.')

  lines = [
      '# Import manifest inferred from Terraform state file(s)',
      '# Generated by manifest_from_state.py',
      f'# Source state(s): '
      f'{", ".join(integrity.display_path(p) for p in state_files)}',
      '',
      'scopes:',
  ]

  has_org_level = any('organization' in v['levels'] or 'folder' in v['levels']
                      for v in types_found.values())
  # `unknown` must appear in the SCOPE levels too, or every type declared
  # only at `unknown` intersects to the empty set and is swept-then-
  # discarded (pseudo-types are skipped outright). Retaining an
  # unclassifiable asset is the whole point of the level.
  has_unknown = any('unknown' in v['levels'] for v in types_found.values())
  if has_org_level or has_unknown:
    # A folder root cannot carry organization-level assets; declaring it
    # anyway asks inventory.py for a sweep that cannot match.
    levels = ['organization', 'folder'] if root_is_org else ['folder']
    if has_unknown:
      levels.append('unknown')
    lines += [
        '  - name: org-foundation',
        f'    root: {scope_root}',
        f'    levels: [{", ".join(levels)}]',
        '',
    ]
    if not root_is_org:
      org_only = sorted(t for t, v in types_found.items()
                        if v['levels'] == {'organization'})
      if org_only:
        print(
            'WARNING: the scope root is a folder, so these declared '
            'organization-level type(s) can never be enumerated and will '
            'yield nothing:', file=sys.stderr)
        for t in org_only:
          print(f'  - {t}', file=sys.stderr)

  include = _project_include_lines(projects, project_numbers)
  if include:
    levels = ['project']
    if has_unknown:
      levels.append('unknown')
    lines += [
        '  - name: stage-projects',
        f'    root: {scope_root}',
        f'    levels: [{", ".join(levels)}]',
        '    include:',
    ] + include + ['']

  return '\n'.join(lines + _type_lines(types_found)) + '\n'


def main():
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('--state', nargs='+', required=True,
                 help='Path(s) to Terraform .tfstate file(s)')
  p.add_argument('--out', default='import-manifest.yaml',
                 help='Output manifest file path (use "-" for stdout)')
  p.add_argument(
      '--force', action='store_true',
      help='overwrite an existing --out file; refused by default '
      'because the manifest is human-owned and gate-relevant')
  args = p.parse_args()

  if args.out != '-' and os.path.exists(args.out) and not args.force:
    raise SystemExit(
        f'ERROR: {integrity.display_path(args.out)} already exists. It is '
        'the human-owned scope '
        'declaration the whole denominator derives from, and its SHA256 '
        'is recorded in inventory.json. Re-run with --force to replace '
        'it deliberately, or pass --out - to review on stdout first.')

  org_ids, projects, project_numbers, folders, types_found = parse_state_files(
      args.state)

  manifest_yaml = generate_manifest(org_ids, projects, project_numbers, folders,
                                    types_found, args.state)

  if args.out == '-':
    sys.stdout.write(manifest_yaml)
  else:
    with open(args.out, 'w', encoding='utf-8') as f:
      f.write(manifest_yaml)
    print(f'Wrote inferred import manifest to {args.out}')


if __name__ == '__main__':
  main()
