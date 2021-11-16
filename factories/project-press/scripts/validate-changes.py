#!/usr/bin/env python3
# Copyright 2021 Google LLC
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

import yaml
import argparse
import sys
import re
from deepdiff import DeepDiff

parser = argparse.ArgumentParser(
    description='Validate field changes in YAML files')
parser.add_argument('original', type=str, help='Original project file')
parser.add_argument('new', type=str, help='New project file')
parser.add_argument('--schema',
                    type=str,
                    nargs=1,
                    default=['../projectSchemaHoldApproval.yaml'],
                    help='Schema file')
args = parser.parse_args()


def iterate_schema(schema, out, parent):
    for k, v in schema.items():
        if isinstance(v, dict):
            _parent = ('%s.' % parent) if parent != '' else parent
            iterate_schema(v, out, '%s%s' % (_parent, k))
        else:
            out['%s.%s' % (parent, k)] = v


hold_for_approval = False
with open(args.schema[0]) as schema_file:
    schema = yaml.load(schema_file, Loader=yaml.SafeLoader)
    schema_out = {}
    iterate_schema(schema, schema_out, '')

    with open(args.original) as old_file:
        old = yaml.load(old_file, Loader=yaml.SafeLoader)

        with open(args.new) as new_file:
            new = yaml.load(new_file, Loader=yaml.SafeLoader)

            ddiff = DeepDiff(old, new, ignore_order=True)
            all_changed = {'values_changed': {}}
            if 'values_changed' in ddiff:
                all_changed['values_changed'] = {
                    **all_changed['values_changed'],
                    **ddiff['values_changed']
                }
            if 'iterable_item_added' in ddiff:
                all_changed['values_changed'] = {
                    **all_changed['values_changed'],
                    **ddiff['iterable_item_added']
                }
            if 'iterable_item_removed' in ddiff:
                all_changed['values_changed'] = {
                    **all_changed['values_changed'],
                    **ddiff['iterable_item_removed']
                }
            if len(all_changed['values_changed'].keys()) > 0:
                for changed, value in all_changed['values_changed'].items():
                    changed = changed.replace('root[\'', '').replace(
                        '\'][\'', '.').replace('\']', '')
                    changed = re.sub(r'\[\d+\]$', '', changed)
                    if changed in schema_out:
                        if schema_out[changed]:
                            hold_for_approval = True
                            if 'old_value' in value:
                                print(
                                    'Field %s was changed (%s -> %s), holding for manual approval.'
                                    % (changed, value['old_value'],
                                       value['new_value']),
                                    file=sys.stderr)
                            else:
                                print(
                                    'Field %s was changed (%s), holding for manual approval.'
                                    % (changed, value),
                                    file=sys.stderr)

                        else:
                            print(
                                'Field %s was changed, but it was automatically approved.'
                                % changed,
                                file=sys.stderr)
                    else:
                        print(
                            'Unknown field %s was changed (not in change schema), ignored.'
                            % changed,
                            file=sys.stderr)

            else:
                print('No fields were changed.', file=sys.stderr)

if hold_for_approval:
    print('Result: Holding change for manual approval.', file=sys.stderr)
    sys.exit(1)
sys.exit(0)
