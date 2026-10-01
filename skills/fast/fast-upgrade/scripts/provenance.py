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
"""Provenance stamps for the fast-upgrade tools.

Every report printed by `fast_upgrade.py` and `plan_review.py` starts with
a `tools <digest>` stamp: the first 16 hex characters of a SHA256 over the
frozen scripts in this directory (sorted by name, LF-normalized). Reports
also stamp their inputs: `plan` and `apply` record a digest of the base
and target trees, and `plan_review.py` the SHA256 of the plan JSON.
Together they record which build of the tools produced a verdict and what
it was pointed at.

This is tamper-evidence, not tamper-proofing: to check a captured report,
run this module from a pristine checkout of the same commit and compare.

    uv run scripts/provenance.py [--verbose]
"""

import argparse
import hashlib
import os
import posixpath
import sys

# The trust boundary: the agent runs these files and never edits them.
FROZEN_FILES = (
    'factory_data.py',
    'fast_upgrade.py',
    'hcl_lite.py',
    'plan_review.py',
    'provenance.py',
    'release_notes.py',
    'report.py',
)
# What an upstream release contributes to an upgrade (see `fetch`).
RELEASE_ENTRIES = ('fast', 'modules', 'CHANGELOG.md', 'default-versions.tf')

_DIGEST_LEN = 16


def _scripts_dir():
  return os.path.dirname(os.path.abspath(__file__))


def file_digest(path):
  """Returns the SHA256 of a file with CRLF normalized to LF, or None."""
  try:
    with open(path, 'rb') as f:
      data = f.read()
  except OSError:
    return None
  return hashlib.sha256(data.replace(b'\r\n', b'\n')).hexdigest()


def tool_digest(scripts_dir=None):
  """Returns the combined digest of the frozen files."""
  scripts_dir = scripts_dir or _scripts_dir()
  h = hashlib.sha256()
  for name in sorted(FROZEN_FILES):
    digest = file_digest(os.path.join(scripts_dir, name)) or 'missing'
    h.update(f'{name}:{digest}\n'.encode())
  return h.hexdigest()[:_DIGEST_LEN]


def link_target(path):
  """Returns a symlink's target in normal form ('dir/' and 'dir' are equal).

  Tar extraction filters normalize link targets on recent Pythons while git
  checkouts keep them verbatim, so raw targets differ between copies of the
  same release. Compare links with this, never with os.readlink alone.
  """
  return posixpath.normpath(os.readlink(path).replace(os.sep, '/'))


def tree_digest(root, entries=RELEASE_ENTRIES, ignored_dirs=(),
                ignored_file_re=None):
  """Returns a digest of the files under `entries` of a release tree.

  Relative paths and contents are hashed in sorted order, and symlinks by
  their normalized target, so two copies of the same release have the same
  digest wherever they live and however they were fetched.
  """
  h = hashlib.sha256()

  def add(path):
    rel = os.path.relpath(path, root).replace(os.sep, '/')
    if os.path.islink(path):
      value = 'link:' + link_target(path)
    else:
      value = file_digest(path) or 'unreadable'
    h.update(f'{rel}\0{value}\n'.encode())

  def wanted(name):
    return not (ignored_file_re and ignored_file_re.search(name))

  for entry in entries:
    top = os.path.join(root, entry)
    if os.path.islink(top) or not os.path.isdir(top):
      if os.path.lexists(top) and wanted(entry):
        add(top)
      continue
    for dirpath, dirnames, filenames in os.walk(top):
      links = [d for d in dirnames if os.path.islink(os.path.join(dirpath, d))]
      dirnames[:] = sorted(
          d for d in dirnames if d not in ignored_dirs and d not in links)
      for name in sorted(filenames + links):
        if wanted(name):
          add(os.path.join(dirpath, name))
  return h.hexdigest()[:_DIGEST_LEN]


def main(argv=None):
  parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
  parser.add_argument('--verbose', action='store_true',
                      help='Print per-file digests.')
  args = parser.parse_args(argv)
  print(f'frozen tools: {tool_digest()}')
  if args.verbose:
    for name in sorted(FROZEN_FILES):
      digest = file_digest(os.path.join(_scripts_dir(), name)) or 'missing'
      print(f'  {name}: {digest[:_DIGEST_LEN]}')
  return 0


if __name__ == '__main__':
  sys.exit(main())
