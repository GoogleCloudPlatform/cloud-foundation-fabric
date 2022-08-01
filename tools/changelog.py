#!/usr/bin/env python3
# Copyright 2022 Google LLC
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

import click
import collections
import re

import ghapi.all
import iso8601

MARK_BEGIN = '<!-- BEGIN CHANGELOG -->'
MARK_END = '<!-- END CHANGELOG -->'
ORG = 'GoogleCloudPlatform'
REPO = 'cloud-foundation-fabric'

PullRequest = collections.namedtuple('PullRequest', 'id author title merged_at')
Release = collections.namedtuple('Release', 'tag merged_at')


def format_pull(pr):
  url = f'https://github.com/{ORG}/{REPO}/pull/'
  return f'- [[#{pr.id}]({url}{pr.id})] {pr.title} ({pr.author})'


def get_api(token, owner=ORG, name=REPO):
  return ghapi.all.GhApi(owner=owner, repo=name, token=token)


def get_pulls(token, api=None):
  api = api or get_api(token)
  release = api.repos.get_latest_release()
  release_published_at = iso8601.parse_date(release.published_at)

  while True:
    page = 1
    for item in api.pulls.list(base='master', state='closed', sort='updated',
                               direction='desc', page=page, per_page=100):
      try:
        merged_at = iso8601.parse_date(item['merged_at'])
      except iso8601.ParseError:
        continue
      pr = PullRequest(item['number'], item['user']['login'], item['title'],
                       merged_at)
      if pr.merged_at <= release_published_at:
        page = None
        break
      yield pr
    if page is None:
      break
    page += 1


def write_doc(path, snippet):
  'Replace changelog file.'
  try:
    doc = open(path).read()
  except (IOError, OSError) as e:
    raise SystemExit(f'Error opening {path}: {e.args[0]}')
  m = re.search('(?sm)%s\n(.*)\n%s' % (MARK_BEGIN, MARK_END), doc)
  if not m:
    raise SystemExit('Mark not found.')
  start, end = m.start(), m.end()
  try:
    open(path, 'w').write('\n'.join([
        doc[:start].rstrip(),
        f'\n{MARK_BEGIN}',
        snippet,
        f'{MARK_END}\n',
        doc[end:].lstrip(),
    ]))
  except (IOError, OSError) as e:
    raise SystemExit(f'Error replacing {path}: {e.args[0]}')


@click.command
@click.option('--token', required=True, envvar='GH_TOKEN')
@click.argument('changelog', required=False, type=click.Path(exists=True))
def main(token, changelog=None):
  buffer = []
  for pr in get_pulls(token=token):
    buffer.append(format_pull(pr))
  buffer = '\n'.join(buffer)
  if not changelog:
    print(buffer)
  else:
    write_doc(changelog, buffer)


if __name__ == '__main__':
  main()