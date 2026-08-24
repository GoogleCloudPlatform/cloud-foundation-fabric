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
import sys
from typing import Dict, List, Set, Tuple

LEVEL_ORDER = {
    'organization': 0,
    'folder': 1,
    'project': 2,
}

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
    'google_logging_organization_settings':
        ('logging.googleapis.com/OrganizationSettings', 'organization', {}),

    # Resource Manager
    'google_folder':
        ('cloudresourcemanager.googleapis.com/Folder', 'organization', {}),
    'google_project':
        ('cloudresourcemanager.googleapis.com/Project', 'organization', {}),
    'google_tags_tag_key':
        ('cloudresourcemanager.googleapis.com/TagKey', 'organization', {}),
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

    # VPC-SC
    'google_access_context_manager_access_policy':
        ('accesscontextmanager.googleapis.com/AccessPolicy', 'organization', {}
        ),
    'google_access_context_manager_service_perimeter':
        ('accesscontextmanager.googleapis.com/ServicePerimeter', 'organization',
         {}),
    'google_access_context_manager_access_level':
        ('accesscontextmanager.googleapis.com/AccessLevel', 'organization', {}),

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
      instances = r.get('instances', [])

      for inst in instances:
        attrs = inst.get('attributes', {})

        # Check for organization ID
        org_id = attrs.get('org_id') or attrs.get('organization')
        if org_id:
          org_ids.add(str(org_id).removeprefix('organizations/'))

        # Check for project
        pid = attrs.get('project') or attrs.get('project_id')
        if pid:
          pid_str = str(pid).removeprefix('projects/')
          projects.add(pid_str)
        pnum = attrs.get('number') or attrs.get('project_number')
        if pid and pnum:
          pid_str = str(pid).removeprefix('projects/')
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
        if rtype in TF_TYPE_MAP:
          cai_type, level_rule, flags = TF_TYPE_MAP[rtype]

          if level_rule == 'dynamic':
            # Inspect parent or name
            parent = attrs.get('parent') or attrs.get('name', '')
            if parent.startswith('organizations/') or attrs.get('org_id'):
              lvl = 'organization'
            elif parent.startswith('folders/') or attrs.get('folder_id'):
              lvl = 'folder'
            elif parent.startswith('projects/') or attrs.get(
                'project_id') or attrs.get('project'):
              lvl = 'project'
            else:
              lvl = 'organization'
            types_found[cai_type]['levels'].add(lvl)
          else:
            types_found[cai_type]['levels'].add(level_rule)

          if rtype == 'google_folder':
            parent = attrs.get('parent', '')
            if parent.startswith('folders/'):
              types_found[cai_type]['levels'].add('folder')
            elif parent.startswith('organizations/'):
              types_found[cai_type]['levels'].add('organization')

          if rtype == 'google_project':
            parent = attrs.get('parent', '') or attrs.get('folder_id', '')
            if parent.startswith('folders/'):
              types_found[cai_type]['levels'].add('folder')
            else:
              types_found[cai_type]['levels'].add('organization')

          for k, v in flags.items():
            types_found[cai_type]['flags'][k] = v

  if errors:
    raise SystemExit(
        f"ERROR: {len(errors)} state file(s) failed to parse: {', '.join(errors)}"
    )

  return org_ids, projects, project_numbers, folders, types_found


def generate_manifest(org_ids, projects, project_numbers, folders, types_found,
                      state_files):
  """Generates YAML string for the import manifest."""
  if org_ids:
    scope_root = f'organizations/{sorted(org_ids)[0]}'
  elif folders:
    scope_root = f'folders/{sorted(folders)[0]}'
  else:
    scope_root = 'organizations/000000000000'

  lines = [
      '# Import manifest inferred from Terraform state file(s)',
      '# Generated by manifest_from_state.py',
      f'# Source state(s): {", ".join(state_files)}',
      '',
      'scopes:',
  ]

  has_org_level = any('organization' in v['levels'] or 'folder' in v['levels']
                      for v in types_found.values())
  if has_org_level:
    lines += [
        '  - name: org-foundation',
        f'    root: {scope_root}',
        '    levels: [organization, folder]',
        '',
    ]

  if projects:
    lines += [
        '  - name: stage-projects',
        f'    root: {scope_root}',
        '    levels: [project]',
        '    include:',
    ]
    for p in sorted(projects):
      pnum_comment = (f'   # project number: {project_numbers[p]}'
                      if p in project_numbers else '')
      lines.append(f'      - {p}{pnum_comment}')
    lines.append('')

  lines.append('types:')

  pseudo_order = ['iam', 'org-policy']
  ordered_types = []
  for pt in pseudo_order:
    if pt in types_found:
      ordered_types.append(pt)
  for t in sorted(types_found.keys()):
    if t not in pseudo_order:
      ordered_types.append(t)

  for t in ordered_types:
    levels = sorted(types_found[t]['levels'],
                    key=lambda lvl: LEVEL_ORDER.get(lvl, 99))
    flags = types_found[t]['flags']
    lines.append(f'  - type: {t}')
    lines.append(f'    levels: [{", ".join(levels)}]')
    for fk, fv in sorted(flags.items()):
      lines.append(f'    {fk}: {str(fv).lower()}')

  return '\n'.join(lines) + '\n'


def main():
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('--state', nargs='+', required=True,
                 help='Path(s) to Terraform .tfstate file(s)')
  p.add_argument('--out', default='import-manifest.yaml',
                 help='Output manifest file path (use "-" for stdout)')
  args = p.parse_args()

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
