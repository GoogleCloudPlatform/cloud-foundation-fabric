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
    if col1.find('ul'):
      # skip agents with more than one identity
      continue
    identity = col1.p.get_text()
    if 'PROJECT_NUMBER' not in identity:
      #
      continue

    identity = identity.replace('PROJECT_NUMBER', '%s')
    name = identity.split('@')[1].split('.')[0]
    name = name.removeprefix('gcp-sa-')
    #name = name.removesuffix('.iam.gserviceaccount.com')

    agent = {
        'name': name,
        'identity': identity,
        'api': col1.span.code.get_text(),
        # 'display_name': col1.h4.get_text(),
        'is_primary': 'Primary service agent' in agent_text,
        'role': col2.code.get_text() if 'roles/' in agent_text else None
    }

    agent['identity'] = identity
    agents.append(agent)

  print(yaml.safe_dump(agents, sort_keys=False))


if __name__ == '__main__':
  main()
main()
