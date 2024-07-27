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

from dataclasses import asdict, dataclass
from itertools import chain

import requests
import yaml
from bs4 import BeautifulSoup

# BASEDIR = pathlib.Path(__file__).resolve().parents[1]
SERVICE_AGENTS_URL = "https://cloud.google.com/iam/docs/service-agents"

# old names used by Fabric
ALIASES = {
    'bigquery-encryption': ['bq'],
    'cloudservices': ['cloudsvc'],
    'compute-system': ['compute'],
    'cloudcomposer-accounts': ['composer'],
    'container-engine-robot': ['container', 'container-engine'],
    'dataflow-service-producer-prod': ['dataflow'],
    'dataproc-accounts': ['dataproc'],
    'gae-api-prod': ['gae-flex'],
    'gcf-admin-robot': ['cloudfunctions', 'gcf'],
    'gkehub': ['fleet'],
    'gs-project-accounts': ['storage'],
    'monitoring-notification': ['monitoring'],
    'serverless-robot-prod': ['cloudrun', 'run'],
}

PRIMARY_OVERRIDE = {
    'storage-transfer-service': True,
}


@dataclass
class Agent:
  name: str
  display_name: str
  api: str
  identity: str
  role: str
  is_primary: bool
  aliases: list[str]


def main():
  page = requests.get(SERVICE_AGENTS_URL).content
  soup = BeautifulSoup(page, 'html.parser')
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
      # most service agents have the format
      # service-PROJECT_NUMBER@gcp-sa-SERVICE_NAME.iam.gserviceaccount.com.
      # We keep the SERVICE_NAME part as the agent's name
      name = identity.split('@')[1].split('.')[0]
      name = name.removeprefix('gcp-sa-')
    identity = identity.replace('PROJECT_NUMBER', '%s')

    if name == 'monitoring':
      # monitoring is deprecated in favor of monitoring-notification.
      # Switch names to preserve old Fabric convention
      name = 'monitoring-deprecated'

    is_primary = 'Primary service agent' in agent_text
    agent = Agent(
        name=name,
        display_name=col1.h4.get_text(),
        api=col1.span.code.get_text() if name != 'cloudservices' else None,
        identity=identity,
        role=col2.code.get_text() if 'roles/' in agent_text else None,
        is_primary=PRIMARY_OVERRIDE.get(name, is_primary),
        aliases=ALIASES.get(name, []),
    )

    if agent.name == 'cloudservices':
      # cloudservices role is granted automatically, we don't want to manage it
      agent.role = None

    agents.append(agent)

  # make sure all names and aliases are different:
  names = set(agent.name for agent in agents)
  assert len(names) == len(agents)
  aliases = set(chain.from_iterable(agent.aliases for agent in agents))
  assert aliases.isdisjoint(names)

  # take the header from the first lines of this file
  header = open(__file__).readlines()[2:15]
  print("".join(header))
  # and print all the agents
  print(yaml.safe_dump([asdict(a) for a in agents], sort_keys=False))


if __name__ == '__main__':
  main()
