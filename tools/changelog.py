#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "click",
#     "iso8601",
#     "marko",
#     "requests",
# ]
# ///
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
- versions can be automatically bumped (major, minor, patch) using the `--bump`
  argument, which computes `release_as` automatically from the latest release

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
- create a new release by automatically bumping the latest version
  ```
  ./tools/changelog.py  --token=$TOKEN --write --bump minor
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
    link = f'https://github.com/{ORG}/{REPO}/compare/{release_from}...HEAD'
    buffer = [f'## [Unreleased]({link}) {comment}']
  else:
    version = _strip_relname(release_to or release_as)
    link = f'https://github.com/{ORG}/{REPO}/releases/tag/v{version}'
    buffer = [(f'## [v{version}]({link}) - '
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
  if name and not name.startswith('v'):
    name = f'v{name}'
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
  name = None
  try:
    with open(filename) as f:
      for l in f.readlines():
        l = l.strip()
        if l.startswith('## '):
          import re
          match = re.match(r'^## \[(.*?)\](?:\((.*?)\))?(?:\s*-\s*(.*))?', l)
          if match:
            name = match.group(1)
            link = match.group(2)
            date_str = match.group(3)

            if name == 'Unreleased':
              date = ''
            else:
              name = _strip_relname(name)
              if not date_str or not date_str.strip():
                date = datetime.date.today()
              else:
                # Strip out trailing comments like ` <!-- from...`
                date_only = date_str.split()[0]
                date = datetime.datetime.strptime(date_only, '%Y-%m-%d').date()
            releases[name] = FileRelease(name, date, [l])
        elif name:
          releases[name].content.append(l)
  except (IOError, OSError) as e:
    raise Error(f'Cannot open {filename}: {e.args[0]}')
  return releases, None


def write_changelog(releases, rel_changes, release_as, release_to, release_from,
                    filename='CHANGELOG.md'):
  'Inject the pull request data and write changelog to file.'
  rel_buffer = []
  release_to = _strip_relname(release_to) if release_to else None
  sorted_releases = sorted(
      releases.values(), reverse=True, key=lambda r: r.published
      if r.published else datetime.date.max)
  if release_as:
    # inject an empty 'Unreleased' block as the current one will be replaced
    rel_link = f'https://github.com/{ORG}/{REPO}/compare/v{_strip_relname(release_as)}...HEAD'
    rel_buffer.append(f'## [Unreleased]({rel_link})\n')
  for rel in sorted_releases:
    if rel.name == release_to or (rel.name == 'Unreleased' and not release_to):
      rel_buffer.append(rel_changes)
    else:
      rel_buffer.append('\n'.join(rel.content))
  open(filename, 'w').write('\n'.join([HEADING] + rel_buffer) + '\n')


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
@click.option(
    '--bump', type=click.Choice(['major', 'minor', 'patch']),
    help='Automatically determine release_as by bumping the latest release.')
@click.argument('changelog-file', required=False, default='CHANGELOG.md',
                type=click.Path(exists=True))
def main(token, changelog_file='CHANGELOG.md', bump=None, exclude_pull=None,
         merged_to=None, release_as=None, release_from=None, release_to=None,
         write=False, verbose=False):
  logging.basicConfig(level=logging.INFO if verbose else logging.WARNING)
  if release_as is not None and release_to is not None:
    raise SystemExit('Only one of `release_as` and `release_to` can be used.')
  try:
    releases, _ = load_changelog(changelog_file)
    latest_release = next((r.name for r in sorted(
        releases.values(), reverse=True, key=lambda x: x.published
        if x.published else datetime.date.min) if r.name != 'Unreleased'), None)

    if bump:
      if release_as:
        raise SystemExit('Cannot use both --bump and --release-as.')
      if release_to:
        raise SystemExit('Cannot use both --bump and --release-to.')

      base_version = release_from or latest_release
      import re
      m = re.match(r'^(v?)(\d+)\.(\d+)\.(\d+)(.*)$', base_version)
      if not m:
        raise SystemExit(f'Cannot bump version {base_version}')
      prefix, major, minor, patch, suffix = m.groups()
      if bump == 'major':
        new_version = f"{int(major)+1}.0.0"
      elif bump == 'minor':
        new_version = f"{major}.{int(minor)+1}.0"
      elif bump == 'patch':
        new_version = f"{major}.{minor}.{int(patch)+1}"

      release_as = f"{prefix}{new_version}{suffix}"
      logging.info(f'Bumping {base_version} to {release_as}')
      if not release_from:
        release_from = latest_release

    date_from = get_release_date(token, release_from)
    logging.info(f'release date from: {date_from}')
    date_to = None if not release_to else get_release_date(token, release_to)
    logging.info(f'release date to: {date_to}')
    pulls = list(
        get_pulls(token, date_from, date_to, merged_to or ('master',),
                  exclude_pull))
    logging.info(f'number of pulls: {len(pulls)}')
    pull_groups = group_pulls(pulls)
    if pull_groups.get(None):
      print("Error: Found uncategorized PRs (missing 'on:' label):")
      for pr in pull_groups[None]:
        url = f"https://github.com/{ORG}/{REPO}/pull/{pr.id}"
        print(f"- #{pr.id}: {pr.title} -> {url}")
      raise SystemExit(
          "Please apply an 'on:' label to these PRs on GitHub and re-run the script."
      )
    upgrade_notes = [pr for pr in pulls if pr.upgrade_notes]
    rel_changes = format_release(pull_groups, upgrade_notes, release_as,
                                 release_to, release_from, date_to, date_from)
    if not write:
      print(rel_changes)
      raise SystemExit(0)
    write_changelog(releases, rel_changes, release_as, release_to, release_from,
                    changelog_file)
  except Error as e:
    raise SystemExit(f'Error running command: {e}')


if __name__ == '__main__':
  main()
