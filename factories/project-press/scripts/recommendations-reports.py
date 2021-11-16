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
import glob
import json
import os

parser = argparse.ArgumentParser(
    description=
    'Outputs Recommendations reports Cloud Scheduler configurations for Terraform'
)
parser.add_argument('--projects', type=str, help='Project files')
parser.add_argument('--config',
                    type=str,
                    default='config.yaml',
                    help='Project factory configuration')
parser.add_argument('--recommendations-config',
                    type=str,
                    default='recommendationsReports.yaml',
                    help='Recommendations reports configuration')
parser.add_argument('--stdin',
                    action='store_true',
                    help='Read project information from stdin')

args = parser.parse_args()

config = {}
recommendations_config = {}
with open(args.config) as config_file:
    config = yaml.load(config_file, Loader=yaml.SafeLoader)

if not os.path.exists(args.recommendations_config):
    print('No recommendations configuration found (%s), exiting.' %
          (args.recommendations_config),
          file=sys.stderr)
    if args.stdin:
        print('{"output":"{}"}')
        sys.exit(0)
    sys.exit(1)

with open(args.recommendations_config) as config_file:
    recommendations_config = yaml.load(config_file, Loader=yaml.SafeLoader)


def format_email(config, email):
    if config['domain'] == '':
        return email
    return '%s@%s' % (email, config['domain'])


output = {}
for report in recommendations_config['reports']:
    report['projects'] = []
    output[report['reportId']] = report
project_cfgs = {}
if not args.stdin:
    for project in glob.glob(args.projects):
        with open(project) as project_file:
            project_cfg = yaml.load(project_file, Loader=yaml.SafeLoader)
            if not 'project' in project_cfg:
                print('Invalid project file %s!' % (project), file=sys.stderr)
                continue
            project_cfgs[project_cfg['project']
                         ['projectId']] = project_cfg['project']
else:
    stdin_input = json.load(sys.stdin)
    if not 'projects' in stdin_input:
        print('Invalid input from Terraform!', file=sys.stderr)
        sys.exit(1)
    project_cfgs = json.loads(stdin_input['projects'])

for project_id, project_cfg in project_cfgs.items():
    if 'recommendationsReports' in project_cfg:
        for report_id in project_cfg['recommendationsReports']:
            if report_id not in output:
                print(
                    'Warning! Project %s specifies an unknown report recommendations report ID "%s".'
                    % (project_id, report_id),
                    file=sys.stderr)
            else:
                for env in project_cfg['environments']:
                    project_id = config['projectIdFormat'].replace(
                        '%id%', project_cfg['projectId']).replace('%env%', env)
                    output[report_id]['projects'].append(project_id)
            if 'recommendationsReportsIncludeOwners' in project_cfg:
                if 'owners' in project_cfg:
                    for owner in project_cfg['owners']:
                        output[report_id]['recipients'].append(
                            format_email(config, owner))
                if 'owner' in project_cfg:
                    output[report_id]['recipients'].append(
                        format_email(config, project_cfg['owner']))
final_output = output
for id, report in output.items():
    final_output[id]['pubsub_message'] = {
        'recipients': report['recipients'],
        'send': report['send'],
        'projects': report['projects']
    }
    if 'settings' in report:
        final_output[id]['pubsub_message'] = {
            **final_output[id]['pubsub_message'],
            **report['settings']
        }
    final_output[id]['pubsub_message_str'] = json.dumps(
        final_output[id]['pubsub_message'])

if args.stdin:
    output_str = json.dumps(final_output)
    print(json.dumps({'output': output_str}))
else:
    print(json.dumps(final_output))
