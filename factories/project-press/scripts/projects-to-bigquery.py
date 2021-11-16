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

import argparse
import sys
import glob
import yaml
from google.cloud import bigquery
from google.api_core.gapic_v1 import client_info as grpc_client_info

parser = argparse.ArgumentParser(
    description='Export project information to BigQuery')
parser.add_argument('--config',
                    type=str,
                    help='Location of Project Factory config.yaml')
parser.add_argument('projects',
                    type=str,
                    help='Location of directory with all project YAML files')

args = parser.parse_args()

project_dir = args.projects if args.projects.endswith(
    '/') else '%s/' % args.projects

config = {}
with open(args.config, 'rt') as f:
    config = yaml.load(f, Loader=yaml.SafeLoader)

if 'bigqueryDestination' not in config:
    print(
        'No BigQuery dataset and table configured for project information export, skipping...'
    )
    sys.exit(0)

domain_append = ''
if config['domain'] != '':
    domain_append = '@%s' % config['domain']

reportingChainPrefix = config[
    'reportingChainPrefix'] if 'reportingChainPrefix' in config else []

print('Reading projects...', file=sys.stderr)
rows = []
for project_file in glob.glob('%s*.yaml' % project_dir):
    with open(project_file, 'rt') as f:
        _project = yaml.load(f, Loader=yaml.SafeLoader)
        project = _project['project']

        for env in project['environments']:
            row = {
                'projectId':
                    project['projectId'],
                'fullProjectId':
                    config['projectIdFormat'].replace(
                        '%id%',
                        project['projectId']).replace('%env%', env).replace(
                            '%folder%', project['folder']),
                'displayName':
                    project['displayName'],
                'folder':
                    project['folder'],
                'owners': ['%s%s' % (project['owner'], domain_append)],
                'reportingChain':
                    reportingChainPrefix +
                    ['%s%s' % (project['owner'], domain_append)],
                'team': [],
                'chargingCode':
                    project['chargingCode'],
                'budget':
                    None,
                'environment':
                    env,
                'status':
                    project['status']
            }
            for group, members in project['team'].items():
                _members = []
                for member in members:
                    _members.append('%s%s' % (member, domain_append))
                row['team'].append({'group': group, 'members': _members})
            if 'budget' in project:
                row['budget'] = project['budget'][env]
            elif 'defaultBudget' in config:
                row['budget'] = config['defaultBudget'][env]
            rows.append(row)

job_config = bigquery.LoadJobConfig(
    schema=[
        bigquery.SchemaField("projectId",
                             "STRING",
                             mode="REQUIRED",
                             description="Project ID"),
        bigquery.SchemaField("fullProjectId",
                             "STRING",
                             mode="REQUIRED",
                             description="Full project ID"),
        bigquery.SchemaField("displayName",
                             "STRING",
                             mode="NULLABLE",
                             description="Human readable name"),
        bigquery.SchemaField("folder",
                             "STRING",
                             mode="REQUIRED",
                             description="Folder where project resides in"),
        bigquery.SchemaField("owners",
                             "STRING",
                             mode="REPEATED",
                             description="Project owners"),
        bigquery.SchemaField("reportingChain",
                             "STRING",
                             mode="REPEATED",
                             description="Project owner reporting chain"),
        bigquery.SchemaField("team",
                             "STRUCT",
                             mode="REPEATED",
                             description="Project team",
                             fields=(
                                 bigquery.SchemaField('group',
                                                      'STRING',
                                                      description='Group name'),
                                 bigquery.SchemaField(
                                     'members',
                                     'STRING',
                                     mode='REPEATED',
                                     description='Group members'),
                             )),
        bigquery.SchemaField("chargingCode",
                             "STRING",
                             mode="REQUIRED",
                             description="Chargeback code"),
        bigquery.SchemaField("budget",
                             "INT64",
                             mode="NULLABLE",
                             description="Project budget"),
        bigquery.SchemaField("environment",
                             "STRING",
                             mode="REQUIRED",
                             description="Environment"),
        bigquery.SchemaField("status",
                             "STRING",
                             mode="REQUIRED",
                             description="Project status"),
    ],
    write_disposition=bigquery.job.WriteDisposition.WRITE_TRUNCATE)

client_info = grpc_client_info.ClientInfo(
    user_agent='google-pso-tool/turbo-project-factory/1.0.0')
client = bigquery.Client(client_info=client_info)
print('Writing projects to Bigquery (%s)...' % config['bigqueryDestination'],
      file=sys.stderr)
client.load_table_from_json(rows,
                            bigquery.table.Table(config['bigqueryDestination']),
                            job_config=job_config)
print('All done.', file=sys.stderr)
