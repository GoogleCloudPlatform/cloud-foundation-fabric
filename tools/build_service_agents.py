#!/usr/bin/env python3

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import collections
import pathlib
import requests
import yaml

import click
from bs4 import BeautifulSoup

# BASEDIR = pathlib.Path(__file__).resolve().parents[1]
SERVICE_AGENTS_URL = "https://cloud.google.com/iam/docs/service-agents"


def main():
  page = requests.get(SERVICE_AGENTS_URL)
  soup = BeautifulSoup(page.content, 'html.parser')
  agents = []
  for content in soup.find(id='service-agents').select('tbody tr'):
    agent_text = content.get_text()
    col1, col2 = content.find_all('td')

    # skip agents with more than one identity
    if col1.find('ul'):
      continue

    identity = col1.p.get_text()
    # skip agents that are not contained in a project
    if 'PROJECT_NUMBER' not in identity:
      continue

    # special case for Cloud Build that has two service agents:
    # - %s@cloudbuild.gserviceaccount.com
    # - service-%s@gcp-sa-cloudbuild.iam.gserviceaccount.com
    if identity == 'PROJECT_NUMBER@cloudbuild.gserviceaccount.com':
      name = "cloudbuild-sa"  # Cloud Build Service Account
    else:
      name = identity.split('@')[1].split('.')[0]
      name = name.removeprefix('gcp-sa-')
    identity = identity.replace('PROJECT_NUMBER', '%s')
    agent = {
        'name': name,
        'display_name': col1.h4.get_text(),
        'api': col1.span.code.get_text(),
        'identity': identity,
        'role': col2.code.get_text() if 'roles/' in agent_text else None,
        'is_primary': 'Primary service agent' in agent_text,
    }

    # agent['identity'] = identity
    agents.append(agent)

  # take the header from the first lines of this file
  header = open(__file__).readlines()[2:15]
  print("".join(header))
  print(yaml.safe_dump(agents, sort_keys=False))


if __name__ == '__main__':
  main()
