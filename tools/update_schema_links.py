#!/usr/bin/env python3

# Copyright 2025 Google LLC
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

import os
import re
from pathlib import Path

import click

_EXCLUDE_DIRS = ('.git', '.terraform')
_SCHEMA_RE = re.compile(r'^(#\s*yaml-language-server:\s*\$schema=)(.*)$',
                        re.MULTILINE)


def get_yaml_files(folder):
  """Recursively find .yaml and .yml files, excluding specific directories."""
  folder = Path(folder)
  for root, dirs, files in os.walk(folder):
    dirs[:] = [d for d in dirs if d not in _EXCLUDE_DIRS]
    for file in files:
      if file.endswith(('.yaml', '.yml')):
        yield Path(root) / file


@click.command()
@click.argument('folder', type=click.Path(exists=True, file_okay=False))
@click.option(
    '--format', default=
    'https://cdn.jsdelivr.net/gh/GoogleCloudPlatform/cloud-foundation-fabric@fast-dev/fast/stages/{parent}/schemas/',
    help='Format string for the new schema path. Use {parent} placeholder. '
    'Example: https://example.com/{parent}/schemas')
@click.option('--dry-run', is_flag=True, default=False,
              help='Print changes without applying.')
@click.option('--verbose', is_flag=True, default=False,
              help='Print processed files.')
def main(folder, format, dry_run, verbose):
  """Update relative schema paths in YAML files to a formatted URL/path.

  This tool searches for YAML files in the given folder and updates the
  JSON schema declaration (e.g. # yaml-language-server: $schema=...)
  replacing relative local paths with a formatted string.

  The {parent} placeholder in the format string resolves to the name of the
  directory containing the 'schemas' folder for the resolved schema file.
  """

  for file_path in get_yaml_files(folder):
    try:
      content = file_path.read_text(encoding='utf-8')
    except (IOError, OSError, UnicodeDecodeError):
      if verbose:
        print(f"Skipping {file_path}: Cannot read.")
      continue

    changed = False

    def replacer(match):
      nonlocal changed
      prefix = match.group(1)
      old_path = match.group(2).strip()

      # We are only interested in relative paths that exist locally
      try:
        # parsing path relative to the yaml file
        resolved_schema = (file_path.parent / old_path).resolve()
      except Exception:
        return match.group(0)

      if not resolved_schema.exists():
        # If it doesn't exist locally, we assume it's already a URL or invalid,
        # so we skip
        if verbose:
          print(f"Skipping {old_path} in {file_path}: File not found locally.")
        return match.group(0)

      parts = resolved_schema.parts

      try:
        # Find the index of 'schemas'
        # We search from the right to handle nested structures, though unlikely
        # in this repo context
        schemas_indices = [
            i for i, part in enumerate(parts) if part == 'schemas'
        ]

        if not schemas_indices:
          return match.group(0)

        # Use the last occurrence of 'schemas'
        idx = schemas_indices[-1]

        if idx == 0:
          return match.group(0)

        parent_dir = parts[idx - 1]

        # Reconstruct the path suffix (everything after .../schemas/)
        suffix_parts = parts[idx + 1:]
        suffix = "/".join(suffix_parts)

        new_base = format.format(parent=parent_dir)

        # ensure clean join
        if new_base.endswith('/'):
          new_url = f"{new_base}{suffix}"
        else:
          new_url = f"{new_base}/{suffix}"

        if new_url != old_path:
          changed = True
          if dry_run:
            print(f"File: {file_path}")
            print(f"{old_path}")
            print(f"{new_url}")
            print()
          return f"{prefix}{new_url}"
        return match.group(0)

      except Exception:
        return match.group(0)

    new_content = _SCHEMA_RE.sub(replacer, content)

    if changed:
      if not dry_run:
        print(f"Updating {file_path}")
        file_path.write_text(new_content, encoding='utf-8')
    elif verbose:
      print(f"No changes for {file_path}")


if __name__ == '__main__':
  main()
