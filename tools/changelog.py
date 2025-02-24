#!/usr/bin/env python3
# Copyright 2025 Google LLC
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
'''Changelog maintenance.

This script allows adding or replacing individual release sections in our
CHANGELOG.md file.

It works on a set of simple principles

- a release is identified by two boundaries, the release for which we want to
  capture PRs (`release_to` or end release) and the release preceding it
  (`release_from` or start release)
- the end release can be null, to capture unreleased merged PRs (the
  'Unreleased' block in changelog)
- the start release can be null, to start capturing from the last published
  release (again to populate the 'Unreleased' block)
- merged PRs between the start and end times are captured and used to populate
  the release block
- PRs are grouped by their `on:` labels, and flagged as containing incompatible
  changes if they have one of the `breaks:` labels
- draft PRs or PRs merged against a base different from the one specified via
  the `merged_to` argument (defaulting to `master`) are ignored
- the unreleased block can optionally be marked with a release name via the
  `release_as` argument to prepare for a new release

Example usage:

- update the Unreleased section after PRs have been merged, both start and end
  releases use defaults, only PRs to `master` are tracked
  ```
  ./tools/changelog.py  --token=$TOKEN --write
  ```
- update an existing release on the master branch
  ```
  ./tools/changelog.py  --token=$TOKEN --write \
    --release-from=v34.0.0 --release-to=v35.0.0
  ```
- create a new release on the master branch
  ```
  ./tools/changelog.py  --token=$TOKEN --write \
    --release-from=v35.0.0 --release-as=v36.0.0
  ```
- create an rc release on the fast-dev branch capturing only branch-merged PRs
  ```
  ./tools/changelog.py  --token=$TOKEN --write \
    --release-from=v35.0.0 --release-as=v36.0.0-rc1 --merged-to=fast-dev
  ```
- create an rc release on the fast-dev branch also capturing master merged PRs
  e.g. when releasing an rc2 with fast-dev aligned on master
  ```
  ./tools/changelog.py  --token=$TOKEN --write \
    --release-from=v35.0.0 --release-as=v36.0.0-rc1 \
    --merged-to=fast-dev --merged-to=master
  ```
'''

import click
import collections
import datetime
import functools
import logging
import requests

import iso8601
import marko

HEADING = (
    '# Changelog\n\n'
    'All notable changes to this project will be documented in this file.\n'
    '<!-- markdownlint-disable MD024 -->\n')
LINK_MARKER = '<!-- markdown-link-check-disable -->'
ORG = 'GoogleCloudPlatform'
REPO = 'cloud-foundation-fabric'
API_URL = f'https://api.github.com/repos/{ORG}/{REPO}'
URL = f'https://github.com/{ORG}/{REPO}'
CHANGE_URL = f'[{{name}}]: {URL}/compare/v{{release_from}}...{{release_to}}'

FileRelease = collections.namedtuple('FileRelease',
                                     'name published content link',
                                     defaults=([], None))
PullRequest = collections.namedtuple(
    'PullRequest', 'id base author title merged_at labels upgrade_notes')


class Error(Exception):
  pass


@functools.cache
def _http(token):
  'HTTP requests session with authentication header.'
  session = requests.Session()
  session.headers.update({'Authorization': f'Bearer {token}'})
  return session


def _strip_relname(name):
  if name is None:
    return 'Unreleased'
  if name.startswith('['):
    name = name[1:-1]
  if name.startswith('v'):
    name = name[1:]
  return name


def fetch(token, path, **kw):
  'Fetch request and JSON decode response.'
  try:
    resp = _http(token).get(f'{API_URL}/{path}', **kw)
  except requests.HTTPError as e:
    raise Error(f'HTTP error: {e}')
  if resp.status_code != 200:
    raise Error(f'HTTP status {resp.status_code} for {path}')
  return resp.json()


def format_pull(pull, group=None):
  'Format pull request.'
  url = 'https://github.com'
  pull_url = f'{url}/{ORG}/{REPO}/pull'
  prefix = ''
  if f'breaks:{group}' in pull.labels or 'incompatible change' in pull.labels:
    prefix = '**incompatible change:** '
  return (f'- [[#{pull.id}]({pull_url}/{pull.id})] '
          f'{prefix}'
          f'{pull.title} '
          f'([{pull.author}]({url}/{pull.author})) <!-- {pull.merged_at} -->')


