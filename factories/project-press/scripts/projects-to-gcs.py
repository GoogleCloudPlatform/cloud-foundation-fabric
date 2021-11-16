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
import json
from google.cloud import storage
from google.api_core.gapic_v1 import client_info as grpc_client_info

parser = argparse.ArgumentParser(
    description='Export project information to GCS')
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

if 'projectInformationGcsBucket' not in config or 'projectInformationGcsObject' not in config:
    print('No GCS bucket or object configured for project export, skipping...')
    sys.exit(0)

print('Reading projects...', file=sys.stderr)
projects = {}
for project_file in glob.glob('%s*.yaml' % project_dir):
    with open(project_file, 'rt') as f:
        _project = yaml.load(f, Loader=yaml.SafeLoader)
        projects[_project['project']['projectId']] = _project

client_info = grpc_client_info.ClientInfo(
    user_agent='google-pso-tool/turbo-project-factory/1.0.0')
storage_client = storage.Client(client_info=client_info)
print('Writing projects to GCS (%s/%s)...' %
      (config['projectInformationGcsBucket'],
       config['projectInformationGcsObject']),
      file=sys.stderr)
bucket = storage_client.bucket(config['projectInformationGcsBucket'])
blob = bucket.blob(config['projectInformationGcsObject'])
blob.upload_from_string(json.dumps(projects))
print('All done.', file=sys.stderr)
