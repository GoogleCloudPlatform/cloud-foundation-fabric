#!/usr/bin/env python3
# Copyright 2023 Google LLC
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
'Parse and output IAM bindings from Terraform state file.'

import collections
import json
import itertools
import re
import sys

import click

FIELDS = ('authoritative', 'resource_type', 'resource_id', 'role',
          'member_type', 'member_id', 'conditions')
ORG_IDS = {}
RESOURCE_SORT = {'organization': 0, 'folder': 1, 'project': 2}
RESOURCE_TYPE_RE = re.compile(r'^google_([^_]+)_iam_([^_]+)$')
Binding = collections.namedtuple('Binding', ' '.join(FIELDS))


def _org_id(resource_id):
  if resource_id not in ORG_IDS:
    ORG_IDS[resource_id] = f'[org_id #{len(ORG_IDS)}]'
  return ORG_IDS[resource_id]


def get_bindings(resources, prefix=None, folders=None):
  'Parse resources and return bindings.'
  org_ids = {}
  for r in resources:
    m = RESOURCE_TYPE_RE.match(r['type'])
    if not m:
      continue
    resource_type = m.group(1)
    authoritative = m.group(2) == 'binding'
    for i in r.get('instances'):
      attrs = i['attributes']
      conditions = ' '.join(c['title'] for c in attrs.get('condition', []))
      if resource_type == 'organization':
        resource_id = _org_id(attrs['org_id'])
      else:
        resource_id = attrs[resource_type]
        if prefix and resource_id.startswith(prefix):
          resource_id = resource_id[len(prefix) + 1:]
      role = attrs['role']
      if role.startswith('organizations/'):
        org_id = role.split('/')[1]
        role = role.replace(org_id, _org_id(org_id))
      members = attrs['members'] if authoritative else [attrs['member']]
      if resource_type == 'folder' and folders:
        resource_id = folders.get(resource_id, resource_id)
      for member in members:
        member_type, _, member_id = member.partition(':')
        if member_type == 'user':
          continue
        try:
          member_id, member_domain = member_id.split('@', 1)
        except ValueError:
          if member_type == 'domain':
            member_id = 'GCP organization domain'
          member_domain = ''
          # raise SystemExit(f'Cannot parse binding {member_id}')
        # Handle Cloud Services Service Account
        if member_domain == 'cloudservices.gserviceaccount.com':
          member_id = "PROJECT_CLOUD_SERVICES"
        # Handle Cloud Service Identity Service Account
        if re.match("^service-\d{8}", member_id):
          member_id = "SERVICE_IDENTITY_" + member_domain.split(".", 1)[0]
        # Handle BQ Cloud Service Identity Service Account
        if re.match("^bq-\d{8}", member_id):
          member_id = "IDENTITY_" + member_domain.split(".", 1)[0]
          resource_type_output = "Service Identity - " + resource_type
        else:
          resource_type_output = resource_type
        if prefix and member_id.startswith(prefix):
          member_id = member_id[len(prefix) + 1:]
        yield Binding(authoritative, resource_type_output, resource_id, role,
                      member_type, member_id, conditions)


def get_folders(resources):
  'Parse resources and return folder id, name tuples.'
  folders = {}
  for r in resources:
    if r['type'] != 'google_folder':
      continue
    for i in r['instances']:
      folder_id = i['attributes']['id']
      folder_name = i['attributes']['display_name']
      if folder_name not in folders:
        folders[folder_name] = []
      folders[folder_name].append(folder_id)
  for name, ids in folders.items():
    for i, folder_id in enumerate(ids):
      if len(ids) == 1:
        yield folder_id, name
      else:
        yield folder_id, f'{name} [#{i}]'


def output_csv(bindings):
  'Output bindings in CSV format.'
  print(','.join(FIELDS))
  for b in bindings:
    print(','.join(str(getattr(b, f)) for f in FIELDS))


def output_principals(bindings):
  'Output bindings in Markdown format by principals.'
  resource_grouper = itertools.groupby(
      bindings, key=lambda b: (b.resource_type, b.resource_id))
  print('# IAM bindings reference')
  print('\nLegend: <code>+</code> additive, <code>•</code> conditional.')
  for resource, resource_groups in resource_grouper:
    resource_type, resource_name = resource
    print(f'\n## {resource_type.title()} <i>{resource_name.lower()}</i>\n')
    principal_grouper = itertools.groupby(
        resource_groups, key=lambda b: (b.member_type, b.member_id))
    print('| members | roles |')
    print('|---|---|')
    for principal, principal_groups in principal_grouper:
      roles = []
      for b in principal_groups:
        additive = '<code>+</code>' if not b.authoritative else ''
        conditions = '<code>•</code>' if b.conditions else ''
        if b.role.startswith('organizations/'):
          roles.append(f'{b.role} {additive}{conditions}')
        else:
          url = ('https://cloud.google.com/iam/docs/understanding-roles#'
                 f'{b.role.replace("roles/", "")}')
          roles.append(f'[{b.role}]({url}) {additive}{conditions}')
      print(f'|<b>{principal[1]}</b><br><small><i>{principal[0]}</i></small>|'
            f'{"<br>".join(roles)}|')


@click.command()
@click.argument('state-file', type=click.File('r'), default=sys.stdin)
@click.option('--format', type=click.Choice(['csv', 'principals', 'raw']),
              default='raw')
@click.option('--prefix', default=None)
def main(state_file, format, prefix=None):
  'Output IAM bindings parsed from Terraform state file or standard input.'
  with state_file:
    data = json.load(state_file)
  resources = data.get('resources', [])
  folders = dict(get_folders(resources))
  bindings = get_bindings(resources, prefix=prefix, folders=folders)
  bindings = sorted(
      bindings, key=lambda b: (
          RESOURCE_SORT.get(b.resource_type, 99),
          b.resource_id,
          b.member_type,
          b.member_id,
      ))
  if format == 'raw':
    for b in bindings:
      print(b)
  else:
    func = globals().get(f'output_{format}')
    if not func:
      raise SystemExit('Unknown format.')
    func(bindings)


if __name__ == '__main__':
  main()
