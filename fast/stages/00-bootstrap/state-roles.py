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
import sys

import click


RESOURCE_ATTR = {'organization': 'org_id',
                 'folder': 'folder', 'project': 'project'}

Binding = collections.namedtuple(
    'Binding', 'resource_type resource role members authoritative conditions')


# TODO(ludomagno): strip domain part from principals
# TODO(ludomagno): parse folder resources and use names in bindings if available
# TODO(ludomagno): optionally output one record per role/principal to allow pivots

def get_additive_bindings(resources, node='organization'):
  'Parse additive bindings for node type.'
  bindings = {}
  resource_type = f'google_{node}_iam_member'
  for resource in resources:
    if resource['type'] != resource_type:
      continue
    name = resource['name']
    for i in resource.get('instances'):
      attrs = i['attributes']
      conditions = tuple(c['title'] for c in attrs.get('condition', []))
      resource = attrs[RESOURCE_ATTR[node]]
      binding = bindings.setdefault((resource, attrs['role'], conditions), [])
      binding.append(attrs['member'])
  for k, v in bindings.items():
    yield Binding(node, k[0], k[1], v, False, k[2])


def get_authoritative_bindings(resources, node='organization'):
  'Parse authoritative bindings for node type.'
  resource_type = f'google_{node}_iam_binding'
  for resource in resources:
    if resource['type'] != resource_type:
      continue
    name = resource['name']
    for i in resource.get('instances'):
      attrs = i['attributes']
      conditions = tuple(c['title'] for c in attrs.get('condition', []))
      resource = attrs[RESOURCE_ATTR[node]]
      yield Binding(node, resource, attrs['role'], attrs['members'], True,
                    conditions)


def output_csv(bindings):
  'Output bindings in CSV format.'
  row = '{authoritative},{type},{id},{role},"{members}",{conditions}'
  print('authoritative,resource_type,resource_id,role,members,conditions')
  for b in bindings:
    print(row.format(
        authoritative=b.authoritative, type=b.resource_type, id=b.resource,
        role=b.role, members='\n'.join(b.members), conditions=' '.join(b.conditions)
    ))


@click.command()
@click.argument('state-file', type=click.File('r'), default=sys.stdin)
@click.option('--output', type=click.Choice(['csv', 'raw']), default='raw')
def main(state_file, output):
  'Outputs IAM bindings parsed from Terraform state file or standard input.'
  with state_file:
    data = json.load(state_file)
  resources = data.get('resources', [])
  bindings = itertools.chain.from_iterable(
      func(resources, node) for node, func in
      itertools.product(
          ('organization', 'folder', 'project'),
          (get_authoritative_bindings, get_additive_bindings)
      )
  )
  if output == 'raw':
    for binding in bindings:
      print(binding)
  elif output == 'csv':
    output_csv(bindings)
  else:
    raise SystemExit('invalid output specification')


if __name__ == '__main__':
  main()
