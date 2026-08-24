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
"""Tamper-evidence for the frozen scripts.

The gates are only meaningful if the actor whose output they judge did not
edit them. That is a rule in the operating contract, and a rule alone was
not enough: a verification round once reached green by adding an entry to
`benign-drift.yaml` rather than by fixing the mapping. Nothing surfaced
it; it was caught later by a reviewer who thought to diff the frozen
files.

This module makes such a change visible without anyone having to think of
looking. `coverage.py` and `verify_plan.py` stamp the digest below into
their output, so every captured gate run records which build of the gates
produced it.

This is tamper-EVIDENCE, not tamper-proofing. An actor editing a gate
could edit this too. What it removes is the silent case: a modified
ruleset now requires deliberate concealment, and any stored gate output
can be checked against a clean checkout.

To verify a recorded run, from a pristine checkout of the same commit:

    python3 scripts/integrity.py

and compare with the `frozen tools:` line in the captured output. A
mismatch means the gates that produced that verdict were not these gates.
Run with `--verbose` for per-file digests, which identifies the file that
differs.

There is deliberately no checked-in expected-digest file. A digest
committed next to the files it covers is edited by the same actor in the
same commit, so it proves nothing that `git diff` does not already prove;
the reference value is the digest computed from a pristine checkout of
the commit under review.

The gates additionally stamp every INPUT they read (resolved path +
SHA256) via `input_stamp`/`data_stamp` below. The frozen-tools digest
authenticates the gates; the input stamps authenticate what the gates
were pointed at. A verdict whose transcript lacks either is not
evidence.
"""

import argparse
import hashlib
import os
import sys

# Everything the trust boundary declares frozen. Order is fixed by sorting
# at hash time, so this list may be extended without invalidating the
# meaning of a digest for an unchanged set.
FROZEN_FILES = (
    'benign-drift.yaml',
    'coverage.py',
    'integrity.py',
    'inventory.py',
    'manifest_from_state.py',
    'manifest_init.py',
    'verify_plan.py',
)

_DIGEST_LEN = 16


def _scripts_dir():
  return os.path.dirname(os.path.abspath(__file__))


def file_digest(name, scripts_dir=None):
  """Returns the full SHA256 of one frozen file (normalized LF), or None if absent."""
  path = os.path.join(scripts_dir or _scripts_dir(), name)
  try:
    with open(path, 'r', encoding='utf-8', errors='surrogateescape') as f:
      content = f.read().replace('\r\n', '\n').encode('utf-8')
      return hashlib.sha256(content).hexdigest()
  except FileNotFoundError:
    return None


def frozen_digest(scripts_dir=None):
  """Returns a short digest covering every frozen file.

  A missing file is hashed distinctly from an empty one, so deleting a
  ruleset changes the digest rather than silently matching.
  """
  h = hashlib.sha256()
  for name in sorted(FROZEN_FILES):
    h.update(name.encode('utf-8'))
    h.update(b'\0')
    d = file_digest(name, scripts_dir)
    h.update(b'<missing>' if d is None else d.encode('ascii'))
    h.update(b'\0')
  return h.hexdigest()[:_DIGEST_LEN]


def stamp(scripts_dir=None):
  """One-line provenance stamp for gate output."""
  return f'frozen tools: {frozen_digest(scripts_dir)}'


def data_stamp(label, data, origin):
  """One-line provenance stamp for an input read as bytes (e.g. stdin).

  A gate verdict is only meaningful for the exact inputs that produced
  it; these lines bind a captured transcript to those inputs so a
  reviewer can re-hash the artifacts and compare.
  """
  digest = hashlib.sha256(data).hexdigest()
  return f'input {label}: {origin} sha256:{digest}'


def display_path(path):
  """Path shape safe to embed in a transcript.

  Relative to cwd if the file is under cwd, basename otherwise.
  """
  full = os.path.realpath(path)
  cwd = os.path.realpath(os.getcwd()) + os.sep
  if full.startswith(cwd):
    try:
      return os.path.relpath(full, os.path.realpath(os.getcwd()))
    except ValueError:
      pass
  return os.path.basename(full)


def input_stamp(label, path):
  """One-line provenance stamp for an input file.

  Prints `display_path(path)` (relative-to-cwd or basename) rather than
  the absolute path.
  """
  full = os.path.abspath(path)
  with open(full, 'rb') as f:
    return data_stamp(label, f.read(), display_path(path))


def tree_stamp(label, paths, origin, root=None):
  """One-line provenance stamp over a set of files (e.g. workspace .tf).

  Hashes sorted (relative name, content) pairs so the digest changes if
  any file is added, removed, renamed or edited. Names are taken
  relative to `root` when given: hashing basenames alone let a file move
  between subdirectories without changing the digest.
  """
  ordered = sorted(paths)
  h = hashlib.sha256()
  for p in ordered:
    if root:
      try:
        name = os.path.relpath(p, root)
      except ValueError:
        name = os.path.basename(p)
    else:
      name = os.path.basename(p)
    h.update(name.encode('utf-8'))
    h.update(b'\0')
    with open(p, 'rb') as f:
      h.update(hashlib.sha256(f.read()).digest())
    h.update(b'\0')
  return (f'input {label}: {origin} files:{len(ordered)} '
          f'sha256:{h.hexdigest()}')


def report(scripts_dir=None):
  lines = [stamp(scripts_dir)]
  for name in sorted(FROZEN_FILES):
    d = file_digest(name, scripts_dir)
    lines.append(f'  {name:24} {d[:_DIGEST_LEN] if d else "MISSING"}')
  return '\n'.join(lines)


def main():
  p = argparse.ArgumentParser(
      description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
  p.add_argument('--verbose', '-v', action='store_true',
                 help='print per-file digests')
  args = p.parse_args()
  print(report() if args.verbose else stamp())
  return 0


if __name__ == '__main__':
  sys.exit(main())
