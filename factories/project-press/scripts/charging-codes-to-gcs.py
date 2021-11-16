#!/usr/bin/env python3
#
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
import json
import yaml
from google.cloud import storage
from google.api_core.gapic_v1 import client_info as grpc_client_info

parser = argparse.ArgumentParser(
    description='Export project charging codes to GCS')
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

if 'chargingCodesDestinationBucket' not in config:
    sys.exit(0)

print('Reading projects...', file=sys.stderr)
charging_codes = []
for project_file in glob.glob('%s*.yaml' % project_dir):
    with open(project_file, 'rt') as f:
        _project = yaml.load(f, Loader=yaml.SafeLoader)
        project = _project['project']
        if project['chargingCode'] not in charging_codes:
            charging_codes.append(project['chargingCode'])

client_info = grpc_client_info.ClientInfo(
    user_agent='google-pso-tool/turbo-project-factory/1.0.0')
storage_client = storage.Client(client_info=client_info)
print('Writing charging codes to GCS (%s/%s)...' %
      (config['chargingCodesDestinationBucket'],
       config['chargingCodesDestinationObject']),
      file=sys.stderr)
bucket = storage_client.bucket(config['chargingCodesDestinationBucket'])
blob = bucket.blob(config['chargingCodesDestinationObject'])
blob.upload_from_string(json.dumps(charging_codes))
print('All done.', file=sys.stderr)
