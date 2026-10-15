#!/usr/bin/env python3
# Copyright 2026 Google LLC
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
#
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Release notes parsing for the fast-upgrade tools.

Reads the Fabric `CHANGELOG.md` (the release format written by
`tools/changelog.py`) and `fast/stages/UPGRADING.md`, selects the releases
between a base (exclusive) and a target (inclusive) version, and tags each
breaking change as relevant or not for the stages and modules a repository
actually uses.
"""

import os
import re

VERSION_RE = re.compile(r'^v?(\d+)\.(\d+)\.(\d+)$')
ANY_VERSION_RE = re.compile(r'\bv(\d+)\.(\d+)\.(\d+)\b')
RELEASE_RE = re.compile(r'^## \[(v\d+\.\d+\.\d+)\](?:\([^)]*\))?'
                        r'(?:\s*-\s*(\d{4}-\d{2}-\d{2}))?')
SECTION_RE = re.compile(r'^### (.+?)\s*$')
SCOPE_RE = re.compile(r'^`([^`]+)`\s*:')
PR_LINK_RE = re.compile(r'\[\[#(\d+)\]\([^)]*\)\]')
AUTHOR_RE = re.compile(r'\s*\(\[[^\]]+\]\([^)]*\)\)\s*$')
COMMENT_RE = re.compile(r'\s*<!--.*?-->')
MOVED_FILE_RE = re.compile(r'^(v\d+\.\d+\.\d+)-(v\d+\.\d+\.\d+)\.tf$')
RENAME_RE = re.compile(r'renamed to\s+`?(?:modules/)?([a-z0-9][a-z0-9-]*)`?')

BREAKING = 'BREAKING CHANGES'
# Scopes that affect every repository regardless of the stages it uses.
GLOBAL_SCOPES = frozenset(
    ('provider', 'providers', 'terraform', 'terraform-google-provider', 'tofu',
     'opentofu', 'fast', 'fast/stages', 'fast/addons', 'modules', 'all'))


def parse_version(value):
  """Returns a (major, minor, patch) tuple, or None."""
  m = VERSION_RE.match(value.strip()) if value else None
  return tuple(int(g) for g in m.groups()) if m else None


def format_version(value):
  return 'v%d.%d.%d' % value


def parse_changelog(text):
  """Returns [{'version', 'date', 'sections': {NAME: [entry, ...]}}]."""
  releases = []
  current = None
  section = None
  entry = None
  for line in text.splitlines():
    m = RELEASE_RE.match(line)
    if m:
      current = {'version': m.group(1), 'date': m.group(2), 'sections': {}}
      releases.append(current)
      section = entry = None
      continue
    if line.startswith('## '):
      current = section = entry = None
      continue
    if current is None:
      continue
    m = SECTION_RE.match(line)
    if m:
      section = m.group(1).strip().upper()
      current['sections'].setdefault(section, [])
      entry = None
      continue
    stripped = line.strip()
    if section is None or not stripped:
      continue
    entries = current['sections'][section]
    if line.startswith('- ') or line.startswith('* '):
      entry = [stripped[2:].strip()]
      entries.append(entry)
    elif section == BREAKING and SCOPE_RE.match(stripped):
      # Unbulleted scoped lines are separate changes in generated notes.
      entry = [stripped]
      entries.append(entry)
    elif entry is not None:
      entry.append(stripped)
  for release in releases:
    for name, entries in release['sections'].items():
      release['sections'][name] = [
          COMMENT_RE.sub('', ' '.join(e)).strip() for e in entries
      ]
  return releases


def select_releases(releases, base, target):
  """Returns releases with base < version <= target, oldest first."""
  selected = [
      r for r in releases if base < parse_version(r['version']) <= target
  ]
  return sorted(selected, key=lambda r: parse_version(r['version']))


def entry_scopes(entry):
  m = SCOPE_RE.match(entry)
  if not m:
    return []
  return [s for s in re.split(r'[,\s]+', m.group(1)) if s]


def relevance(entry, stages=None, modules=None):
  """Returns (relevant, reason) for a breaking change entry.

  `stages` and `modules` are the names in use; None means unknown, in which
  case every entry is relevant.
  """
  if stages is None and modules is None:
    return True, 'unfiltered'
  stages = stages or set()
  modules = modules or set()
  scopes = entry_scopes(entry)
  if not scopes:
    return True, 'global'
  for scope in scopes:
    value = scope.strip('/').lower()
    if value in GLOBAL_SCOPES:
      return True, 'global'
    parts = value.split('/')
    if parts[0] == 'modules' and len(parts) > 1:
      if parts[1] in modules:
        return True, f'module {parts[1]}'
    elif parts[0] == 'fast':
      if parts[-1] in stages:
        return True, f'stage {parts[-1]}'
    elif value in stages:
      return True, f'stage {value}'
    elif value in modules:
      return True, f'module {value}'
  return False, 'not used'


def condense(entry):
  """Shortens a changelog line to '#PR title'."""
  m = PR_LINK_RE.search(entry)
  text = PR_LINK_RE.sub('', entry)
  text = AUTHOR_RE.sub('', text).strip()
  return f'#{m.group(1)} {text}' if m else text


def breaking_changes(releases, stages=None, modules=None):
  result = []
  for release in releases:
    for entry in release['sections'].get(BREAKING, []):
      relevant, reason = relevance(entry, stages, modules)
      result.append({
          'version': release['version'],
          'text': entry,
          'relevant': relevant,
          'reason': reason,
      })
  return result


def fast_changes(releases):
  return [{
      'version': r['version'],
      'text': condense(e)
  } for r in releases for e in r['sections'].get('FAST', [])]


def declared_module_renames(releases):
  """Returns {old: new} module renames stated in breaking changes."""
  renames = {}
  for release in releases:
    for entry in release['sections'].get(BREAKING, []):
      for scope in entry_scopes(entry):
        parts = scope.strip('/').split('/')
        if len(parts) == 2 and parts[0] == 'modules':
          m = RENAME_RE.search(entry)
          if m and m.group(1) != parts[1]:
            renames[parts[1]] = m.group(1)
  return renames


def upgrading_notes(text, base, target):
  """Returns UPGRADING.md blocks that mention a version in (base, target]."""
  blocks = []
  current = None
  for line in text.splitlines():
    if line.startswith('>'):
      if current is None or current['kind'] != 'quote':
        current = {'kind': 'quote', 'lines': []}
        blocks.append(current)
      current['lines'].append(line[1:].strip())
    elif line.startswith('#'):
      current = {'kind': 'section', 'lines': [line]}
      blocks.append(current)
    elif current is not None and current['kind'] == 'section':
      current['lines'].append(line)
    else:
      current = None
  notes = []
  for block in blocks:
    body = '\n'.join(block['lines']).strip()
    found = {tuple(int(g) for g in v) for v in ANY_VERSION_RE.findall(body)}
    hits = sorted(v for v in found if base < v <= target)
    if hits:
      notes.append({
          'versions': [format_version(v) for v in hits],
          'text': body,
      })
  return notes


def moved_files(root, stage_dirs, base, target):
  """Returns [{'stage', 'file', 'path'}] moved-block files for the range."""
  result = []
  for stage_dir in sorted(stage_dirs):
    moved = os.path.join(root, stage_dir, 'moved')
    if not os.path.isdir(moved):
      continue
    for name in sorted(os.listdir(moved)):
      m = MOVED_FILE_RE.match(name)
      if m and base < parse_version(m.group(2)) <= target:
        result.append({
            'stage': stage_dir,
            'file': name,
            'path': f'{stage_dir}/moved/{name}',
        })
  return result
