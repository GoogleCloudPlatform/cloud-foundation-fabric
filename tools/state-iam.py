#!/usr/bin/env python3
# Copyright 2022 Google LLC
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


FIELDS = (
    'authoritative', 'resource_type', 'resource_id', 'role', 'member_type',
    'member_id', 'conditions'
)
RESOURCE_SORT = {'organization': 0, 'folder': 1, 'project': 2}
RESOURCE_TYPE_RE = re.compile(r'^google_([^_]+)_iam_([^_]+)$')
Binding = collections.namedtuple('Binding', ' '.join(FIELDS))


def get_bindings(resources, prefix=None, folders=None):
  'Parse resources and return bindings.'
  for r in resources:
    m = RESOURCE_TYPE_RE.match(r['type'])
    if not m:
      continue
    resource_type = m.group(1)
    authoritative = m.group(2) == 'binding'
    for i in r.get('instances'):
      attrs = i['attributes']
      conditions = ' '.join(c['title'] for c in attrs.get('condition', []))
      resource_id = attrs[resource_type if resource_type !=
                          'organization' else 'org_id']
      members = attrs['members'] if authoritative else [attrs['member']]
      if resource_type == 'folder' and folders:
        resource_id = folders.get(resource_id, resource_id)
      for member in members:
        member_type, _, member_id = member.partition(':')
        member_id = member_id.rpartition('@')[0]
        if prefix:
          member_id = member_id.lstrip(f'{prefix}-')
        yield Binding(authoritative, resource_type, resource_id, attrs['role'],
                      member_type, member_id, conditions)


def get_folders(resources):
  'Parse resources and return folder id, name tuples.'
  for r in resources:
    if r['type'] != 'google_folder':
      continue
    for i in r['instances']:
      yield i['attributes']['id'], i['attributes']['display_name']


@click.command()
@click.argument('state-file', type=click.File('r'), default=sys.stdin)
@click.option('--output', type=click.Choice(['csv', 'raw']), default='raw')
@click.option('--prefix', default=None)
def main(state_file, output, prefix=None):
  'Output IAM bindings parsed from Terraform state file or standard input.'
  with state_file:
    data = json.load(state_file)
  resources = data.get('resources', [])
  folders = dict(get_folders(resources))
  bindings = get_bindings(resources, prefix=prefix, folders=folders)
  bindings = sorted(bindings, key=lambda b: (
      RESOURCE_SORT.get(b.resource_type, 99), b.resource_id,
      b.authoritative * -1, b.member_type, b.member_id))
  if output == 'raw':
    for b in bindings:
      print(b)
  elif output == 'csv':
    print(','.join(FIELDS))
    for b in bindings:
      print(','.join(str(getattr(b, f)) for f in FIELDS))
  else:
    raise SystemExit('Unknown format.')


if __name__ == '__main__':
  main()