def format_release(pull_groups, upgrade_notes, release_as, release_to,
                   release_from, date_to, date_from):
  'Format release changelog heading and text.'
  pull_url = f'https://github.com/{ORG}/{REPO}/pull'
  if release_as:
    # if we're releasing date to is today
    date_to = datetime.date.today()
  comment = f'<!-- from: {date_from} to: {date_to} since: {release_from} -->'
  if release_to is None and not release_as:
    buffer = [f'## [{release_as or "Unreleased"}] {comment}']
  else:
    buffer = [(f'## [{_strip_relname(release_to or release_as)}] - '
               f'{date_to.strftime("%Y-%m-%d")} {comment}')]
  if upgrade_notes:
    buffer.append('\n### BREAKING CHANGES\n')
    for pr in upgrade_notes:
      for note in pr.upgrade_notes:
        buffer.append(f'- {note} [[#{pr.id}]({pull_url}/{pr.id})]')
    buffer.append('')

  for group in sorted(pull_groups.keys(), key=lambda s: s or ''):
    if group is not None:
      buffer.append(f'### {group.upper()}\n')
    for pull in pull_groups[group]:
      buffer.append(format_pull(pull, group))
    buffer.append('')
  return '\n'.join(buffer)


def get_upgrade_notes(body):
  notes = []
  if body is None:
    return notes
  parser = marko.parser.Parser()
  doc = parser.parse(body)
  for child in doc.children:
    if not isinstance(child, marko.block.FencedCode):
      continue
    if child.lang != "upgrade-note":
      continue
    note = child.children[0].children.strip(" \n\t")
    notes.append(note)
  return notes


def get_pulls(token, date_from, date_to, merged_to, exclude_pulls=None):
  'Get and normalize pull requests from the Github API.'
  exclude_pulls = exclude_pulls
  url = 'pulls?state=closed&sort=updated&direction=desc&per_page=100'
  page = 1
  lookbehinds = 0
  while True:
    pulls = fetch(token, f'{url}&page={page}')
    excluded, unmerged = 0, 0
    for r in pulls:
      pull_id = r['number']
      merged_at = r['merged_at']
      body = r['body']
      upgrade_notes = get_upgrade_notes(r['body'])

      if merged_at is None:
        unmerged += 1
        continue
      pull = PullRequest(pull_id, r['base']['ref'], r['user']['login'],
                         r['title'], iso8601.parse_date(merged_at),
                         [l['name'].lower() for l in r['labels']],
                         upgrade_notes)
      if pull.id in exclude_pulls:
        excluded += 1
        continue
      if pull.base not in merged_to or pull.merged_at <= date_from:
        unmerged += 1
        continue
      if date_to and pull.merged_at >= date_to:
        continue
      yield pull
    if (len(pulls) + excluded) < 100:
      break
    elif unmerged == 100:
      if lookbehinds >= 1:
        break
      lookbehinds += 1
    page += 1


def get_release_date(token, name=None):
  'Get published date for a specific release or the latest release.'
  path = f'releases/tags/{name}' if name else f'releases/latest'
  release = fetch(token, path)
  if not release.get('draft'):
    return iso8601.parse_date(release['published_at'])


def group_pulls(pulls):
  'Group pull requests by on: label.'
  pulls.sort(key=lambda p: p.merged_at, reverse=True)
  groups = {None: []}
  for pull in pulls:
    labels = [l[3:] for l in pull.labels if l.startswith('on:')]
    if not labels:
      groups[None].append(pull)
      continue
    for label in labels:
      group = groups.setdefault(label, [])
      group.append(pull)
  return groups


