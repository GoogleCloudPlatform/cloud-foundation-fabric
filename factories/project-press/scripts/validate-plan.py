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
import json
import tempfile
import sys
import os

parser = argparse.ArgumentParser(
    description='Validate a Terraform plan file against deletions.')
parser.add_argument('file', type=str, help='file to validate')
args = parser.parse_args()

ALLOWED_PROVIDERS_TO_DELETE = ['registry.terraform.io/hashicorp/null']
ALLOWED_RESOURCES_TO_DELETE = [
    'google_cloud_scheduler_job', 'google_project_organization_policy'
]

with open(args.file, 'rb') as f:
    c = f.read(2)
    if c == b'PK':  # Compressed TF plan file, courtesy of Phil Katz
        temp = tempfile.mkstemp(suffix='.json')
        os.system('terraform show -json %s > %s' % (args.file, temp[1]))
        args.file = temp[1]

with open(args.file) as f:
    plan = json.load(f)
    if 'resource_changes' in plan:
        for change in plan['resource_changes']:
            if 'delete' in change['change']['actions']:
                if change['provider_name'] in ALLOWED_PROVIDERS_TO_DELETE:
                    print(
                        '(Terraform plan file has a deletion operation, but it\'s on the approved list of providers, ignoring...)',
                        file=sys.stderr)
                elif change['type'] in ALLOWED_RESOURCES_TO_DELETE:
                    print(
                        '(Terraform plan file has a deletion operation, but it\'s on the approved list of resources, ignoring...)',
                        file=sys.stderr)
                else:
                    print('Terraform plan file has deletion operations.',
                          file=sys.stderr)
                    sys.exit(1)
print('Terraform plan file has only creates and in-place updates.',
      file=sys.stderr)
sys.exit(0)
