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
import yamale
import json
import sys
import argparse
import re
import glob
from validators import get_validators

parser = argparse.ArgumentParser(
    description='Validate a project YAML configuration file.')
parser.add_argument('file', type=str, help='file to validate')
parser.add_argument('--schema',
                    type=str,
                    default='../projectSchema.yaml',
                    help='schema file')
parser.add_argument('--schema-help',
                    type=str,
                    default='../projectSchemaHelp.yaml',
                    help='schema help file')
parser.add_argument('--mode',
                    type=str,
                    default='validate',
                    help='select mode (validate or approve)')
parser.add_argument('--json',
                    action='store_true',
                    default=False,
                    help='output errors in JSON mode')

args = parser.parse_args()

schema_help = {}
with open(args.schema_help) as f:
    schema_help = yaml.load(f, Loader=yaml.SafeLoader)

schema_help_key = 'help' if args.mode == 'validate' else 'approvalHelp'

files = [args.file]
if '*' in args.file:
    files = glob.glob(args.file)

validators = get_validators()
schema = yamale.make_schema(args.schema, validators=validators)
errors_found = False
errors_json = {}
for file in files:
    print('Validating %s...' % (file), file=sys.stderr)
    data = yamale.make_data(file)
    try:
        yamale.validate(schema, data)
    except yamale.yamale_error.YamaleError as e:
        project_file = open(file, "r")
        project_contents = project_file.readlines()

        errors_found = True
        print('Error validating data in \'%s\'\n' % file, file=sys.stderr)
        for result in e.results:
            for error in result.errors:
                end_field = error.find(':')
                field_name = error[0:end_field]
                field_name = re.sub(r'\.\d+', '', field_name)

                # Find line number for field (very simplistic version)
                line_number = 1
                search_field_name = '%s:' % (field_name.replace('project.', ''))
                for num, line in enumerate(project_contents):
                    if search_field_name in line:
                        line_number = num + 1
                        break
                if file not in errors_json:
                    errors_json[file] = {}
                if line_number not in errors_json[file]:
                    errors_json[file][line_number] = '%s\n' % (error)
                else:
                    errors_json[file][line_number] = '%s\n%s' % (
                        errors_json[file][line_number], error)

                print('  %s' % error, file=sys.stderr)
                if field_name in schema_help[schema_help_key]:
                    print('', file=sys.stderr)
                    for line in schema_help[schema_help_key][field_name].split(
                            "\n"):
                        print('    %s' % line, file=sys.stderr)
                        errors_json[file][line_number] = '%s\n    %s' % (
                            errors_json[file][line_number], line)

if errors_found:
    if args.json:
        github_json = []
        for file, errors in errors_json.items():
            for line, error in errors.items():
                github_json.append({
                    'path': file,
                    'line': line,
                    'body': '```\n%s\n```' % (error)
                })
        print(json.dumps(github_json))
    sys.exit(1)
if args.json:
    print('{}')
sys.exit(0)
