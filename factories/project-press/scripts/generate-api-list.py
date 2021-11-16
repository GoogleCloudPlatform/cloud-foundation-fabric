#!/usr/bin/env python3
"""A tool for generating a list for projectApprovedApis.yaml file.
Requirements in 'requirements.txt'.
"""
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

import google.auth
import googleapiclient.errors as errors
from googleapiclient.discovery import build
from google.oauth2 import service_account
import argparse
import pprint
import os
import yaml
import time

API_SERVICE_NAME = 'servicemanagement'
API_VERSION = 'v1'
URI = 'https://%s.googleapis.com/$discovery/rest?' % (API_SERVICE_NAME)
pp = pprint.PrettyPrinter(indent=2)

parser = argparse.ArgumentParser(
    description='projectApprovedApis.yaml generation tool.')
# Check validity of command line flags
parser.add_argument(
    '--previous-file',
    help='Previous projectApprovedApis.yaml path if updating list of APIs.')
args = parser.parse_args()
credentials, project = google.auth.default()

previous_approved = []
previous_hold_for_approval = []
if args.previous_file:
    with open(args.previous_file, 'r') as stream:
        approvedApis = yaml.safe_load(stream)
        if isinstance(approvedApis['approved'], list):  # Old format
            for api in approvedApis['approved']:
                previous_approved.append(api)
            for api in approvedApis['holdForApproval']:
                previous_hold_for_approval.append(api)
        else:
            for api, _v in approvedApis['approved'].items():
                previous_approved.append(api)
            for api, _v in approvedApis['holdForApproval'].items():
                previous_hold_for_approval.append(api)

all_apis = {}
apis = {'approved': {}, 'holdForApproval': {}}
servicemanagement = build(API_SERVICE_NAME,
                          API_VERSION,
                          discoveryServiceUrl=URI)
request = servicemanagement.services().list()
response = request.execute()
while request:
    if 'services' in response:
        for service in response['services']:
            service_request = servicemanagement.services().getConfig(
                serviceName=service['serviceName'], view='FULL')
            service_response = service_request.execute()
            if 'name' in service_response:
                all_apis[service_response['name']] = {
                    'title':
                        service_response['title'],
                    'description':
                        service_response['documentation']['summary']
                        if 'documentation' in service_response and
                        'summary' in service_response['documentation'] else ''
                }
                time.sleep(
                    0.6
                )  # Sleep for 600ms - default quota is 120 req/minute, so this should keep us under it

    request = servicemanagement.services().list_next(request, response)
    if request:
        response = request.execute()

if len(previous_approved) == 0:
    for k, v in all_apis.items():
        apis['approved'][k] = v
else:
    for api in previous_approved:
        if api in all_apis:
            apis['approved'][api] = all_apis[api]
    for api in previous_hold_for_approval:
        if api in all_apis:
            apis['holdForApproval'][api] = all_apis[api]

print(yaml.dump(apis))