def load_changelog(filename):
  'Return structured data from changelog file.'
  releases = {}
  links = None
  name = None
  try:
    with open(filename) as f:
      for l in f.readlines():
        l = l.strip()
        if l.startswith(LINK_MARKER):
          links = {}
          continue
        if l.startswith('## '):
          if l[4:].startswith('Unreleased'):
            name, date = 'Unreleased', ''
          else:
            name, _, date = l[3:].partition(' - ')
            name = _strip_relname(name)
          if not date.strip():
            date = datetime.date.today()
          else:
            date = datetime.datetime.strptime(date.split()[0],
                                              '%Y-%m-%d').date()
          releases[name] = FileRelease(name, date, [l])
        elif name and links is None:
          releases[name].content.append(l)
        elif l.startswith('['):
          name, _, _ = l.partition(':')
          links[_strip_relname(name)] = l
  except (IOError, OSError) as e:
    raise Error(f'Cannot open {filename}: {e.args[0]}')
  return releases, links


def write_changelog(releases, links, rel_changes, release_as, release_to,
                    release_from, filename='CHANGELOG.md'):
  'Inject the pull request data and write changelog to file.'
  rel_buffer, link_buffer = [], []
  release_to = _strip_relname(release_to)
  sorted_releases = sorted(releases.values(), reverse=True,
                           key=lambda r: r.published)
  if release_as:
    # inject an empty 'Unreleased' block as the current one will be replaced
    rel_buffer.append('## Unreleased\n')
    rel_link = CHANGE_URL.format(name='Unreleased', release_from=release_as,
                                 release_to='HEAD')
    link_buffer.append(rel_link)
  for rel in sorted_releases:
    rel_link = links.get(rel.name)
    if rel_link is None:
      raise Error(f"no link found for {rel.name}")
    if rel.name == release_to:
      rel_buffer.append(rel_changes)
      if release_as:
        rel_link = CHANGE_URL.format(name=release_as, release_from=release_from,
                                     release_to=release_as)
    else:
      rel_buffer.append('\n'.join(rel.content))
    link_buffer.append(rel_link)
  open(filename, 'w').write(
      '\n'.join([HEADING] + rel_buffer +
                ['<!-- markdown-link-check-disable -->'] + link_buffer))


@click.command
@click.option('--exclude-pull', required=False, multiple=True, type=int,
              help='Exclude specific PR numbers.')
@click.option('--merged-to', required=False, default=('master',), multiple=True,
              help='Only include PRs merged to these branches.')
@click.option('--release-as', required=False, default=None,
              help='Use this name for the Unreleased section as a new release.')
@click.option(
    '--release-from', required=False, default=None,
    help='Lower bound of the comparison, defaults to previous full release.')
@click.option(
    '--release-to', required=False, default=None, help=
    'Release to replace and use as upper bound of the comparison. Leave unspecified for a new release.'
)
@click.option('--token', required=True, envvar='GH_TOKEN',
              help='GitHub API token.')
@click.option('--write', '-w', is_flag=True, required=False, default=False,
              help='Write modified changelog file.')
@click.option('--verbose', '-v', is_flag=True, default=False,
              help='Print information about the running operations')
@click.argument('changelog-file', required=False, default='CHANGELOG.md',
                type=click.Path(exists=True))
def main(token, changelog_file='CHANGELOG.md', exclude_pull=None,
         merged_to=None, release_as=None, release_from=None, release_to=None,
         write=False, verbose=False):
  logging.basicConfig(level=logging.INFO if verbose else logging.WARNING)
  if release_as is not None and release_to is not None:
    raise SystemExit('Only one of `release_as` and `release_to` can be used.')
  try:
    date_from = get_release_date(token, release_from)
    logging.info(f'release date from: {date_from}')
    date_to = None if not release_to else get_release_date(token, release_to)
    logging.info(f'release date to: {date_to}')
    pulls = list(
        get_pulls(token, date_from, date_to, merged_to or ('master',),
                  exclude_pull))
    logging.info(f'number of pulls: {len(pulls)}')
    pull_groups = group_pulls(pulls)
    upgrade_notes = [pr for pr in pulls if pr.upgrade_notes]
    rel_changes = format_release(pull_groups, upgrade_notes, release_as,
                                 release_to, release_from, date_to, date_from)
    if not write:
      print(rel_changes)
      raise SystemExit(0)
    releases, links = load_changelog(changelog_file)
    write_changelog(releases, links, rel_changes, release_as, release_to,
                    release_from, changelog_file)
  except Error as e:
    raise SystemExit(f'Error running command: {e}')


if __name__ == '__main__':
  main()
